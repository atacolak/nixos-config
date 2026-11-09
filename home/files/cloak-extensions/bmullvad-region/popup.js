// Talk to the bmullvad native host, list exits, switch region, disconnect.
// No network access: everything goes through the local helper.

const HOST = "net.colak.bmullvad";
const CACHE_KEY = "bmullvad.relays";
const CACHE_TTL = 6 * 60 * 60 * 1000; // relays change slowly; a day-old list is fine

const $state = document.getElementById("state");
const $detail = document.getElementById("detail");
const $search = document.getElementById("search");
const $list = document.getElementById("list");
const $err = document.getElementById("err");
const $footer = document.getElementById("footer");
const $disconnect = document.getElementById("disconnect");

// [{cc, cn, cityCode, city}]
let relays = [];
let view = "countries";
let currentCountry = null;
let status = null;
let busy = false;

function flag(cc) {
  if (!cc || cc.length !== 2) return "🏳️";
  const base = 0x1f1e6;
  return String.fromCodePoint(
    base + cc.toUpperCase().charCodeAt(0) - 65,
    base + cc.toUpperCase().charCodeAt(1) - 65
  );
}

// One request/response round trip with the native host.
function call(op, args = {}) {
  return new Promise((resolve, reject) => {
    let port;
    try {
      port = chrome.runtime.connectNative(HOST);
    } catch (e) {
      reject(new Error("cannot reach bmullvad host: " + e.message));
      return;
    }
    let settled = false;
    port.onMessage.addListener((msg) => {
      settled = true;
      try { port.disconnect(); } catch (_) {}
      if (msg && msg.error) reject(new Error(msg.error));
      else resolve(msg);
    });
    port.onDisconnect.addListener(() => {
      if (settled) return;
      const err = chrome.runtime.lastError;
      reject(new Error(err ? err.message : "bmullvad host closed the connection"));
    });
    port.postMessage({ op, ...args });
  });
}

function renderStatus() {
  if (!status) return;
  const st = status.state || "disconnected";
  $state.textContent = st;
  $state.className = st;
  // nothing to disconnect when there is no tunnel
  $disconnect.disabled = st === "disconnected" || busy;
  $disconnect.title =
    st === "disconnected" ? "nothing to disconnect" : "disconnect the browser tunnel";

  const bits = [];
  if (status.relay) bits.push(status.relay);
  if (status.city && status.country) bits.push(status.city + ", " + status.country);
  $detail.textContent = bits.join(" · ");
}

/* ---------- relays ---------- */

async function loadRelays() {
  let cached = null;
  try {
    cached = await chrome.storage.local.get(CACHE_KEY);
  } catch (_) {}
  const hit = cached && cached[CACHE_KEY];
  if (hit && Array.isArray(hit.relays) && Date.now() - hit.at < CACHE_TTL) {
    relays = hit.relays;
    return;
  }
  // stale cache still beats an empty list while the fetch runs
  if (hit && Array.isArray(hit.relays) && hit.relays.length) relays = hit.relays;

  try {
    const data = await call("list");
    const fresh = Array.isArray(data) ? data : data.relays || [];
    if (fresh.length) {
      relays = fresh;
      chrome.storage.local.set({ [CACHE_KEY]: { at: Date.now(), relays: fresh } });
    }
  } catch (e) {
    if (!relays.length) throw e;
  }
}

/* ---------- rendering ---------- */

function countryRows() {
  const byCc = new Map();
  for (const r of relays) {
    const hit = byCc.get(r.cc);
    if (hit) hit.n += 1;
    else byCc.set(r.cc, { cc: r.cc, cn: r.cn, n: 1 });
  }
  return [...byCc.values()].sort((a, b) => a.cn.localeCompare(b.cn));
}

function cityRows(cc) {
  const byCity = new Map();
  for (const r of relays) {
    if (r.cc !== cc) continue;
    const hit = byCity.get(r.cityCode);
    if (hit) hit.n += 1;
    else byCity.set(r.cityCode, { cityCode: r.cityCode, city: r.city, n: 1 });
  }
  return [...byCity.values()].sort((a, b) => a.city.localeCompare(b.city));
}

function matches(text, q) {
  return text.toLowerCase().includes(q);
}

function rowButton({ flagText, name, code, count, isCurrent, onClick }) {
  const li = document.createElement("li");
  if (isCurrent) li.dataset.current = "1";
  const btn = document.createElement("button");
  btn.type = "button";

  const f = document.createElement("span");
  f.className = "flag";
  f.textContent = flagText;

  const nm = document.createElement("span");
  nm.className = "name";
  nm.textContent = name;

  const cc = document.createElement("span");
  cc.className = "cc";
  cc.textContent = code;

  const ct = document.createElement("span");
  ct.className = "mark";
  ct.textContent = isCurrent ? "✓" : count != null ? String(count) : "";

  btn.append(f, nm, cc, ct);
  btn.addEventListener("click", onClick);
  li.append(btn);
  return li;
}

function render() {
  const q = $search.value.trim().toLowerCase();
  $list.replaceChildren();

  if (view === "cities") {
    const back = document.createElement("li");
    const b = document.createElement("button");
    b.type = "button";
    const bf = document.createElement("span");
    bf.className = "flag";
    bf.textContent = "←";
    const bn = document.createElement("span");
    bn.className = "name";
    bn.textContent = currentCountry.cn;
    const bm = document.createElement("span");
    bm.className = "mark";
    bm.textContent = "all countries";
    b.append(bf, bn, bm);
    b.addEventListener("click", () => {
      view = "countries";
      currentCountry = null;
      $search.value = "";
      render();
      $search.focus();
    });
    back.append(b);
    $list.append(back);

    if (!q || matches("any city", q)) {
      $list.append(
        rowButton({
          flagText: "🌐",
          name: "Any city",
          code: currentCountry.cc,
          count: null,
          isCurrent: false,
          onClick: () => switchTo(currentCountry.cc, null),
        })
      );
    }

    for (const c of cityRows(currentCountry.cc)) {
      if (q && !matches(c.city, q) && !matches(currentCountry.cc, q)) continue;
      $list.append(
        rowButton({
          flagText: flag(currentCountry.cc),
          name: c.city,
          code: c.cityCode,
          count: c.n,
          isCurrent:
            status &&
            status.relay &&
            status.relay.startsWith(currentCountry.cc + "-") &&
            status.city &&
            status.city.toLowerCase() === c.city.toLowerCase(),
          onClick: () => switchTo(currentCountry.cc, c.cityCode),
        })
      );
    }
    $footer.textContent = `${cityRows(currentCountry.cc).length} cities · ${currentCountry.cc}`;
    return;
  }

  let shown = 0;
  const q2 = q.replace(/^\+/, "");
  const rows = [];
  for (const c of countryRows()) {
    // Rank so an exact country-code hit beats a name substring: "nl" must put
    // Netherlands first, not Finland (Fi-nl-and).
    let rank;
    if (!q) rank = 0;
    else if (c.cc === q2) rank = 1;
    else if (c.cc.startsWith(q2)) rank = 2;
    else if (matches(c.cn, q)) rank = 3;
    else continue;
    rows.push({ c, rank });
  }
  rows.sort((a, b) => a.rank - b.rank || a.c.cn.localeCompare(b.cn));
  for (const { c } of rows) {
    shown += 1;
    $list.append(
      rowButton({
        flagText: flag(c.cc),
        name: c.cn,
        code: c.cc,
        count: c.n,
        isCurrent:
          status && status.relay && status.relay.startsWith(c.cc + "-"),
        onClick: () => {
          currentCountry = c;
          view = "cities";
          $search.value = "";
          render();
          $search.focus();
        },
      })
    );
  }
  const total = countryRows().length;
  $footer.textContent = q
    ? `${shown} of ${total} countries`
    : `${total} countries · search name or code (nl, +se)`;
}

/* ---------- actions ---------- */

function pokeWorker() {
  try {
    chrome.runtime.sendMessage({ type: "sync" }, () => {
      // nothing to do with the answer; errors just mean no worker listening
      void chrome.runtime.lastError;
    });
  } catch (_) {}
}

async function settle() {
  // a fresh peer needs a handshake before it reports connected, so poll
  // briefly instead of painting one mid-switch sample and stopping.
  for (let i = 0; i < 12; i++) {
    await refresh();
    if (status && status.state === "connected") return;
    await new Promise((r) => setTimeout(r, 1000));
  }
}

async function switchTo(cc, cityCode) {
  if (busy) return;
  busy = true;
  renderStatus();
  $err.textContent = "";
  $state.textContent = "switching…";
  $state.className = "";
  try {
    const res = await call("set", cityCode ? { cc, city: cityCode } : { cc });
    if (res.relay) $footer.textContent = "now on " + res.relay;
    await settle();
    pokeWorker();
    render();
  } catch (e) {
    $err.textContent = e.message;
  } finally {
    busy = false;
    renderStatus();
  }
}

async function disconnect() {
  if (busy) return;
  busy = true;
  renderStatus();
  $err.textContent = "";
  $state.textContent = "disconnecting…";
  $state.className = "";
  try {
    await call("down");
    for (let i = 0; i < 8; i++) {
      await refresh();
      if (status && status.state === "disconnected") break;
      await new Promise((r) => setTimeout(r, 500));
    }
    pokeWorker();
    render();
  } catch (e) {
    $err.textContent = e.message;
  } finally {
    busy = false;
    renderStatus();
  }
}

async function refresh() {
  try {
    const s = await call("status");
    status = s.status || s;
    renderStatus();
    // remember it so the next open paints instantly instead of waiting
    try { chrome.storage.local.set({ "bmullvad.status": status }); } catch (_) {}
  } catch (e) {
    $err.textContent = e.message;
  }
}

/* ---------- boot ---------- */

async function boot() {
  $search.addEventListener("input", render);
  $disconnect.addEventListener("click", disconnect);
  $search.focus();

  // Paint from cache and stop. Nothing below this line may block the first
  // frame: opening the popup must not wait on the native host at all.
  let staged = false;
  try {
    const cache = await chrome.storage.local.get(["bmullvad.status", CACHE_KEY]);
    if (cache["bmullvad.status"]) status = cache["bmullvad.status"];
    const hit = cache[CACHE_KEY];
    if (hit && Array.isArray(hit.relays) && hit.relays.length) {
      relays = hit.relays;
      staged = true;
    }
  } catch (_) {}
  renderStatus();
  if (relays.length) render();
  if (!relays.length) $footer.textContent = "loading exits…";

  // Whatever is still missing gets filled in behind the painted frame.
  refresh().then(() => {
    if (!relays.length) render();
  });
  if (!staged) {
    loadRelays()
      .then(() => render())
      .catch((e) => {
        $err.textContent = e.message;
        $footer.textContent = "relay list unavailable";
      });
  }
}

boot();
