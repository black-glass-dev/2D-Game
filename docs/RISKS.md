# Risk Register

| ID | Risk | Impact | Mitigation | Owner/status |
| --- | --- | --- | --- | --- |
| R-001 | `main.gd` owns startup, HUD, combat wiring, spawning, score, and respawn | High regression risk | Introduce facades/services incrementally; retain a bootable legacy gameplay entry during migration | Active — M1 |
| R-002 | Desert world is procedural and map data is distributed across scripts | High map regression risk | Wrap Desert in `MP_DS_01` compatibility adapter before moving data; retain exact default spawn profile | Active — M1 |
| R-003 | Existing direct input reads have no InputMap/autoload abstraction | Control breakage on touch/desktop | Preserve legacy reads during InputService rollout; test touch, mouse, keyboard, and gamepad per batch | Active — M1 |
| R-004 | Existing settings file has no schema or migration | Loss of player preferences/layout | Add versioned migration with safe defaults and retain old config keys | Active — M1 |
| R-005 | Highrise requires multi-floor navigation, links, rappels, and hazards while Raiders currently use simple direct locomotion | AI can get stuck or bypass level rules | Graybox/nav test harness before art; explicit NavigationLink and fallback route tests | Planned — M4 |
| R-006 | Third-party acquisition may fail or exceed mobile budget | Art or legal blocker | Manifest/hash/license workflow; retry/fallback chain; procedural fallback and blocked-assets log | Planned — M5 |
| R-007 | Hosted Android emulator fails to boot | No CI device-launch proof | Keep export/headless/capture gates; use a physical-device checklist for final classification | Active — M3/M6 |
| R-008 | Branch index had become detached from the published project content | Accidental overwrite/loss during registration | Byte-compare with remote, create safety archive, reset only after matching audit | Mitigated — M0 |
| R-009 | Menu background can consume gameplay performance budget | Slow boot/battery drain | Quality-gated rail camera with static thumbnail fallback | Planned — M2 |
| R-010 | Localization font lacks Bengali glyph coverage | Broken UI text | Noto Sans Bengali Regular/SemiBold is vendored under OFL; verify actual Bengali render in Godot screenshot capture before closing the risk | Active — M1/M2 |
| R-011 | New boot shell may fail to hand legacy Desert state ownership back after threaded loading | Menu works but gameplay state/pause logic becomes inconsistent | Keep `Main.tscn` directly runnable and set Playing only in its `_ready`; use `tools/verify_boot_flow.gd`. The first CI run exposed parser/config defects before hand-off; fixes are re-queued. | Active — M2 |
