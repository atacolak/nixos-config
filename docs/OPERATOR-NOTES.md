# observeOS — how I want my computer to feel

*Operator notes from 30 October 2026. This is the operator's first-person language, selected from the conversation with only small punctuation fixes. It is not marketing copy. Keep the underlying passages available when implementing or explaining the system.*

> "literally, your agent plugs into your system. and it doesnt even have to be hard, it can just be a mcp, even. its just the computer running it has to run an app. then the agent can just talk to the app."

> "the fact that our system is literally declarative does help on this, of course. we can know so much more as opposed to a more closed system would."

> "it is as if the agent is here."

> "i want very good tiling and for it to actually work. make them do whatever they can to make sure their testing is as close to how a human would. even if it takes actually sending those key presses."

> "i am still on sway. i am kinda scared to go bc it has to work very very good and almost flawlessly!!"

> "how i use caps lock as my prefix key, how i can rapid-press caps twice like double click and that toggles caps for me, how i use caps+w to collapse selected windows into one that i can alt-tab or alt-shift-tab to switch like a deck of cards"

> "it is how i USE and EXPECT from my system."

> "i really liked nixOS's declarative surface because i can literally make it extremely hard for agents to not know what is up with the system they are running or to lie (lol)? they write the system anyway, i tell that what i want and they do the system work."

> "you take ownership of my nixos configs too, making sure they are a form of ART, making sure it has personal writing-blogposting-ish stuff which would make it actually amusing to read, too."

> "you press once, annotate as much as you want, switch panes if you want and point to other stuff, talk about the things you pointed, and press again, then boom. a packet is sent to your agent, and they can respond."

> "a small sort of 'wave' forming from the kwin pane that was pressed that navigates like a minimal wave motion to the edges of that pane to indicate the computer knows which pane the person interacted with (but very minimal)"

> "we know what each pane that the user is mentioning literally is. and we can interact with them."

> "one thing our app allows that we can use as an interaction layer is literally, user press-hold-ing a button to make their cursor able to 'draw' like a magic sparkle or something"

> "instead of click and hold, the key, press is also good."

> "don't overfit to current low-throughput llms running as agents. to see the magic of such a system, you'd want at least 200-300 tok-s stable, and 1000-1500 tok/s would feel like absolute magic."

> "rewindOS feels like a blessing before i even experienced it."

## Don't lose the specific interactions

- **Keyboard is a personal language.** The actual double Caps behavior is from KMonad; the operator remembers finding the idea on Reddit *or* Stack Overflow, but the origin is unverified. Preserve that uncertainty instead of making up a tidy story. The distinct `Caps+W` tabbed deck, scoped to selected subtree with `Alt+Tab` and `Alt+Shift+Tab` sibling cycling, must work, not be approximated by global window switching. `Caps+Y` tree mode and `Caps+R` resize mode are real multi-keystroke interactions.
- **Human-grade proof.** In private disposable KWin sessions, inject the *actual shortcut sequences* through a real key event path (not just invoke tiling methods), assert KWin's real window IDs/focus/geometry and capture before/after pixels. Test rapid Caps double-tap separately on the target's actual KMonad device with operator supervision; don't touch the live Sway seat otherwise. A failure must stay red. Include repeated/nested operations and recoverability.
- **No cutover while operator is busy.** Keep `obs-36o.2.5` deferred; system may build/test and document reversible activation, but never switch/login/restart GDM or mutate running Sway/KMonad without explicit live operator involvement.
- **Observe on Sway first if possible.** The observation app should not have to wait for Plasma. Probe RewindOS's actual Sway/PipeWire/portal path in a controlled, opt-in test. Build capture, pause, OCR, temporal indexing and search on Sway before physical Plasma migration where possible. Never silently record private apps or secret prompts; test exclusion against *background visible content*, not only active-window labels.
- **Current and recent are two queries over one evidence stream.** The agent receives active app/window ID, screenshot/selected region, pointer marks, accessible text when available, event timing, confidence and evidence refs. App/window identities persist over their lifetime. Never infer a precise click/selection or tab from sparse OCR alone.
- **Voice/annotation together.** One press arms a visible compact dark/pink listener (see the two Handy overlay image references in the 2026-10-30 chat). Cursor becomes temporary sparkling ink; marks are attached to window IDs and timestamps even across pane focus changes. Second press sends voice + strokes + relevant frame refs to the selected agent. Agents may answer through SpeechCore, draw their own short-lived attention rings/waves and show dismissible panes. Theme colors belong to user preferences, not hardcoded pink.
- **Window-attention wave.** The requested light ripple travels from the touched point to the border of the exact pane; very small and brief. Can draw attention to an agent-mentioned pane, and later optionally bring it forward with an explicitly authorized action.
- **An agent's parallel space.** Cache references to tabs/pages/notes/code/workspaces and permit read-only or copy-on-write exploration with tools/terminal. Sharing context is not sharing live browser credentials or uncommitted buffers by default. Identify staleness.
- **Retrieval.** Screen/OCR data and window timelines remain original evidence. Text/vision/audio/video embeddings (evaluate EmbeddingGemma 2 on the laptop) are derived searchable indexes with references, not truth or copied into Hindsight as raw truth. Marlin-2B may help find scene intervals from sampled video, but evaluate it on desktop-specific recordings before assuming fine UI reading.
- **Documentation is part of the machine.** Annotate real NixOS decisions as an amusing, honest first-person engineering story alongside the declarative config: reason, observed system, exact behavior, failed experiments, verification command and how to rollback. Do not invent the origin of shortcuts or replace operator phrasing with AI-brand prose. Keep executable Nix syntax pristine.
- **Latency target, not an already achieved performance claim.** Architect callbacks and context retrieval for fast agents (200–300 output tok/s as desirable and 1000–1500 aspirational), without speculative always-on per-frame LLM loops or forcing slow agents to process entire screen history.

## Near-term acceptance scene

Operator remains on Sway. One shortcut toggles annotation/listening. Operator opens one pane, points at a phrase, switches to another pane, marks a second area, speaks, presses shortcut again. The chosen actor receives the *actual two panes*, each mark with timing and window identity, and an audio/text link; answers aloud; can place a small attention wave and borderless dismissible reply near the correct pane. All of this is visible and opt-in. If a structured selection or tab identity is unavailable, it says unknown and supplies the supporting frame.

Implement this by adding the minimum compositor/input adapters to **existing observeOS and SpeechCore**, not by creating a new agent identity/memory/orchestrator.
