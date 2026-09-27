User-supplied portraits from Portraits.zip.

map.json maps the original filenames to Darktide breed names. Variants without
a separate image share their base breed's portrait. Both Twin portraits were
checked against their weapons: Twin Captain is the gunner, Second Twin is melee.

Run tools/build-portraits.ps1 from PowerShell on Windows to rebuild the Lua data.
The current renderer has no external JPG texture loader. It uses 96-pixel-wide
previews with preserved aspect ratio and 5-bit RGB quantization, merging equal
horizontal/vertical runs. The original JPGs remain unmodified here.

Imported portraits are used in the selection cards and the bottom-left controlled
enemy panel. The team HUD retains lightweight portraits. Missing data uses the old fallback.
No external file paths or additional mods are required at runtime.

In-game frame-time impact has not been measured. Each preview uses up to 9342
rectangles; invisible cards are not drawn. A compiled texture atlas would be
preferable if a compatible custom resource loading pipeline becomes available.
