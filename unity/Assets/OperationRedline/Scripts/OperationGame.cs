using System.Collections.Generic;
using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Runtime-owned Unity migration implementation. It deliberately creates the
    /// playable Desert operation without generated scene dependencies so a fresh
    /// Unity import has a deterministic Bootstrap -> Menu -> map -> operation
    /// path. Rooftop Highrise remains visibly locked pending its authoritative
    /// design packet; no source-specific layout is invented here.
    /// </summary>
    public sealed class OperationGame : MonoBehaviour
    {
        private enum GameScreen
        {
            Splash,
            Menu,
            MapSelect,
            Settings,
            Gameplay,
            Paused,
            Results,
        }

        private enum SettingsTab
        {
            Graphics,
            Audio,
            Controls,
            Accessibility,
            Other,
        }

        private enum Difficulty
        {
            Easy,
            Normal,
            Hard,
            Nightmare,
        }

        private enum OperationMode
        {
            Survival,
            Endless,
        }

        private static readonly int[] WaveSizes = { 6, 9, 12 };
        private const string DesertMapId = "MP_DS_01";
        private const string HighriseMapId = "MP_RF_02";

        private readonly List<RaiderActor> raiders = new List<RaiderActor>();
        private readonly List<GameObject> worldObjects = new List<GameObject>();
        private readonly List<Material> worldMaterials = new List<Material>();
        private readonly List<DamagePopup> damagePopups = new List<DamagePopup>();
        // First-wave routes deliberately cross the player's forward view so a
        // new mobile session immediately communicates that the operation is live.
        private readonly Vector3[] spawnPoints =
        {
            new Vector3(0f, 1f, 21f), new Vector3(-9f, 1f, 25f),
            new Vector3(9f, 1f, 25f), new Vector3(-16f, 1f, 22f),
            new Vector3(16f, 1f, 22f), new Vector3(0f, 1f, 31f),
        };

        private UnitySettings settings;
        private UnityProgress progress;
        private UnityControls controls;
        private GameScreen screen;
        private GameScreen settingsReturnScreen = GameScreen.Menu;
        private SettingsTab settingsTab;
        private Difficulty selectedDifficulty = Difficulty.Normal;
        private OperationMode selectedMode = OperationMode.Survival;
        private UnityControls.Action? rebindCapture;
        private int rebindSelection;

        private float splashUntil;
        private Transform playerRoot;
        private OutpostPlayerController playerController;
        private float health;
        private float regenerationWait;
        private int score;
        private int wave;
        private int pendingSpawns;
        private int spawnSerial;
        private float waveDelay;
        private float spawnDelay;
        private bool operationComplete;
        private bool operationFailed;
        private bool resultRecorded;
        private int shotsFired;
        private int shotsHit;
        private int headshots;
        private float fpsSample;
        private float fpsTimer;

        private UnityWeaponState carbine;
        private UnityWeaponState sidearm;
        private UnityWeaponState activeWeapon;
        private TacticalRadar tacticalRadar;
        private UnityHudLayout hudLayout;
        private bool hudEditMode;
        private UnityHudLayout.Element? hudDragElement;
        private Vector2 hudDragOffset;
        private AudioSource music;
        private AudioSource effects;
        private AudioSource uiEffects;
        private AudioClip rifleShot;
        private AudioClip pistolShot;
        private AudioClip reloadClick;
        private AudioClip landingThump;
        private Texture2D menuBackdrop;
        private Texture2D desertGroundTexture;
        private Texture2D concreteTexture;
        private Texture2D metalTexture;
        private Texture2D crateTexture;
        private Shader mobileDesertShader;
        private Font bengaliFont;
        private string soundCaption;
        private float soundCaptionUntil;
        private Color baseAmbient;
        private bool mobileFireHeld;
        private bool mobileFirePressed;
        private bool mobileAimHeld;
        private Texture2D mobileControlDisc;

        private struct MobileActionLayout
        {
            public Rect Fire;
            public Rect Aim;
            public Rect Reload;
            public Rect Swap;
            public Rect Jump;
            public Rect Crouch;
            public Rect Pause;
            public Rect Radar;
        }

        private struct DamagePopup
        {
            public Vector3 WorldPosition;
            public string Text;
            public Color Color;
            public float ExpiresAt;
        }

        public bool IsGameplayStopped { get { return screen != GameScreen.Gameplay; } }

        private void Awake()
        {
            settings = new UnitySettings();
            progress = new UnityProgress();
            controls = new UnityControls();
            splashUntil = Time.unscaledTime + 1.15f;
            screen = GameScreen.Splash;
            baseAmbient = RenderSettings.ambientLight;
            LoadPresentationAssets();
            CreateAudio();
            tacticalRadar = gameObject.AddComponent<TacticalRadar>();
            hudLayout = new UnityHudLayout();
            ApplyPresentationSettings();
        }

        private void LoadPresentationAssets()
        {
            menuBackdrop = Resources.Load<Texture2D>("UI/menu_desert_outpost");
            desertGroundTexture = Resources.Load<Texture2D>("Textures/desert_outpost_ground");
            concreteTexture = Resources.Load<Texture2D>("Textures/outpost_concrete");
            metalTexture = Resources.Load<Texture2D>("Textures/outpost_corrugated_metal");
            crateTexture = Resources.Load<Texture2D>("Textures/outpost_weathered_crate");
            mobileDesertShader = Resources.Load<Shader>("Shaders/OperationRedlineMobile");
            if (mobileDesertShader == null)
            {
                Debug.LogError("Operation Redline mobile world shader is missing; the Desert Outpost cannot safely fall back to a stripped default material.");
            }
            SetTextureRepeat(desertGroundTexture);
            SetTextureRepeat(concreteTexture);
            SetTextureRepeat(metalTexture);
            SetTextureRepeat(crateTexture);
            bengaliFont = Resources.Load<Font>("Fonts/NotoSansBengali-Regular");
            mobileControlDisc = CreateMobileControlDisc();
            rifleShot = Resources.Load<AudioClip>("Audio/rifle_shot");
            pistolShot = Resources.Load<AudioClip>("Audio/pistol_shot");
            reloadClick = Resources.Load<AudioClip>("Audio/reload_click");
            landingThump = Resources.Load<AudioClip>("Audio/landing_thump");
        }

        private static void SetTextureRepeat(Texture2D texture)
        {
            if (texture != null)
            {
                texture.wrapMode = TextureWrapMode.Repeat;
            }
        }

        private Texture2D CreateMobileControlDisc()
        {
            const int size = 64;
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var pixels = new Color32[size * size];
            var center = (size - 1) * 0.5f;
            var outerRadius = center - 1f;
            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    var distance = Vector2.Distance(new Vector2(x, y), new Vector2(center, center));
                    var alpha = distance <= outerRadius ? (byte)(distance > outerRadius - 2f ? 115 : 185) : (byte)0;
                    pixels[y * size + x] = new Color32(166, 229, 240, alpha);
                }
            }
            texture.SetPixels32(pixels);
            texture.Apply(false, true);
            return texture;
        }

        private void CreateAudio()
        {
            music = gameObject.AddComponent<AudioSource>();
            music.name = "Outpost Watch Music";
            music.clip = Resources.Load<AudioClip>("Audio/outpost_watch");
            music.loop = true;
            music.playOnAwake = false;
            if (music.clip != null)
            {
                music.Play();
            }

            effects = gameObject.AddComponent<AudioSource>();
            effects.name = "Combat SFX";
            effects.playOnAwake = false;
            uiEffects = gameObject.AddComponent<AudioSource>();
            uiEffects.name = "UI SFX";
            uiEffects.playOnAwake = false;
        }

        private void OnApplicationFocus(bool hasFocus)
        {
            if (settings != null && settings.MuteWhenUnfocused)
            {
                AudioListener.pause = !hasFocus;
            }
        }

        private void Update()
        {
            ApplyAudioSettings();
            fpsTimer += Time.unscaledDeltaTime;
            if (fpsTimer >= 0.25f)
            {
                fpsSample = 1f / Mathf.Max(0.001f, Time.unscaledDeltaTime);
                fpsTimer = 0f;
            }

            if (screen == GameScreen.Splash && Time.unscaledTime >= splashUntil)
            {
                screen = GameScreen.Menu;
            }

            if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.JoystickButton1))
            {
                HandleBack();
            }

            if (screen == GameScreen.Gameplay)
            {
                UpdateGameplay();
            }
        }

        private void HandleBack()
        {
            if (screen == GameScreen.Gameplay)
            {
                PauseOperation();
            }
            else if (screen == GameScreen.Paused)
            {
                ResumeOperation();
            }
            else if (screen == GameScreen.Settings)
            {
                screen = settingsReturnScreen;
            }
            else if (screen == GameScreen.MapSelect || screen == GameScreen.Results)
            {
                screen = GameScreen.Menu;
            }
            else if (screen == GameScreen.Menu)
            {
                Application.Quit();
            }
        }

        private void BeginOperation()
        {
            ClearWorld();
            BuildDesertOutpost();
            health = 100f;
            regenerationWait = 0f;
            score = 0;
            wave = 0;
            pendingSpawns = 0;
            spawnSerial = 0;
            waveDelay = 0.45f;
            spawnDelay = 0f;
            operationComplete = false;
            operationFailed = false;
            resultRecorded = false;
            shotsFired = 0;
            shotsHit = 0;
            headshots = 0;
            mobileFireHeld = false;
            mobileFirePressed = false;
            mobileAimHeld = false;
            damagePopups.Clear();
            carbine = new UnityWeaponState(WeaponKind.Carbine);
            sidearm = new UnityWeaponState(WeaponKind.Sidearm);
            activeWeapon = carbine;
            progress.SetLastMap(DesertMapId);
            screen = GameScreen.Gameplay;
            SetGameplayCursor(true);
        }

        private void PauseOperation()
        {
            if (screen != GameScreen.Gameplay)
            {
                return;
            }
            screen = GameScreen.Paused;
            SetGameplayCursor(false);
        }

        private void ResumeOperation()
        {
            if (screen != GameScreen.Paused)
            {
                return;
            }
            screen = GameScreen.Gameplay;
            SetGameplayCursor(true);
        }

        private void SetGameplayCursor(bool active)
        {
            if (Application.isMobilePlatform)
            {
                return;
            }
            Cursor.lockState = active ? CursorLockMode.Locked : CursorLockMode.None;
            Cursor.visible = !active;
        }

        private void UpdateGameplay()
        {
            if (playerRoot == null || playerController == null || playerController.PlayerCamera == null)
            {
                FinishOperation(false);
                return;
            }

            var mobileLayout = ResolveMobileActionLayout();
            UpdateMobileActionInput(mobileLayout);
            if (screen != GameScreen.Gameplay)
            {
                return;
            }

            var desktopPointer = !Application.isMobilePlatform;
            var isAiming = mobileAimHeld || Input.GetKey(controls.GetKey(UnityControls.Action.Aim)) || (desktopPointer && Input.GetMouseButton(1)) || Input.GetKey(KeyCode.JoystickButton4);
            playerController.SetAiming(isAiming);
            playerController.UpdateMovement(true);
            if (playerController.LandedThisFrame)
            {
                PlayEffect(landingThump, 0.6f);
                ShowCaption("caption.landing");
            }

            carbine.Update(Time.unscaledDeltaTime);
            sidearm.Update(Time.unscaledDeltaTime);
            if (Input.GetKeyDown(controls.GetKey(UnityControls.Action.Reload)) || Input.GetKeyDown(KeyCode.JoystickButton2))
            {
                StartReload();
            }
            if (Input.GetKeyDown(controls.GetKey(UnityControls.Action.SwapWeapon)) || Input.GetKeyDown(KeyCode.JoystickButton3))
            {
                SwitchWeapon();
            }

            var fireHeld = mobileFireHeld || Input.GetKey(controls.GetKey(UnityControls.Action.Fire)) || (desktopPointer && Input.GetMouseButton(0)) || Input.GetKey(KeyCode.JoystickButton5);
            if (fireHeld && (settings.AutoFire || mobileFirePressed || Input.GetKeyDown(controls.GetKey(UnityControls.Action.Fire)) || (desktopPointer && Input.GetMouseButtonDown(0)) || Input.GetKeyDown(KeyCode.JoystickButton5)))
            {
                FireActiveWeapon();
            }
            mobileFirePressed = false;

            UpdateHealthRegeneration();
            UpdateWaveSpawning();
        }

        private MobileActionLayout ResolveMobileActionLayout()
        {
            var screenSize = new Vector2(Screen.width, Screen.height);
            var fireSize = new Vector2(118f * settings.ButtonScale, 104f * settings.ButtonScale);
            var fire = hudLayout.Resolve(UnityHudLayout.Element.Fire, fireSize, screenSize, settings.LeftHanded);
            var pause = hudLayout.Resolve(UnityHudLayout.Element.Pause, new Vector2(115f, 36f), screenSize, settings.LeftHanded);
            var radar = hudLayout.Resolve(UnityHudLayout.Element.Radar, new Vector2(122f, 122f), screenSize, settings.LeftHanded);
            var supportWidth = 82f;
            var direction = settings.LeftHanded ? 1f : -1f;
            var supportX = Mathf.Clamp(fire.center.x + direction * (fire.width * 0.5f + supportWidth * 0.5f + 9f), 8f, Screen.width - supportWidth - 8f);
            var lowerY = Mathf.Clamp(fire.y + fire.height - 52f, 8f, Screen.height - 52f);
            return new MobileActionLayout
            {
                Fire = fire,
                Aim = new Rect(supportX - supportWidth * 0.5f, lowerY, supportWidth, 52f),
                Reload = new Rect(supportX - supportWidth * 0.5f, Mathf.Max(8f, fire.y - 60f), supportWidth, 48f),
                Swap = new Rect(supportX - supportWidth * 0.5f, Mathf.Max(8f, fire.y - 114f), supportWidth, 48f),
                Jump = new Rect(supportX - supportWidth * 0.5f, Mathf.Max(8f, fire.y - 168f), supportWidth, 48f),
                Crouch = new Rect(supportX - supportWidth * 0.5f, Mathf.Max(8f, fire.y - 222f), supportWidth, 48f),
                Pause = pause,
                Radar = radar,
            };
        }

        private void UpdateMobileActionInput(MobileActionLayout layout)
        {
            mobileFireHeld = false;
            mobileFirePressed = false;
            mobileAimHeld = false;
            playerController.SetMobileUiExclusions(new[]
            {
                layout.Fire, layout.Aim, layout.Reload, layout.Swap, layout.Jump, layout.Crouch, layout.Pause, layout.Radar,
            });
            if (!Application.isMobilePlatform)
            {
                return;
            }

            foreach (var touch in Input.touches)
            {
                var guiPosition = new Vector2(touch.position.x, Screen.height - touch.position.y);
                var held = touch.phase == TouchPhase.Began || touch.phase == TouchPhase.Moved || touch.phase == TouchPhase.Stationary;
                if (held && layout.Fire.Contains(guiPosition))
                {
                    mobileFireHeld = true;
                    if (touch.phase == TouchPhase.Began)
                    {
                        mobileFirePressed = true;
                    }
                }
                if (held && layout.Aim.Contains(guiPosition))
                {
                    mobileAimHeld = true;
                }
                if (touch.phase == TouchPhase.Began && HandleMobileActionTap(layout, guiPosition))
                {
                    return;
                }
            }

            // Some Android device/input-handler combinations expose a primary
            // touch through mouse state but do not populate Input.touches.
            // Keep the action surface responsive without turning arbitrary
            // screen taps into shots.
            if (Input.touchCount == 0 && Input.GetMouseButton(0))
            {
                var guiPosition = new Vector2(Input.mousePosition.x, Screen.height - Input.mousePosition.y);
                if (layout.Fire.Contains(guiPosition))
                {
                    mobileFireHeld = true;
                    mobileFirePressed = Input.GetMouseButtonDown(0);
                }
                if (layout.Aim.Contains(guiPosition))
                {
                    mobileAimHeld = true;
                }
                if (Input.GetMouseButtonDown(0) && HandleMobileActionTap(layout, guiPosition))
                {
                    return;
                }
            }
        }

        private bool HandleMobileActionTap(MobileActionLayout layout, Vector2 guiPosition)
        {
            if (layout.Pause.Contains(guiPosition))
            {
                PauseOperation();
                return true;
            }
            if (layout.Reload.Contains(guiPosition)) StartReload();
            if (layout.Swap.Contains(guiPosition)) SwitchWeapon();
            if (layout.Jump.Contains(guiPosition)) playerController.RequestTouchJump();
            if (layout.Crouch.Contains(guiPosition)) playerController.ToggleCrouch();
            return false;
        }

        private void UpdateHealthRegeneration()
        {
            if (regenerationWait > 0f)
            {
                regenerationWait -= Time.unscaledDeltaTime;
                return;
            }
            health = Mathf.Min(100f, health + 11f * Time.unscaledDeltaTime);
        }

        private void UpdateWaveSpawning()
        {
            if (pendingSpawns > 0)
            {
                spawnDelay -= Time.unscaledDeltaTime;
                if (spawnDelay <= 0f)
                {
                    SpawnRaider();
                    pendingSpawns--;
                    spawnDelay = Mathf.Max(0.38f, 0.95f - wave * 0.04f) / DifficultySpawnRate();
                }
                return;
            }

            if (raiders.Count > 0)
            {
                return;
            }

            waveDelay -= Time.unscaledDeltaTime;
            if (waveDelay > 0f)
            {
                return;
            }

            if (selectedMode == OperationMode.Survival && wave >= WaveSizes.Length)
            {
                FinishOperation(true);
                return;
            }

            wave++;
            var baseSize = WaveSizes[(wave - 1) % WaveSizes.Length];
            pendingSpawns = Mathf.Max(1, Mathf.RoundToInt(baseSize * DifficultyEnemyCount()));
            // Spawn the first contact immediately. On a phone, a silent empty
            // world during the initial cadence is easily mistaken for a freeze.
            SpawnRaider();
            pendingSpawns--;
            spawnDelay = 0.42f;
            waveDelay = 2.4f;
        }

        private float DifficultyEnemyCount()
        {
            switch (selectedDifficulty)
            {
                case Difficulty.Easy: return 0.75f;
                case Difficulty.Hard: return 1.25f;
                case Difficulty.Nightmare: return 1.45f;
                default: return 1f;
            }
        }

        private float DifficultySpawnRate()
        {
            switch (selectedDifficulty)
            {
                case Difficulty.Easy: return 0.82f;
                case Difficulty.Hard: return 1.18f;
                case Difficulty.Nightmare: return 1.35f;
                default: return 1f;
            }
        }

        private float DifficultyDamageMultiplier()
        {
            switch (selectedDifficulty)
            {
                case Difficulty.Easy: return 0.78f;
                case Difficulty.Hard: return 1.2f;
                case Difficulty.Nightmare: return 1.4f;
                default: return 1f;
            }
        }

        private void SpawnRaider()
        {
            var enemy = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            enemy.name = "Raider Wave " + wave;
            var spawn = spawnPoints[spawnSerial % spawnPoints.Length];
            spawnSerial++;
            enemy.transform.position = spawn;
            enemy.transform.localScale = new Vector3(1.1f, 1.3f, 1.1f);
            var renderer = enemy.GetComponent<Renderer>();
            ApplyWorldMaterial(renderer, wave % WaveSizes.Length == 0 ? new Color(0.58f, 0.16f, 0.12f) : new Color(0.35f, 0.24f, 0.16f));
            var actor = enemy.AddComponent<RaiderActor>();
            actor.Initialize(this, playerRoot, wave, DifficultyDamageMultiplier());
            raiders.Add(actor);
            worldObjects.Add(enemy);
        }

        private void FireActiveWeapon()
        {
            if (activeWeapon == null || playerController == null || !activeWeapon.TryFire())
            {
                return;
            }

            shotsFired++;
            PlayEffect(activeWeapon.Kind == WeaponKind.Carbine ? rifleShot : pistolShot, 0.58f);
            ShowCaption(activeWeapon.Kind == WeaponKind.Carbine ? "caption.rifle_fire" : "caption.pistol_fire");
            var origin = playerController.PlayerCamera.transform.position;
            var direction = ApplyMobileAimAssist(playerController.PlayerCamera.transform.forward);
            var destination = origin + direction * activeWeapon.Range;
            if (Physics.Raycast(origin, direction, out var hit, activeWeapon.Range))
            {
                destination = hit.point;
                var enemy = hit.collider.GetComponentInParent<RaiderActor>();
                if (enemy != null)
                {
                    var headshot = hit.point.y > enemy.transform.position.y + 1.25f;
                    enemy.TakeDamage(activeWeapon.Damage, headshot);
                    shotsHit++;
                    if (headshot)
                    {
                        headshots++;
                    }
                    if (settings.DamageNumbers)
                    {
                        damagePopups.Add(new DamagePopup
                        {
                            WorldPosition = hit.point + Vector3.up * 0.38f,
                            Text = (headshot ? activeWeapon.Damage * 2f : activeWeapon.Damage).ToString("0"),
                            Color = headshot ? new Color(1f, 0.78f, 0.24f) : Color.white,
                            ExpiresAt = Time.unscaledTime + 0.72f,
                        });
                    }
                }
            }
            if (settings.ScreenEffects)
            {
                CreateShotTracer(origin, destination);
            }
        }

        private Vector3 ApplyMobileAimAssist(Vector3 direction)
        {
            if (!Application.isMobilePlatform || !settings.AimAssist || playerController == null)
            {
                return direction;
            }
            var origin = playerController.PlayerCamera.transform.position;
            var bestDirection = direction;
            var bestAlignment = 0.992f;
            foreach (var raider in raiders)
            {
                if (raider == null)
                {
                    continue;
                }
                var targetPoint = raider.transform.position + Vector3.up * 1.2f;
                var toTarget = targetPoint - origin;
                var distance = toTarget.magnitude;
                if (distance < 1f || distance > activeWeapon.Range)
                {
                    continue;
                }
                var candidate = toTarget / distance;
                var alignment = Vector3.Dot(direction, candidate);
                if (alignment > bestAlignment)
                {
                    bestAlignment = alignment;
                    bestDirection = candidate;
                }
            }
            return Vector3.Slerp(direction, bestDirection, 0.16f).normalized;
        }

        private void CreateShotTracer(Vector3 origin, Vector3 destination)
        {
            var direction = destination - origin;
            var length = direction.magnitude;
            if (length <= 0.01f)
            {
                return;
            }
            var tracer = GameObject.CreatePrimitive(PrimitiveType.Cube);
            tracer.name = "Shot Tracer";
            tracer.transform.position = origin + direction * 0.5f;
            tracer.transform.rotation = Quaternion.LookRotation(direction);
            tracer.transform.localScale = new Vector3(0.018f, 0.018f, length);
            var renderer = tracer.GetComponent<Renderer>();
            ApplyWorldMaterial(renderer, new Color(1f, 0.8f, 0.28f));
            var collider = tracer.GetComponent<Collider>();
            if (collider != null)
            {
                collider.enabled = false;
            }
            tracer.AddComponent<UnityTransientEffect>().Initialize(settings.ReducedMotion ? 0.025f : 0.055f);
        }

        private void StartReload()
        {
            if (activeWeapon != null && activeWeapon.StartReload())
            {
                PlayEffect(reloadClick, 0.55f);
                ShowCaption("caption.reloading");
            }
        }

        private void SwitchWeapon()
        {
            if (carbine == null || sidearm == null || activeWeapon == null || activeWeapon.IsReloading)
            {
                return;
            }
            activeWeapon = activeWeapon.Kind == WeaponKind.Carbine ? sidearm : carbine;
            PlayUiEffect();
        }

        public void OnRaiderEliminated(RaiderActor actor, bool headshot)
        {
            raiders.Remove(actor);
            score += headshot ? 150 : 100;
        }

        public void ApplyPlayerDamage(float amount)
        {
            if (screen != GameScreen.Gameplay)
            {
                return;
            }
            health = Mathf.Max(0f, health - amount);
            regenerationWait = 4f;
            if (settings.Haptics && Application.isMobilePlatform)
            {
                Handheld.Vibrate();
            }
            if (health <= 0f)
            {
                FinishOperation(false);
            }
        }

        private void FinishOperation(bool complete)
        {
            if (screen == GameScreen.Results)
            {
                return;
            }
            operationComplete = complete;
            operationFailed = !complete;
            if (!resultRecorded)
            {
                progress.RecordResult(DesertMapId, score, wave);
                resultRecorded = true;
            }
            screen = GameScreen.Results;
            SetGameplayCursor(false);
        }

        private void BuildDesertOutpost()
        {
            var world = new GameObject("MP_DS_01 Desert Outpost");
            worldObjects.Add(world);

            var light = new GameObject("Desert Sun").AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.15f;
            light.color = new Color(1f, 0.77f, 0.5f);
            light.shadows = LightShadows.Soft;
            light.transform.rotation = Quaternion.Euler(42f, -34f, 0f);
            worldObjects.Add(light.gameObject);

            RenderSettings.ambientLight = new Color(0.37f, 0.36f, 0.31f) * settings.Brightness;
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.63f, 0.48f, 0.32f);
            RenderSettings.fogDensity = 0.006f;

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Desert Ground — textured mobile-safe terrain";
            ground.transform.localScale = new Vector3(12f, 1f, 12f);
            ApplyWorldMaterial(ground.GetComponent<Renderer>(), Color.white, desertGroundTexture, new Vector2(4f, 4f));
            worldObjects.Add(ground);

            CreateBlock("Command Yard", new Vector3(0f, 2.2f, -8f), new Vector3(14f, 4.4f, 6f), new Color(0.54f, 0.58f, 0.53f), concreteTexture, new Vector2(3f, 2f));
            CreateBlock("North Hangar", new Vector3(-20f, 2f, -24f), new Vector3(13f, 4f, 9f), new Color(0.56f, 0.59f, 0.52f), metalTexture, new Vector2(3f, 2f));
            CreateBlock("South Checkpoint", new Vector3(21f, 1.3f, 20f), new Vector3(11f, 2.6f, 5f), new Color(0.62f, 0.53f, 0.38f), concreteTexture, new Vector2(2f, 2f));
            CreateBlock("Radio Tower", new Vector3(28f, 8f, -8f), new Vector3(2.2f, 16f, 2.2f), new Color(0.33f, 0.42f, 0.42f), metalTexture, new Vector2(2f, 4f));
            CreateBlock("Outpost Gate", new Vector3(0f, 2.6f, 37f), new Vector3(17f, 5.2f, 1.3f), new Color(0.38f, 0.52f, 0.49f), metalTexture, new Vector2(4f, 2f));
            for (var index = 0; index < 8; index++)
            {
                var position = new Vector3(-35f + index * 10f, 1f, 32f);
                CreateBlock("Supply Cover " + index, position, new Vector3(3.6f, 2f, 2.2f), new Color(0.72f, 0.56f, 0.32f), crateTexture, new Vector2(1.5f, 1f));
            }
            CreateOutpostDetails();

            var root = new GameObject("Player");
            root.transform.position = new Vector3(0f, 1.05f, 13f);
            playerRoot = root.transform;
            var character = root.AddComponent<CharacterController>();
            character.height = 1.8f;
            character.radius = 0.38f;
            character.center = new Vector3(0f, 0.9f, 0f);
            playerController = root.AddComponent<OutpostPlayerController>();
            playerController.Initialize(settings, controls);
            worldObjects.Add(root);
        }

        private void CreateBlock(string blockName, Vector3 position, Vector3 scale, Color color, Texture2D texture = null, Vector2? textureTiling = null)
        {
            var block = GameObject.CreatePrimitive(PrimitiveType.Cube);
            block.name = blockName;
            block.transform.position = position;
            block.transform.localScale = scale;
            ApplyWorldMaterial(block.GetComponent<Renderer>(), color, texture, textureTiling);
            worldObjects.Add(block);
        }

        private void CreateOutpostDetails()
        {
            CreateCylinder("Signal Mast", new Vector3(-7f, 4.7f, -2f), new Vector3(0.42f, 4.7f, 0.42f), new Color(0.32f, 0.46f, 0.43f), metalTexture);
            CreateCylinder("Fuel Drum A", new Vector3(10f, 0.62f, 7f), new Vector3(0.58f, 0.62f, 0.58f), new Color(0.75f, 0.27f, 0.12f), metalTexture);
            CreateCylinder("Fuel Drum B", new Vector3(11.4f, 0.62f, 7.8f), new Vector3(0.58f, 0.62f, 0.58f), new Color(0.16f, 0.47f, 0.49f), metalTexture);
            CreateCylinder("Fuel Drum C", new Vector3(9.1f, 0.62f, 8.1f), new Vector3(0.58f, 0.62f, 0.58f), new Color(0.75f, 0.27f, 0.12f), metalTexture);
            CreateBlock("Sandbag Wall West", new Vector3(-11f, 0.7f, 7f), new Vector3(6.2f, 1.4f, 1.2f), new Color(0.68f, 0.51f, 0.3f), crateTexture, new Vector2(2f, 1f));
            CreateBlock("Sandbag Wall East", new Vector3(12f, 0.7f, -3f), new Vector3(1.2f, 1.4f, 6.2f), new Color(0.68f, 0.51f, 0.3f), crateTexture, new Vector2(2f, 1f));
            CreateBlock("Radio Array", new Vector3(27.4f, 16.7f, -8f), new Vector3(5.2f, 0.32f, 0.32f), new Color(0.88f, 0.7f, 0.3f), metalTexture, new Vector2(2f, 1f));
        }

        private void CreateCylinder(string objectName, Vector3 position, Vector3 scale, Color color, Texture2D texture = null)
        {
            var cylinder = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            cylinder.name = objectName;
            cylinder.transform.position = position;
            cylinder.transform.localScale = scale;
            ApplyWorldMaterial(cylinder.GetComponent<Renderer>(), color, texture, texture == null ? (Vector2?)null : new Vector2(1f, 2f));
            worldObjects.Add(cylinder);
        }

        private void ApplyWorldMaterial(Renderer renderer, Color tint, Texture2D texture = null, Vector2? textureTiling = null)
        {
            if (renderer == null || mobileDesertShader == null)
            {
                return;
            }
            var material = new Material(mobileDesertShader)
            {
                color = tint,
                mainTexture = texture == null ? Texture2D.whiteTexture : texture,
            };
            material.mainTextureScale = textureTiling ?? Vector2.one;
            renderer.sharedMaterial = material;
            worldMaterials.Add(material);
        }

        private void ClearWorld()
        {
            foreach (var objectInWorld in worldObjects)
            {
                if (objectInWorld != null)
                {
                    Destroy(objectInWorld);
                }
            }
            worldObjects.Clear();
            foreach (var material in worldMaterials)
            {
                if (material != null)
                {
                    Destroy(material);
                }
            }
            worldMaterials.Clear();
            raiders.Clear();
            damagePopups.Clear();
            playerRoot = null;
            playerController = null;
            RenderSettings.fog = false;
            RenderSettings.ambientLight = baseAmbient;
        }

        private void ApplyPresentationSettings()
        {
            ApplyAudioSettings();
            if (playerController != null)
            {
                playerController.ApplySettings();
            }
            if (screen == GameScreen.Gameplay)
            {
                RenderSettings.ambientLight = new Color(0.37f, 0.36f, 0.31f) * settings.Brightness;
            }
        }

        private void ApplyAudioSettings()
        {
            AudioListener.volume = settings == null ? 1f : settings.MasterVolume;
            if (music != null)
            {
                music.volume = settings.MusicVolume;
                if (music.clip != null && settings.MusicVolume > 0f && !music.isPlaying && !AudioListener.pause)
                {
                    music.Play();
                }
                if (settings.MusicVolume <= 0f && music.isPlaying)
                {
                    music.Stop();
                }
            }
            if (effects != null) effects.volume = settings.SfxVolume;
            if (uiEffects != null) uiEffects.volume = settings.UiVolume;
        }

        private void PlayEffect(AudioClip clip, float volume)
        {
            if (clip != null && effects != null && settings.SfxVolume > 0f)
            {
                effects.PlayOneShot(clip, volume);
            }
        }

        private void PlayUiEffect()
        {
            if (reloadClick != null && uiEffects != null && settings.UiVolume > 0f)
            {
                uiEffects.PlayOneShot(reloadClick, 0.32f);
            }
        }

        private void ShowCaption(string key)
        {
            if (!settings.Subtitles)
            {
                return;
            }
            soundCaption = LocalizedCatalog.Get(key, settings.Language);
            soundCaptionUntil = Time.unscaledTime + 1.1f;
        }

        private void OnGUI()
        {
            ProcessRebindCapture();
            var titleStyle = Style(42, new Color(0.56f, 0.97f, 1f), TextAnchor.MiddleCenter, true);
            var subtitleStyle = Style(18, new Color(1f, 0.58f, 0.25f), TextAnchor.MiddleCenter, false);
            var bodyStyle = Style(18, Color.white, TextAnchor.MiddleCenter, false);
            var leftStyle = Style(17, Color.white, TextAnchor.UpperLeft, false);
            var buttonStyle = Style(19, Color.white, TextAnchor.MiddleCenter, true);

            if (screen != GameScreen.Gameplay)
            {
                DrawMenuBackdrop();
            }

            if (screen == GameScreen.Splash)
            {
                GUI.Label(new Rect(0, Screen.height * 0.31f, Screen.width, 65), T("app.title"), titleStyle);
                GUI.Label(new Rect(0, Screen.height * 0.41f, Screen.width, 32), T("app.subtitle"), subtitleStyle);
                GUI.Label(new Rect(0, Screen.height * 0.59f, Screen.width, 30), T("menu.press_to_continue"), bodyStyle);
                if (Event.current.type == EventType.MouseDown || Input.anyKeyDown)
                {
                    screen = GameScreen.Menu;
                }
                return;
            }

            if (screen == GameScreen.Menu)
            {
                DrawMenu(titleStyle, subtitleStyle, buttonStyle);
                return;
            }

            if (screen == GameScreen.MapSelect)
            {
                DrawMapSelect(titleStyle, bodyStyle, buttonStyle);
                return;
            }

            if (screen == GameScreen.Settings)
            {
                DrawSettings(titleStyle, bodyStyle, leftStyle, buttonStyle);
                return;
            }

            if (screen == GameScreen.Gameplay)
            {
                DrawGameplayHud(leftStyle, bodyStyle, buttonStyle);
                return;
            }

            if (screen == GameScreen.Paused)
            {
                DrawPause(titleStyle, buttonStyle);
                return;
            }

            if (screen == GameScreen.Results)
            {
                DrawResults(titleStyle, bodyStyle, buttonStyle);
            }
        }

        private void DrawMenu(GUIStyle titleStyle, GUIStyle subtitleStyle, GUIStyle buttonStyle)
        {
            DrawPanel(new Rect(Screen.width * 0.5f - 235f, Screen.height * 0.5f - 180f, 470f, 380f));
            GUI.Label(new Rect(0, Screen.height * 0.16f, Screen.width, 58), T("app.title"), titleStyle);
            GUI.Label(new Rect(0, Screen.height * 0.25f, Screen.width, 32), T("app.subtitle"), subtitleStyle);
            if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.43f, 340f, 58f), T("menu.play"), buttonStyle)) screen = GameScreen.MapSelect;
            if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.51f, 340f, 58f), T("menu.continue"), buttonStyle)) BeginOperation();
            if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.59f, 340f, 58f), T("menu.settings"), buttonStyle))
            {
                settingsReturnScreen = GameScreen.Menu;
                screen = GameScreen.Settings;
            }
            if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.67f, 340f, 58f), T("menu.quit"), buttonStyle)) Application.Quit();
        }

        private void DrawMapSelect(GUIStyle titleStyle, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            DrawPanel(new Rect(35f, 85f, Screen.width - 70f, Screen.height - 150f));
            GUI.Label(new Rect(0, 28f, Screen.width, 45f), T("menu.map_select"), titleStyle);
            DrawDesertCard(new Rect(Screen.width * 0.12f, 130f, Screen.width * 0.34f, 390f), bodyStyle, buttonStyle);
            DrawHighriseCard(new Rect(Screen.width * 0.54f, 130f, Screen.width * 0.34f, 390f), bodyStyle);
            if (Button(new Rect(42f, Screen.height - 60f, 180f, 42f), T("menu.back"), buttonStyle)) screen = GameScreen.Menu;
        }

        private void DrawDesertCard(Rect rect, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            DrawPanel(rect);
            GUI.Label(new Rect(rect.x + 18f, rect.y + 18f, rect.width - 36f, 48f), T("map.desert_outpost"), Style(24, new Color(1f, 0.7f, 0.39f), TextAnchor.MiddleCenter, true));
            GUI.Label(new Rect(rect.x + 20f, rect.y + 76f, rect.width - 40f, 75f), "MP_DS_01\n" + T("map.waves") + "  6 / 9 / 12", bodyStyle);
            GUI.Label(new Rect(rect.x + 20f, rect.y + 150f, rect.width - 40f, 30f), T("map.difficulty") + ": " + DifficultyLabel(), bodyStyle);
            if (Button(new Rect(rect.x + 25f, rect.y + 184f, rect.width - 50f, 40f), DifficultyLabel(), buttonStyle)) CycleDifficulty();
            GUI.Label(new Rect(rect.x + 20f, rect.y + 230f, rect.width - 40f, 30f), T("map.mode") + ": " + ModeLabel(), bodyStyle);
            if (Button(new Rect(rect.x + 25f, rect.y + 264f, rect.width - 50f, 40f), ModeLabel(), buttonStyle)) CycleMode();
            var record = progress.GetRecord(DesertMapId);
            var recordText = record.BestScore > 0 || record.BestWave > 0
                ? T("map.best_score") + ": " + record.BestScore + "\n" + T("map.best_wave") + ": " + record.BestWave
                : T("map.no_record");
            GUI.Label(new Rect(rect.x + 20f, rect.y + 307f, rect.width - 40f, 46f), recordText, bodyStyle);
            if (Button(new Rect(rect.x + 25f, rect.y + rect.height - 58f, rect.width - 50f, 42f), T("menu.start_mission"), buttonStyle)) BeginOperation();
        }

        private void DrawHighriseCard(Rect rect, GUIStyle bodyStyle)
        {
            DrawPanel(rect);
            GUI.Label(new Rect(rect.x + 18f, rect.y + 18f, rect.width - 36f, 48f), T("map.rooftop_highrise"), Style(24, new Color(0.78f, 0.57f, 0.42f), TextAnchor.MiddleCenter, true));
            GUI.Label(new Rect(rect.x + 20f, rect.y + 88f, rect.width - 40f, 150f), "MP_RF_02\n\n" + T("map.unavailable_detail"), bodyStyle);
            GUI.Label(new Rect(rect.x + 18f, rect.y + rect.height - 72f, rect.width - 36f, 45f), T("menu.coming_soon") + "  •  " + T("menu.locked"), Style(18, new Color(0.78f, 0.57f, 0.42f), TextAnchor.MiddleCenter, true));
        }

        private void DrawSettings(GUIStyle titleStyle, GUIStyle bodyStyle, GUIStyle leftStyle, GUIStyle buttonStyle)
        {
            var panel = new Rect(Screen.width * 0.5f - 350f, 60f, 700f, Screen.height - 125f);
            DrawPanel(panel);
            GUI.Label(new Rect(0, 17f, Screen.width, 36f), T("menu.settings"), titleStyle);
            var tabs = new[] { SettingsTab.Graphics, SettingsTab.Audio, SettingsTab.Controls, SettingsTab.Accessibility, SettingsTab.Other };
            for (var index = 0; index < tabs.Length; index++)
            {
                var tab = tabs[index];
                var rect = new Rect(panel.x + 12f + index * 136f, panel.y + 56f, 128f, 36f);
                if (Button(rect, SettingsTabLabel(tab), buttonStyle)) settingsTab = tab;
            }

            var content = new Rect(panel.x + 35f, panel.y + 112f, panel.width - 70f, panel.height - 182f);
            if (settingsTab == SettingsTab.Graphics) DrawGraphicsSettings(content, leftStyle, buttonStyle);
            if (settingsTab == SettingsTab.Audio) DrawAudioSettings(content, leftStyle, buttonStyle);
            if (settingsTab == SettingsTab.Controls) DrawControlSettings(content, leftStyle, bodyStyle, buttonStyle);
            if (settingsTab == SettingsTab.Accessibility) DrawAccessibilitySettings(content, leftStyle, buttonStyle);
            if (settingsTab == SettingsTab.Other) DrawOtherSettings(content, leftStyle, buttonStyle);

            GUI.Label(new Rect(panel.x + 25f, panel.y + panel.height - 66f, panel.width - 50f, 24f), T("settings.persistence_note"), bodyStyle);
            if (Button(new Rect(panel.x + 40f, panel.y + panel.height - 38f, 180f, 30f), T("settings.reset_defaults"), buttonStyle))
            {
                settings.ResetToDefaults();
                ApplyPresentationSettings();
            }
            if (Button(new Rect(panel.x + panel.width - 220f, panel.y + panel.height - 38f, 180f, 30f), T("menu.back"), buttonStyle)) screen = settingsReturnScreen;
        }

        private void DrawGraphicsSettings(Rect content, GUIStyle leftStyle, GUIStyle buttonStyle)
        {
            GUI.Label(new Rect(content.x, content.y, content.width, 28f), T("settings.graphics_hint"), leftStyle);
            GUI.Label(new Rect(content.x, content.y + 46f, 230f, 30f), T("settings.quality_tier"), leftStyle);
            for (var index = 0; index < 3; index++)
            {
                if (Button(new Rect(content.x + 230f + index * 95f, content.y + 42f, 85f, 34f), (index + 1).ToString(), buttonStyle))
                {
                    settings.SetQuality(index);
                    ApplyPresentationSettings();
                }
            }
            SliderRow(content, 95f, T("settings.fov"), settings.FieldOfView, 60f, 90f, settings.SetFieldOfView);
            SliderRow(content, 145f, T("settings.brightness"), settings.Brightness, 0.65f, 1.35f, settings.SetBrightness);
            if (Button(new Rect(content.x, content.y + 202f, 220f, 36f), settings.ShowFps ? T("settings.show_fps") + ": ON" : T("settings.show_fps") + ": " + T("settings.off"), buttonStyle)) settings.SetShowFps(!settings.ShowFps);
            if (Button(new Rect(content.x + 250f, content.y + 202f, 220f, 36f), "EFFECTS: " + OnOff(settings.ScreenEffects), buttonStyle)) settings.SetScreenEffects(!settings.ScreenEffects);
        }

        private void DrawAudioSettings(Rect content, GUIStyle leftStyle, GUIStyle buttonStyle)
        {
            GUI.Label(new Rect(content.x, content.y, content.width, 28f), T("settings.audio_hint"), leftStyle);
            SliderRow(content, 48f, T("settings.master_volume"), settings.MasterVolume, 0f, 1f, settings.SetMasterVolume);
            SliderRow(content, 98f, T("settings.music_volume"), settings.MusicVolume, 0f, 1f, settings.SetMusicVolume);
            SliderRow(content, 148f, T("settings.sfx_volume"), settings.SfxVolume, 0f, 1f, settings.SetSfxVolume);
            SliderRow(content, 198f, T("settings.ui_volume"), settings.UiVolume, 0f, 1f, settings.SetUiVolume);
            if (Button(new Rect(content.x, content.y + 254f, 330f, 36f), T("settings.mute_unfocused") + ": " + OnOff(settings.MuteWhenUnfocused), buttonStyle)) settings.SetMuteWhenUnfocused(!settings.MuteWhenUnfocused);
        }

        private void DrawControlSettings(Rect content, GUIStyle leftStyle, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            GUI.Label(new Rect(content.x, content.y, content.width, 28f), T("settings.controls_hint"), leftStyle);
            SliderRow(content, 42f, T("settings.look_sensitivity"), settings.LookSensitivity, 0.55f, 1.65f, settings.SetLookSensitivity);
            if (Button(new Rect(content.x, content.y + 97f, 250f, 34f), T("settings.aim_assist") + ": " + OnOff(settings.AimAssist), buttonStyle)) settings.SetAimAssist(!settings.AimAssist);
            if (Button(new Rect(content.x + 270f, content.y + 97f, 250f, 34f), T("settings.fire_mode") + ": " + (settings.AutoFire ? T("settings.auto_fire") : T("settings.single")), buttonStyle)) settings.SetAutoFire(!settings.AutoFire);
            SliderRow(content, 137f, T("settings.joystick_scale"), settings.JoystickScale, 0.75f, 1.35f, settings.SetJoystickScale);
            SliderRow(content, 177f, T("settings.button_scale"), settings.ButtonScale, 0.75f, 1.35f, settings.SetButtonScale);
            SliderRow(content, 217f, T("settings.touch_opacity"), settings.TouchOpacity, 0.35f, 1f, settings.SetTouchOpacity);
            SliderRow(content, 257f, T("settings.gamepad_deadzone"), settings.GamepadDeadzone, 0.05f, 0.85f, settings.SetGamepadDeadzone);
            if (Button(new Rect(content.x, content.y + 302f, 280f, 30f), T("settings.left_handed") + ": " + OnOff(settings.LeftHanded), buttonStyle)) settings.SetLeftHanded(!settings.LeftHanded);
            GUI.Label(new Rect(content.x, content.y + 338f, content.width, 22f), T("settings.key_bindings"), leftStyle);
            var rebindActions = new[] { UnityControls.Action.Fire, UnityControls.Action.Aim, UnityControls.Action.Jump, UnityControls.Action.Crouch, UnityControls.Action.SwapWeapon, UnityControls.Action.Reload };
            rebindSelection = Mathf.Clamp(rebindSelection, 0, rebindActions.Length - 1);
            var selectedAction = rebindActions[rebindSelection];
            if (Button(new Rect(content.x, content.y + 365f, 350f, 28f), T(UnityControls.Label(selectedAction)) + ": " + controls.GetKey(selectedAction), buttonStyle)) rebindCapture = selectedAction;
            if (Button(new Rect(content.x + 365f, content.y + 365f, 80f, 28f), "<", buttonStyle)) rebindSelection = (rebindSelection + rebindActions.Length - 1) % rebindActions.Length;
            if (Button(new Rect(content.x + 455f, content.y + 365f, 80f, 28f), ">", buttonStyle)) rebindSelection = (rebindSelection + 1) % rebindActions.Length;
            if (rebindCapture.HasValue)
            {
                GUI.Label(new Rect(content.x, content.y + 397f, 290f, 20f), T("settings.press_key"), bodyStyle);
            }
            if (Button(new Rect(content.x + 350f, content.y + 397f, 200f, 24f), T("settings.reset_bindings"), buttonStyle)) controls.ResetDefaults();
        }

        private void DrawAccessibilitySettings(Rect content, GUIStyle leftStyle, GUIStyle buttonStyle)
        {
            GUI.Label(new Rect(content.x, content.y, content.width, 28f), T("settings.accessibility_hint"), leftStyle);
            if (Button(new Rect(content.x, content.y + 45f, 260f, 36f), T("settings.subtitles") + ": " + OnOff(settings.Subtitles), buttonStyle)) settings.SetSubtitles(!settings.Subtitles);
            if (Button(new Rect(content.x + 280f, content.y + 45f, 260f, 36f), T("settings.damage_numbers") + ": " + OnOff(settings.DamageNumbers), buttonStyle)) settings.SetDamageNumbers(!settings.DamageNumbers);
            if (Button(new Rect(content.x, content.y + 98f, 260f, 36f), T("settings.reduce_shake") + ": " + OnOff(settings.ReducedMotion), buttonStyle)) settings.SetReducedMotion(!settings.ReducedMotion);
            if (Button(new Rect(content.x + 280f, content.y + 98f, 260f, 36f), T("settings.colorblind") + ": " + OnOff(settings.ColorblindMode), buttonStyle)) settings.SetColorblindMode(!settings.ColorblindMode);
            if (Button(new Rect(content.x, content.y + 151f, 260f, 36f), T("settings.haptics") + ": " + OnOff(settings.Haptics), buttonStyle)) settings.SetHaptics(!settings.Haptics);
        }

        private void DrawOtherSettings(Rect content, GUIStyle leftStyle, GUIStyle buttonStyle)
        {
            GUI.Label(new Rect(content.x, content.y, content.width, 28f), T("settings.other_hint"), leftStyle);
            if (Button(new Rect(content.x, content.y + 45f, 260f, 38f), T("settings.language") + ": " + (settings.Language == SupportedLanguage.English ? "English" : "বাংলা"), buttonStyle)) settings.ToggleLanguage();
            if (Button(new Rect(content.x + 280f, content.y + 45f, 260f, 38f), T("settings.fps_limit") + ": " + (settings.FpsLimit <= 0 ? T("settings.unlimited") : settings.FpsLimit.ToString()), buttonStyle))
            {
                settings.SetFpsLimit(settings.FpsLimit == 30 ? 60 : settings.FpsLimit == 60 ? 120 : 30);
            }
        }

        private void DrawPause(GUIStyle titleStyle, GUIStyle buttonStyle)
        {
            DrawPanel(new Rect(Screen.width * 0.5f - 220f, Screen.height * 0.5f - 165f, 440f, 350f));
            GUI.Label(new Rect(0, Screen.height * 0.30f, Screen.width, 50f), T("pause.title"), titleStyle);
            if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.44f, 300f, 46f), T("pause.resume"), buttonStyle)) ResumeOperation();
            if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.51f, 300f, 46f), T("pause.restart_operation"), buttonStyle)) BeginOperation();
            if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.58f, 300f, 46f), T("pause.map_select"), buttonStyle)) { ClearWorld(); screen = GameScreen.MapSelect; }
            if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.65f, 300f, 46f), T("menu.settings"), buttonStyle))
            {
                settingsReturnScreen = GameScreen.Paused;
                screen = GameScreen.Settings;
            }
        }

        private void DrawResults(GUIStyle titleStyle, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            DrawPanel(new Rect(Screen.width * 0.5f - 250f, Screen.height * 0.5f - 175f, 500f, 360f));
            var result = operationComplete ? T("result.mission_complete") : T("result.mission_failed");
            GUI.Label(new Rect(0, Screen.height * 0.28f, Screen.width, 56f), result, titleStyle);
            var accuracy = shotsFired == 0 ? 0 : Mathf.RoundToInt(100f * shotsHit / shotsFired);
            var record = progress.GetRecord(DesertMapId);
            GUI.Label(new Rect(0, Screen.height * 0.40f, Screen.width, 105f),
                T("result.final_score").Replace("%05d", score.ToString("D5")) + "\n" +
                T("result.wave").Replace("%d", wave.ToString()) + "\n" +
                T("result.accuracy").Replace("%d", accuracy.ToString()) + "\n" +
                T("result.best_score").Replace("%05d", record.BestScore.ToString("D5")), bodyStyle);
            if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.60f, 300f, 46f), T("result.restart_operation"), buttonStyle)) BeginOperation();
            if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.67f, 300f, 46f), T("pause.map_select"), buttonStyle)) { ClearWorld(); screen = GameScreen.MapSelect; }
        }

        private void DrawGameplayHud(GUIStyle leftStyle, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            var hudColor = settings.ColorblindMode ? new Color(1f, 0.92f, 0.35f) : Color.white;
            GUI.color = new Color(0.02f, 0.08f, 0.1f, 0.88f);
            GUI.DrawTexture(new Rect(14f, 14f, 270f, 158f), Texture2D.whiteTexture);
            GUI.color = hudColor;
            var limit = selectedMode == OperationMode.Endless ? "∞" : WaveSizes.Length.ToString();
            GUI.Label(new Rect(28f, 26f, 250f, 27f), T("map.waves") + "  " + Mathf.Max(wave, 1) + " / " + limit, leftStyle);
            GUI.Label(new Rect(28f, 54f, 250f, 27f), "SCORE  " + score.ToString("D5"), leftStyle);
            GUI.Label(new Rect(28f, 82f, 250f, 27f), "HP  " + Mathf.CeilToInt(health), leftStyle);
            if (activeWeapon != null)
            {
                GUI.Label(new Rect(28f, 110f, 250f, 27f), (activeWeapon.Kind == WeaponKind.Carbine ? "CARBINE" : "SIDEARM") + "  " + activeWeapon.Ammo + " / " + activeWeapon.Reserve, leftStyle);
                var contactText = "CONTACTS " + raiders.Count + (pendingSpawns > 0 ? "  +" + pendingSpawns : string.Empty);
                GUI.Label(new Rect(28f, 137f, 250f, 24f), activeWeapon.IsReloading ? T("caption.reloading") : contactText, leftStyle);
            }
            GUI.color = Color.white;
            GUI.Label(new Rect(Screen.width * 0.5f - 8f, Screen.height * 0.5f - 18f, 16f, 36f), "+", Style(28, hudColor, TextAnchor.MiddleCenter, true));
            if (settings.ShowFps) GUI.Label(new Rect(Screen.width - 115f, 66f, 100f, 24f), Mathf.RoundToInt(fpsSample) + " FPS", leftStyle);
            if (settings.Subtitles && Time.unscaledTime < soundCaptionUntil) GUI.Label(new Rect(0f, Screen.height - 72f, Screen.width, 26f), "♪  " + soundCaption, bodyStyle);
            DrawDamageNumbers();

            var mobileLayout = ResolveMobileActionLayout();
            if (hudEditMode)
            {
                DrawHudEditor(mobileLayout.Radar, mobileLayout.Fire, mobileLayout.Pause, bodyStyle, buttonStyle);
                return;
            }

            if (tacticalRadar != null) tacticalRadar.Draw(mobileLayout.Radar, playerRoot, raiders, settings.ColorblindMode);
            if (Application.isMobilePlatform)
            {
                DrawMobileTouchControls(mobileLayout, bodyStyle, buttonStyle);
                return;
            }

            GUI.color = new Color(1f, 1f, 1f, settings.TouchOpacity);
            if (GUI.RepeatButton(mobileLayout.Fire, T("bindings.fire"), buttonStyle)) FireActiveWeapon();
            GUI.color = Color.white;
            if (Button(mobileLayout.Pause, T("bindings.pause"), buttonStyle)) PauseOperation();
            if (Button(new Rect(292f, 18f, 88f, 36f), "HUD", buttonStyle)) hudEditMode = true;
        }

        private void DrawMobileTouchControls(MobileActionLayout layout, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            DrawMobileMovementPad(bodyStyle);
            DrawMobileAction(layout.Fire, T("bindings.fire"), mobileFireHeld, buttonStyle);
            DrawMobileAction(layout.Aim, T("bindings.aim"), mobileAimHeld, buttonStyle);
            DrawMobileAction(layout.Reload, T("bindings.reload"), false, buttonStyle);
            DrawMobileAction(layout.Swap, T("bindings.swap"), false, buttonStyle);
            DrawMobileAction(layout.Jump, T("bindings.jump"), false, buttonStyle);
            DrawMobileAction(layout.Crouch, T("bindings.crouch"), playerController != null && playerController.IsCrouching, buttonStyle);
            DrawMobileAction(layout.Pause, T("bindings.pause"), false, buttonStyle);
        }

        private void DrawMobileMovementPad(GUIStyle bodyStyle)
        {
            if (mobileControlDisc == null)
            {
                return;
            }
            var radius = 54f * settings.JoystickScale;
            var defaultCenter = new Vector2(settings.LeftHanded ? Screen.width - radius - 24f : radius + 24f, Screen.height - radius - 24f);
            var center = defaultCenter;
            if (playerController != null && playerController.HasMoveTouch)
            {
                center = new Vector2(playerController.MoveTouchOrigin.x, Screen.height - playerController.MoveTouchOrigin.y);
            }
            center.x = Mathf.Clamp(center.x, radius + 8f, Screen.width - radius - 8f);
            center.y = Mathf.Clamp(center.y, radius + 8f, Screen.height - radius - 8f);
            GUI.color = new Color(0.08f, 0.23f, 0.28f, settings.TouchOpacity * 0.78f);
            GUI.DrawTexture(new Rect(center.x - radius, center.y - radius, radius * 2f, radius * 2f), mobileControlDisc);
            var knob = playerController == null ? Vector2.zero : playerController.TouchMove * radius * 0.52f;
            GUI.color = new Color(0.7f, 0.96f, 1f, settings.TouchOpacity);
            GUI.DrawTexture(new Rect(center.x + knob.x - radius * 0.34f, center.y - knob.y - radius * 0.34f, radius * 0.68f, radius * 0.68f), mobileControlDisc);
            GUI.color = new Color(1f, 1f, 1f, settings.TouchOpacity);
            GUI.Label(new Rect(center.x - radius, center.y - 11f, radius * 2f, 22f), "MOVE", bodyStyle);
            GUI.color = Color.white;
        }

        private void DrawMobileAction(Rect rect, string label, bool active, GUIStyle buttonStyle)
        {
            GUI.color = active ? new Color(0.16f, 0.62f, 0.66f, settings.TouchOpacity) : new Color(0.035f, 0.16f, 0.2f, settings.TouchOpacity);
            GUI.DrawTexture(rect, Texture2D.whiteTexture);
            GUI.color = new Color(1f, 1f, 1f, settings.TouchOpacity);
            GUI.Label(rect, label, buttonStyle);
            GUI.color = Color.white;
        }

        private void DrawHudEditor(Rect radarRect, Rect fireRect, Rect pauseRect, GUIStyle bodyStyle, GUIStyle buttonStyle)
        {
            GUI.color = new Color(0f, 0f, 0f, 0.55f);
            GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), Texture2D.whiteTexture);
            GUI.color = Color.white;
            GUI.Label(new Rect(0f, 20f, Screen.width, 34f), T("settings.hud_layout_note"), bodyStyle);
            DrawHudEditTarget(UnityHudLayout.Element.Radar, radarRect, "RADAR", buttonStyle);
            DrawHudEditTarget(UnityHudLayout.Element.Fire, fireRect, T("bindings.fire"), buttonStyle);
            DrawHudEditTarget(UnityHudLayout.Element.Pause, pauseRect, T("pause.title"), buttonStyle);
            if (Button(new Rect(Screen.width * 0.5f - 185f, Screen.height - 70f, 175f, 42f), "RESET HUD", buttonStyle)) hudLayout.Reset();
            if (Button(new Rect(Screen.width * 0.5f + 10f, Screen.height - 70f, 175f, 42f), "DONE", buttonStyle))
            {
                hudEditMode = false;
                hudDragElement = null;
            }
        }

        private void DrawHudEditTarget(UnityHudLayout.Element element, Rect rect, string label, GUIStyle buttonStyle)
        {
            var current = Event.current;
            if (current.type == EventType.MouseDown && rect.Contains(current.mousePosition))
            {
                hudDragElement = element;
                hudDragOffset = current.mousePosition - rect.position;
                current.Use();
            }
            else if (current.type == EventType.MouseDrag && hudDragElement.HasValue && hudDragElement.Value == element)
            {
                var moved = new Rect(current.mousePosition - hudDragOffset, rect.size);
                hudLayout.Store(element, moved, new Vector2(Screen.width, Screen.height));
                current.Use();
            }
            else if (current.type == EventType.MouseUp && hudDragElement.HasValue && hudDragElement.Value == element)
            {
                hudDragElement = null;
                current.Use();
            }

            GUI.color = new Color(0.18f, 0.52f, 0.62f, 0.9f);
            GUI.Box(rect, label, buttonStyle);
            GUI.color = Color.white;
        }

        private void DrawDamageNumbers()
        {
            if (!settings.DamageNumbers || playerController == null || playerController.PlayerCamera == null)
            {
                return;
            }
            for (var index = damagePopups.Count - 1; index >= 0; index--)
            {
                var popup = damagePopups[index];
                if (Time.unscaledTime >= popup.ExpiresAt)
                {
                    damagePopups.RemoveAt(index);
                    continue;
                }
                var viewport = playerController.PlayerCamera.WorldToScreenPoint(popup.WorldPosition);
                if (viewport.z <= 0f)
                {
                    continue;
                }
                var age = 1f - (popup.ExpiresAt - Time.unscaledTime) / 0.72f;
                var rise = settings.ReducedMotion ? 8f : 28f;
                var rect = new Rect(viewport.x - 24f, Screen.height - viewport.y - rise * age, 48f, 24f);
                GUI.Label(rect, popup.Text, Style(18, popup.Color, TextAnchor.MiddleCenter, true));
            }
        }

        private void SliderRow(Rect content, float y, string label, float value, float minimum, float maximum, System.Action<float> setter)
        {
            GUI.Label(new Rect(content.x, content.y + y, 230f, 30f), label, Style(16, Color.white, TextAnchor.UpperLeft, false));
            var changed = GUI.HorizontalSlider(new Rect(content.x + 240f, content.y + y + 8f, 250f, 22f), value, minimum, maximum);
            if (Mathf.Abs(changed - value) > 0.001f)
            {
                setter(changed);
                ApplyPresentationSettings();
            }
            GUI.Label(new Rect(content.x + 505f, content.y + y, 60f, 30f), changed.ToString("0.00"), Style(15, Color.white, TextAnchor.UpperLeft, false));
        }

        private void ProcessRebindCapture()
        {
            if (!rebindCapture.HasValue || Event.current.type != EventType.KeyDown)
            {
                return;
            }
            var captured = Event.current.keyCode;
            var action = rebindCapture.Value;
            if (!UnityControls.IsReserved(captured) && !controls.HasConflict(action, captured))
            {
                controls.SetKey(action, captured);
            }
            rebindCapture = null;
            Event.current.Use();
        }

        private void CycleDifficulty()
        {
            selectedDifficulty = (Difficulty)(((int)selectedDifficulty + 1) % 4);
            PlayUiEffect();
        }

        private void CycleMode()
        {
            selectedMode = selectedMode == OperationMode.Survival ? OperationMode.Endless : OperationMode.Survival;
            PlayUiEffect();
        }

        private string DifficultyLabel()
        {
            switch (selectedDifficulty)
            {
                case Difficulty.Easy: return T("game.easy");
                case Difficulty.Hard: return T("game.hard");
                case Difficulty.Nightmare: return T("game.nightmare");
                default: return T("game.normal");
            }
        }

        private string ModeLabel()
        {
            return selectedMode == OperationMode.Endless ? T("game.endless") : T("game.survival");
        }

        private string SettingsTabLabel(SettingsTab tab)
        {
            switch (tab)
            {
                case SettingsTab.Graphics: return T("settings.graphics");
                case SettingsTab.Audio: return T("settings.audio");
                case SettingsTab.Controls: return T("settings.controls");
                case SettingsTab.Accessibility: return T("settings.accessibility");
                default: return T("settings.other");
            }
        }

        private string OnOff(bool value)
        {
            return value ? "ON" : T("settings.off");
        }

        private string T(string key)
        {
            return LocalizedCatalog.Get(key, settings.Language);
        }

        private void DrawMenuBackdrop()
        {
            GUI.color = Color.white;
            if (menuBackdrop != null)
            {
                GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), menuBackdrop, ScaleMode.ScaleAndCrop);
            }
            else
            {
                GUI.color = new Color(0.22f, 0.17f, 0.12f);
                GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), Texture2D.whiteTexture);
            }
            GUI.color = new Color(0.02f, 0.04f, 0.07f, 0.63f);
            GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), Texture2D.whiteTexture);
            GUI.color = Color.white;
        }

        private static void DrawPanel(Rect rect)
        {
            GUI.color = new Color(0.035f, 0.075f, 0.09f, 0.9f);
            GUI.DrawTexture(rect, Texture2D.whiteTexture);
            GUI.color = Color.white;
        }

        private bool Button(Rect rect, string label, GUIStyle style)
        {
            GUI.color = new Color(0.12f, 0.29f, 0.34f, 0.96f);
            var clicked = GUI.Button(rect, label, style);
            GUI.color = Color.white;
            if (clicked)
            {
                PlayUiEffect();
            }
            return clicked;
        }

        private GUIStyle Style(int size, Color color, TextAnchor alignment, bool bold)
        {
            var style = new GUIStyle(GUI.skin.label)
            {
                fontSize = size,
                fontStyle = bold ? FontStyle.Bold : FontStyle.Normal,
                alignment = alignment,
                normal = { textColor = color },
                wordWrap = true,
            };
            if (bengaliFont != null)
            {
                style.font = bengaliFont;
            }
            return style;
        }

        private void OnDestroy()
        {
            AudioListener.pause = false;
            ClearWorld();
            if (mobileControlDisc != null)
            {
                Destroy(mobileControlDisc);
            }
        }
    }
}
