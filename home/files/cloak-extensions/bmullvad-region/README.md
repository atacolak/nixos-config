# flags/

one SVG per Mullvad exit country, 4:3, from
[flag-icons](https://github.com/lipis/flag-icons) (MIT).

`home/sf.nix` rasterises these into `flags/<cc>-<size>.png` at 16/32/48/128
during the build. Chromium's `createImageBitmap` refuses SVG, so the extension
cannot rasterise them itself — and committing 200 PNGs to git for a 50-entry
lookup table is worse than committing 50 small SVGs and letting the build do
it.

`background.js` crops each 4:3 flag to the centre square when drawing the
1:1 toolbar icon. Do not "fix" that by scaling to a square: a squashed flag is
a wrong flag.

a flag missing here is not fatal. `flagIcon()` throws, `paint()` catches it,
and the icon falls back to the desaturated mark.
