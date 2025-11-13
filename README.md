### Garry's Mod Font Health Manager

A lightweight utility that helps keep your dynamically created fonts under control in Garry's Mod.

This addon was originally created after noticing that some servers - especially those with many addons - repeatedly recreate the same fonts for no reason, bloating the engine's font list. By preventing duplicate font creation, this tool reduced the total number of active fonts on my setup from around **800** down to **~550**.

Fewer duplicate fonts means:

* **Faster load times** (skips unnecessary font creation)
* **Better memory management** (avoids excessive font data in the engine)
* **Improved stability** overall

---

### Installation

Make sure to drop the folder in addons/GFonts/lua/autorun/!0_gfonts.lua

**Important**: If you change the file name it might break as it must be loaded first before everything else!
