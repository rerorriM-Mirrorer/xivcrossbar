# FFXI golden cursor

Six transparent PNG frames extracted from the supplied 51.DAT texture anc/anc. Each canvas is 32×20; consistent bounds preserve the animated glint and position. `provenance.json` records the extraction reference. Original FFXI assets remain their respective owner's work.

Row-major playback order and 12 fps are preview choices, not verified native game timing. The PNGs retain the original alpha.

XIVCrossbar's `ui/animated_cursor.lua` preloads these frames and displays the current frame beside the selected menu option. This changes the addon menu cursor, not the operating-system mouse pointer.
