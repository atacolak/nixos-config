// The toolbar icon *is* the exit country's flag. When the tunnel is down
// there is no flag to show, so it falls back to a desaturated Mullvad mark —
// unmistakably "not tunnelled" at 16 px, no badge or slash needed.
//
// A manifest icon is static, so every state has to be drawn and pushed with
// chrome.action.setIcon. Service workers are killed when idle, so anything
// that might mean the user is looking (startup, alarm, popup message) re-syncs.

const HOST = "net.colak.bmullvad";
const SIZES = [16, 32, 48, 128];
const ALARM = "bmullvad-icon-refresh";

// Flags ship pre-rasterised at these widths by the nix derivation.
// Chromium refuses SVG in createImageBitmap, so they cannot be vector here.
const FLAG_DIR = "flags";

/* ---------- host ---------- */

function call(op) {
  return new Promise((resolve, reject) => {
    let port;
    try {
      port = chrome.runtime.connectNative(HOST);
    } catch (e) {
      reject(new Error(String(e && e.message)));
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
      reject(new Error(err ? err.message : "host closed"));
    });
    port.postMessage({ op });
  });
}

/* ---------- drawing ---------- */

const flagCache = new Map();
const markCache = new Map();

// Round the corners so a flag reads as a tile rather than a smear of colour
// bleeding into the toolbar.
function roundedClip(ctx, size, ratio) {
  const r = Math.max(2, Math.round(size * ratio));
  ctx.beginPath();
  ctx.moveTo(r, 0);
  ctx.arcTo(size, 0, size, size, r);
  ctx.arcTo(size, size, 0, size, r);
  ctx.arcTo(0, size, 0, 0, r);
  ctx.arcTo(0, 0, size, 0, r);
  ctx.closePath();
  ctx.clip();
}

async function bitmap(key, url) {
  const cache = key === "mark" ? markCache : flagCache;
  if (!cache.has(key)) {
    cache.set(key, (async () => {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`${url}: ${res.status}`);
      return createImageBitmap(await res.blob());
    })());
  }
  try {
    return await cache.get(key);
  } catch (e) {
    cache.delete(key);
    throw e;
  }
}

// Flags are 4:3 and the icon is 1:1, so crop the long axis. Scaling a flag
// to a square would simply draw the wrong flag.
async function flagIcon(cc, size) {
  const code = String(cc).toLowerCase();
  const bmp = await bitmap(`flag:${code}:${size}`, chrome.runtime.getURL(`${FLAG_DIR}/${code}-${size}.png`));
  const canvas = new OffscreenCanvas(size, size);
  const ctx = canvas.getContext("2d");
  ctx.save();
  roundedClip(ctx, size, 0.16);
  const side = Math.min(bmp.width, bmp.height);
  const sx = (bmp.width - side) / 2;
  const sy = (bmp.height - side) / 2;
  ctx.drawImage(bmp, sx, sy, side, side, 0, 0, size, size);
  ctx.restore();
  return canvas;
}

// Desaturated mark for "no tunnel". Grayscale is the clearest possible
// "inactive" signal in a 16 px square, and keeps the mark recognisable.
async function markIcon(size) {
  const bmp = await bitmap("mark", chrome.runtime.getURL(`icons/${size}.png`));
  const canvas = new OffscreenCanvas(size, size);
  const ctx = canvas.getContext("2d");
  ctx.filter = "grayscale(1) opacity(0.65)";
  ctx.drawImage(bmp, 0, 0, size, size);
  return canvas;
}

/* ---------- state ---------- */

async function paint(state, cc) {
  const showFlag = state === "connected" && cc && cc.length === 2;
  const imageData = {};
  let drewFlag = false;

  for (const size of SIZES) {
    let canvas = null;
    if (showFlag) {
      try {
        canvas = await flagIcon(cc, size);
        drewFlag = true;
      } catch (_) {
        canvas = null; // flag missing from the build: fall through to the mark
      }
    }
    if (!canvas) canvas = await markIcon(size);
    imageData[size] = canvas.getContext("2d").getImageData(0, 0, size, size);
  }

  // Only claim a country when its flag is actually on the icon. A build with
  // no asset for a country falls back to the mark, and the title must not
  // then name a country the user cannot see.
  const country = drewFlag && cc ? cc.toUpperCase() : "";
  const title =
    state === "connected"
      ? `Mullvad: connected${country ? " (" + country + ")" : ""}`
      : state === "stale"
        ? "Mullvad: connected, not passing traffic"
        : "Mullvad: disconnected";

  await chrome.action.setIcon({ imageData });
  await chrome.action.setTitle({ title });
  // the flag itself communicates state; no text badge needed
  await chrome.action.setBadgeText({ text: "" });

  return drewFlag;
}

async function sync() {
  try {
    const s = await call("status");
    await paint(s.state, s.cc);
    chrome.storage.local.set({ "bmullvad.status": s });
    return s;
  } catch (_) {
    // host missing (older generation, or bmullvad off PATH): show the honest
    // state rather than leaving a stale flag on the toolbar.
    await paint("disconnected", null);
    return null;
  }
}

chrome.runtime.onInstalled.addListener(() => {
  chrome.alarms.create(ALARM, { periodInMinutes: 1 });
  sync();
});
chrome.runtime.onStartup.addListener(sync);
chrome.alarms.onAlarm.addListener((a) => {
  if (a.name === ALARM) sync();
});
// the popup tells us when it changed something so the icon flips immediately
// instead of on the next alarm tick
chrome.runtime.onMessage.addListener((msg, _sender, reply) => {
  if (msg && msg.type === "sync") {
    sync().then((s) => reply({ ok: true, status: s }));
    return true;
  }
  return false;
});

sync();
