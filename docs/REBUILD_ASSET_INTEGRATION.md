# Clean Unity rebuild — player asset integration

The clean Unity runtime is ready to consume the player's 3D models and resource
set without rewriting input, combat, state, or Android build code.

## Drop locations

Place final Unity-ready assets below the following paths before the next
integration batch:

```text
unity/Assets/RedlineRebuild/Resources/Rebuild/Prefabs/
unity/Assets/RedlineRebuild/Resources/Rebuild/Textures/
```

The code automatically uses the final resource when it exists and retains its
safe temporary material/primitive only when it does not.

## Prefab names

| Filename without `.prefab` | Runtime role |
| --- | --- |
| `outpost_left` | left outpost building |
| `outpost_right` | right outpost building |
| `outpost_gate` | far gate |
| `watch_tower` | tower/landmark |
| `crate_stack_a` | left cover dressing |
| `crate_stack_b` | right cover dressing |
| `sandbag_cover` | foreground cover |
| `raider` | hostile actor visual |

## Texture names

| Filename without extension | Runtime role |
| --- | --- |
| `desert_ground` | terrain texture |
| `outpost_concrete` | structure texture |
| `outpost_metal` | gate/tower texture |
| `outpost_crate` | crate texture |

The full machine-readable key list is
[`asset_manifest.json`](../unity/Assets/RedlineRebuild/Resources/Rebuild/asset_manifest.json).

## Import safety

- Prefer `.fbx`, `.obj`, `.glb`, `.png`, `.jpg`, `.wav`, and `.ogg`; Unity will
  import them under `Assets/`.
- Prefabs used for solid cover or enemies should include a Collider.
- Keep supplied models free of gameplay scripts. The rebuild owns interaction,
  health, wave spawning, and AI to avoid returning to the old control/runtime
  failure mode.
- Material shaders will be assigned/verified in the asset-integration batch for
  Android safety; do not rely on an editor-only or pipeline-specific shader.

No player asset is present in the repository yet, so the current APK uses only
the documented temporary fallbacks. This is a prepared integration seam, not a
claim that supplied assets have already been used.
