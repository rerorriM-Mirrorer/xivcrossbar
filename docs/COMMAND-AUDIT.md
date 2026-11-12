# Command inventory, November 12, 2026

Audited addon callback branch names and friendly aliases. Nested native subcommands
are identified separately; existing command paths are retained. This is an exposure
classification, not permission to delete compatibility or diagnostic commands.

| Command | Audience / status |
| --- | --- |
| `//xb ?` | Compatibility alias / old spelling |
| `//xb al` | Compatibility alias / old spelling |
| `//xb alias` | Public |
| `//xb auto` | Public |
| `//xb autoattack` | Advanced / diagnostic |
| `//xb autohide` | Public |
| `//xb autohold` | Public |
| `//xb bank` | Advanced / diagnostic |
| `//xb banklabeloffset` | Compatibility alias / old spelling |
| `//xb banklabelopacity` | Compatibility alias / old spelling |
| `//xb banklabels` | Compatibility alias / old spelling |
| `//xb bar` | Public |
| `//xb bridge` | Advanced / diagnostic |
| `//xb ca` | Public |
| `//xb caption` | Compatibility alias / old spelling |
| `//xb clear` | Public |
| `//xb compact` | Compatibility alias / old spelling |
| `//xb controller` | Public |
| `//xb copy` | Public |
| `//xb costalign` | Advanced / diagnostic |
| `//xb costoffset` | Advanced / diagnostic |
| `//xb cp` | Compatibility alias / old spelling |
| `//xb crossbar` | Public |
| `//xb crossbarlabeloffset` | Public |
| `//xb crossbarlabels` | Public |
| `//xb crossbars` | Public |
| `//xb custom` | Compatibility alias / old spelling |
| `//xb cutscene` | Public |
| `//xb default` | Public |
| `//xb deleteset` | Public |
| `//xb diagnose` | Advanced / diagnostic |
| `//xb diagnostics` | Advanced / diagnostic |
| `//xb display` | Compatibility alias / old spelling |
| `//xb eventbars` | Compatibility alias / old spelling |
| `//xb fade` | Compatibility alias / old spelling |
| `//xb fading` | Public |
| `//xb help` | Public |
| `//xb hide` | Public |
| `//xb hotbar` | Compatibility alias / old spelling |
| `//xb ic` | Compatibility alias / old spelling |
| `//xb icon` | Public |
| `//xb inputstatus` | Advanced / diagnostic |
| `//xb inputtest` | Advanced / diagnostic |
| `//xb inputtrace` | Advanced / diagnostic |
| `//xb jobsets` | Public |
| `//xb labelopacity` | Public |
| `//xb layout` | Public |
| `//xb legacy` | Public |
| `//xb lockout` | Advanced / diagnostic |
| `//xb logic` | Nested native subcommand, not a standalone public form |
| `//xb me` | Private personal controls/preset |
| `//xb move` | Public |
| `//xb mv` | Compatibility alias / old spelling |
| `//xb n` | Compatibility alias / old spelling |
| `//xb nativepad` | Advanced / diagnostic |
| `//xb new` | Public |
| `//xb off` | Nested native subcommand, not a standalone public form |
| `//xb preset` | Public |
| `//xb probe` | Nested native subcommand, not a standalone public form |
| `//xb recastflash` | Public |
| `//xb regenerate` | Advanced / diagnostic |
| `//xb reload` | Public |
| `//xb remap` | Public |
| `//xb rename` | Public |
| `//xb rendertrace` | Advanced / diagnostic |
| `//xb resources` | Advanced / diagnostic |
| `//xb restart` | Public |
| `//xb rn` | Compatibility alias / old spelling |
| `//xb scale` | Public |
| `//xb set` | Public |
| `//xb setname` | Public |
| `//xb setnameoffset` | Public |
| `//xb show` | Public |
| `//xb skillchain` | Advanced / diagnostic |
| `//xb slotglow` | Public |
| `//xb slotlabelalign` | Advanced / diagnostic |
| `//xb slotlabeloffset` | Advanced / diagnostic |
| `//xb slotlabelstroke` | Advanced / diagnostic |
| `//xb slotrumble` | Advanced / diagnostic |
| `//xb status` | Public |
| `//xb sw` | Compatibility alias / old spelling |
| `//xb switch` | Public |
| `//xb textfade` | Compatibility alias / old spelling |
| `//xb textsettle` | Compatibility alias / old spelling |
| `//xb triggerbanks` | Compatibility alias / old spelling |
| `//xb triggerscale` | Public |
| `//xb ui` | Public |
| `//xb unload` | Public |
| `//xb visibility` | Public |

`preset me` and Me options remain private testing forms. `controller` includes
status/start/stop/profiles/profile plus the five friendly hardware names. Public
help contains the supported usage; undocumented native subcommands are diagnostic.

Keep crossbar (set selection) distinct from crossbars (3-6 eight-slot groups).
