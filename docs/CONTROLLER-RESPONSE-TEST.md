# Controller Response 1 — October 21, 2026

Runtime directlink1-response1; shared Controls 9.13-response1. Starting source
60cd89d8eea9418f2076b26f808dec225b4e14ce. Development/live test, not a confirmed
cure for sticky inputs. The cumulative changed-files ZIP works over Cleanup 1
(28304f4), Timing 1, Status Cleanup 1 or Startup/Pacts/Registry 1.

## Install

1. Back up xivcrossbar. Run `//xb controller stop`.
2. Unload XIVCrossbar in every client: `//lua u xivcrossbar`.
3. Merge the ZIP's xivcrossbar folder into the installed addon. Preserve data
   and artwork. Do not replace the whole folder or rerun the cleanup helper.
4. Load the addon in each client. With controls released, run
   `//xb controller start` once per computer.
5. `//xb inputstatus` reports directlink1-response1. `//xb controller status`
   reports Controls 9.13-response1 and the actual versus requested route.

## First check

Leave existing input settings alone for this first comparison. Read controller
status in the affected client; requested messages and active messages are
different facts. A keys route remains supported and is now clearly traced.

Start `//xb controller trace on`. In an ordinary harmless native menu, try a few
separated Up/Down taps and one hold/release. If convenient, switch to another
client and return, then try navigation again. Cancel normally. Do not confirm a
transaction, deliberately crash, or repeatedly hold inputs to force a failure.
Stop with `//xb controller trace off`, or let it finish after 31 seconds.

Send the appended controller-input-trace.log and this character's
controller-lua-trace-<character>.log, with the menu and whether it still felt
sticky. An approximate moment helps; no separate chat log is necessary.

The new AHK header records its execution settings. Wrapper lines identify the
actual route, and Lua state lines identify settings/eligibility and keys it
believes it owns even when capture starts during a hold. Focus retry lines show
which prior keys receive another release request. None proves the state FFXI
accepted, so observed cursor movement remains useful evidence.

## What changed

- The Lua focus callback preserves owned keys before receiver cancellation
  clears them, allowing the intended release retry on focus regain. The actual
  callback regression failed before this correction and passes afterward.
- The wrapper sets SetBatchLines -1. Its existing timer provides idle time;
  callbacks no longer contain AHK's additional automatic batch sleeps. It is
  not a busy loop or a promise of 10 ms timing. CPU impact and latency need a
  real Windows comparison.
- Key send delays, F8 timing, POV cardinal/diagonal policy, repeat behavior and
  watchdog/recovery thresholds remain unchanged. Banks and saved bindings stay
  as installed. The patch includes previous updates, including registry tuning.

All 59 Lua regressions and seven JS suites passed. Lua sources parsed using the
documented Lua 5.4 normalization fallback, plus AHK structural/layout checks.
These checks do not execute Windows keyboard delivery, FFXI, or AHK natively.

## If it persists

Investigate in this order, with one variable changed per comparison:

1. Compare start gaps and stage/operation times after the installed registry
   and pacing changes. Slow input sampling can miss whole taps or extend holds.
   A separate AHK timer alone does not make blocking work run in parallel.
2. Verify the actual route. Myrr's supplied 01:09:35 UTC capture used Apps/F3
   with the message receiver disabled; earlier DirectLink tests do not establish
   what that incident exercised. New state fields expose the missing conditions.
3. If sampling is healthy, compare native output: the existing `//xb realkeys on`
   experiment lets AHK send ordinary IJKL and masks those directions from the
   message stream. Requires profile x, messages on, dpad ijkl, inputtest off and
   a neutral handoff. `//xb realkeys off` restores Lua setkey. Test only after the
   first unchanged-settings capture; do not enable this as a blanket repair.
4. Inspect native AHK releases during client switching, Windower/other-addon
   bindings and any gamepad/driver duplicate output if the route comparison
   points there. Controller polling logs do not reveal an unsampled tap or the
   actual in-game key latch. No driver fault or external conflict is established.
5. Only then consider replacing per-frame file mailboxes with a nonblocking
   local transport, retaining sequences, ownership and acknowledgments. LuaSocket
   exists in this addon; a Windows AHK endpoint and lifecycle/security/ordering
   verification would still be new work. Do not equate UDP with reliable delivery.

## Rollback

Stop the wrapper and unload all addon clients. Restore the backed-up code,
reload, and start the prior wrapper once with neutral controls. No settings or
binding migration was performed. Preserve comparison logs.
