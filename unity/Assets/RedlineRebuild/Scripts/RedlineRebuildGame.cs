using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Events;
using UnityEngine.UI;

namespace OperationRedline.Rebuild
{
    /// <summary>
    /// Clean, code-owned Unity vertical slice for Android review. It is a new
    /// runtime: UGUI owns touch routing; one state machine owns simulation;
    /// every active gameplay clock is unscaled; and the old migration runtime is
    /// deliberately not instantiated.
    /// </summary>
    public sealed class RedlineRebuildGame : MonoBehaviour
    {
        private enum AppState
        {
            Home,
            Loading,
            Playing,
            Paused,
            Results,
        }

        private const int TotalWaves = 3;
        private const float PlayerWalkSpeed = 5.4f;
        private const float PlayerGravity = 22f;
        private const float FireInterval = 0.18f;
        private const float EnemySpawnCadence = 0.85f;

        private readonly List<RedlineRebuildEnemy> enemies = new List<RedlineRebuildEnemy>();
        private readonly List<Material> worldMaterials = new List<Material>();

        private AppState state;
        private Canvas canvas;
        private Font uiFont;
        private GameObject page;
        private GameObject pauseOverlay;
        private GameObject worldRoot;
        private GameObject playerRoot;
        private CharacterController playerController;
        private Camera playerCamera;
        private Transform cameraPivot;
        private Text statusLabel;
        private Text healthLabel;
        private Text waveLabel;
        private Text ammoLabel;
        private Text loadingLabel;
        private Coroutine operationStartRoutine;

        private Vector2 uiMove;
        private Vector2 queuedLook;
        private bool uiFireHeld;
        private float yaw;
        private float pitch;
        private float verticalVelocity;
        private float fireCooldown;
        private float elapsed;
        private float spawnTimer;
        private float intermissionTimer;
        private int wave;
        private int pendingSpawns;
        private int spawnSequence;
        private int enemiesDefeated;
        private int shotsFired;
        private int shotsHit;
        private int health;
        private int ammo;
        private int reserveAmmo;
        private bool reloadInProgress;
        private float reloadTimer;
        private bool resultSuccess;

        private Shader mobileShader;
        private Texture2D groundTexture;
        private Texture2D concreteTexture;
        private Texture2D metalTexture;
        private Texture2D crateTexture;

        private void Awake()
        {
            Time.timeScale = 1f;
            Application.targetFrameRate = 60;
            QualitySettings.vSyncCount = 0;
            mobileShader = Resources.Load<Shader>("Shaders/OperationRedlineMobile");
            groundTexture = Resources.Load<Texture2D>("Textures/desert_outpost_ground");
            concreteTexture = Resources.Load<Texture2D>("Textures/outpost_concrete");
            metalTexture = Resources.Load<Texture2D>("Textures/outpost_corrugated_metal");
            crateTexture = Resources.Load<Texture2D>("Textures/outpost_weathered_crate");
            uiFont = Resources.Load<Font>("Fonts/NotoSansBengali-Regular");
            if (uiFont == null)
            {
                uiFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            }
            EnsureEventSystem();
            BuildCanvas();
            ShowHome();
        }

        private void Update()
        {
            if (state == AppState.Home)
            {
                ReadHomePointerFallback();
                return;
            }
            if (state != AppState.Playing)
            {
                return;
            }

            var deltaTime = Mathf.Min(0.05f, Time.unscaledDeltaTime);
            elapsed += deltaTime;
            ReadDesktopInput();
            TickPlayer(deltaTime);
            TickCombat(deltaTime);
            TickEnemies(deltaTime);
            TickWaves(deltaTime);
            RefreshHud();
        }

        private void OnApplicationPause(bool paused)
        {
            if (paused && state == AppState.Playing)
            {
                PauseOperation();
            }
        }

        private void OnApplicationFocus(bool focused)
        {
            if (!focused && state == AppState.Playing)
            {
                PauseOperation();
            }
        }

        private void EnsureEventSystem()
        {
            if (FindObjectOfType<EventSystem>() != null)
            {
                return;
            }
            var eventSystem = new GameObject("Redline Rebuild EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
            DontDestroyOnLoad(eventSystem);
        }

        private void BuildCanvas()
        {
            var root = new GameObject("Redline Rebuild UI", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            DontDestroyOnLoad(root);
            canvas = root.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 100;
            var scaler = root.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.55f;
        }

        private void ShowHome()
        {
            state = AppState.Home;
            Time.timeScale = 1f;
            ClearPage();
            ClearWorld();
            page = CreatePanel("Home", canvas.transform, Vector2.zero, Vector2.one, new Color(0.025f, 0.055f, 0.075f, 1f));
            CreateText(page.transform, "OPERATION REDLINE", 62, Color.white, TextAnchor.MiddleCenter, new Vector2(0.12f, 0.70f), new Vector2(0.88f, 0.84f));
            CreateText(page.transform, "ডেজার্ট আউটপোস্ট  |  DESERT OUTPOST", 28, new Color(0.55f, 0.92f, 0.84f), TextAnchor.MiddleCenter, new Vector2(0.14f, 0.62f), new Vector2(0.86f, 0.68f));
            CreateText(page.transform, "Fresh Unity rebuild — direct mobile controls, live waves, and pause-safe simulation.", 23, new Color(0.78f, 0.86f, 0.88f), TextAnchor.MiddleCenter, new Vector2(0.16f, 0.50f), new Vector2(0.84f, 0.58f));
            CreateTouchSurface(page.transform, "Start Operation", "START OPERATION\nঅপারেশন শুরু", RedlineRebuildTouchSurface.Role.StartOperation, new Vector2(0.32f, 0.30f), new Vector2(0.68f, 0.43f), new Color(0.12f, 0.55f, 0.42f, 1f));
            CreateText(page.transform, "Temporary authored materials are in use. Player-provided final assets will replace them without changing gameplay code.", 17, new Color(0.62f, 0.7f, 0.72f), TextAnchor.MiddleCenter, new Vector2(0.12f, 0.13f), new Vector2(0.88f, 0.21f));
        }

        private void BeginOperation()
        {
            if ((state != AppState.Home && state != AppState.Results) || operationStartRoutine != null)
            {
                return;
            }
            operationStartRoutine = StartCoroutine(BeginOperationRoutine());
        }

        private System.Collections.IEnumerator BeginOperationRoutine()
        {
            state = AppState.Loading;
            Time.timeScale = 1f;
            ClearPage();
            ClearWorld();
            page = CreatePanel("Operation Loading", canvas.transform, Vector2.zero, Vector2.one, new Color(0.025f, 0.055f, 0.075f, 1f));
            loadingLabel = CreateText(page.transform, "DEPLOYING DESERT OUTPOST\nলোড হচ্ছে...", 34, Color.white, TextAnchor.MiddleCenter, new Vector2(0.18f, 0.46f), new Vector2(0.82f, 0.62f));
            yield return null;

            try
            {
                ResetOperationState();
                loadingLabel.text = "BUILDING SAFE WORLD\nবিশ্ব তৈরি হচ্ছে...";
                CreateWorld();
                yield return null;
                loadingLabel.text = "INITIALIZING TOUCH CONTROLS\nকন্ট্রোল প্রস্তুত হচ্ছে...";
                BuildGameplayUi();
                yield return null;
                state = AppState.Playing;
                SetStatus("UI READY · WAVE 1 STARTING");
            }
            catch (System.Exception exception)
            {
                Debug.LogException(exception);
                ShowStartupFailure(exception.Message);
            }
            finally
            {
                operationStartRoutine = null;
            }
        }

        private void ResetOperationState()
        {
            elapsed = 0f;
            wave = 1;
            pendingSpawns = WaveSize(wave);
            spawnSequence = 0;
            spawnTimer = 0f;
            intermissionTimer = 0f;
            enemiesDefeated = 0;
            shotsFired = 0;
            shotsHit = 0;
            health = 100;
            ammo = 30;
            reserveAmmo = 120;
            reloadInProgress = false;
            reloadTimer = 0f;
            fireCooldown = 0f;
            verticalVelocity = 0f;
            uiMove = Vector2.zero;
            queuedLook = Vector2.zero;
            uiFireHeld = false;
            yaw = 0f;
            pitch = 0f;
        }

        private void CreateWorld()
        {
            worldRoot = new GameObject("Redline Rebuild World");
            CreatePlayer();

            var ground = CreatePrimitive("Desert Ground", PrimitiveType.Plane, Vector3.zero, new Vector3(12f, 1f, 12f), GroundMaterial());
            ground.transform.SetParent(worldRoot.transform, true);

            var concrete = CreateMaterial(new Color(0.56f, 0.47f, 0.37f, 1f), RedlineRebuildAssetResolver.TextureOrFallback("outpost_concrete", concreteTexture));
            var metal = CreateMaterial(new Color(0.29f, 0.32f, 0.30f, 1f), RedlineRebuildAssetResolver.TextureOrFallback("outpost_metal", metalTexture));
            var crate = CreateMaterial(new Color(0.52f, 0.30f, 0.13f, 1f), RedlineRebuildAssetResolver.TextureOrFallback("outpost_crate", crateTexture));
            CreateWorldProp("outpost_left", "Outpost Left", PrimitiveType.Cube, new Vector3(-11f, 2.8f, 13f), new Vector3(5.2f, 5.6f, 7f), concrete);
            CreateWorldProp("outpost_right", "Outpost Right", PrimitiveType.Cube, new Vector3(11f, 2.5f, 16f), new Vector3(5f, 5f, 6f), concrete);
            CreateWorldProp("outpost_gate", "Gate", PrimitiveType.Cube, new Vector3(0f, 3f, 34f), new Vector3(15f, 6f, 0.75f), metal);
            CreateWorldProp("watch_tower", "Tower", PrimitiveType.Cube, new Vector3(-17f, 5.5f, 27f), new Vector3(3.2f, 11f, 3.2f), metal);
            CreateWorldProp("crate_stack_a", "Crate Stack A", PrimitiveType.Cube, new Vector3(-4.5f, 1f, 8f), new Vector3(2f, 2f, 2f), crate);
            CreateWorldProp("crate_stack_b", "Crate Stack B", PrimitiveType.Cube, new Vector3(4.5f, 1f, 10f), new Vector3(2f, 2f, 2f), crate);
            CreateWorldProp("sandbag_cover", "Sandbag Cover", PrimitiveType.Cube, new Vector3(7f, 0.65f, 4f), new Vector3(5f, 1.3f, 1.2f), GroundMaterial(new Color(0.58f, 0.47f, 0.27f, 1f)));

            var lightRoot = new GameObject("Desert Sun");
            lightRoot.transform.SetParent(worldRoot.transform, false);
            lightRoot.transform.rotation = Quaternion.Euler(48f, -32f, 0f);
            var sun = lightRoot.AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.intensity = 0.6f;
            sun.color = new Color(1f, 0.82f, 0.6f, 1f);
            RenderSettings.ambientLight = new Color(0.48f, 0.38f, 0.27f, 1f);
        }

        private void CreatePlayer()
        {
            playerRoot = new GameObject("Redline Player");
            playerRoot.transform.position = new Vector3(0f, 1.05f, -12f);
            playerController = playerRoot.AddComponent<CharacterController>();
            playerController.height = 1.8f;
            playerController.radius = 0.35f;
            playerController.center = new Vector3(0f, 0.9f, 0f);
            playerController.stepOffset = 0.3f;
            playerController.slopeLimit = 45f;
            cameraPivot = new GameObject("Camera Pivot").transform;
            cameraPivot.SetParent(playerRoot.transform, false);
            cameraPivot.localPosition = new Vector3(0f, 0.48f, 0f);
            playerCamera = new GameObject("Player Camera").AddComponent<Camera>();
            playerCamera.tag = "MainCamera";
            playerCamera.transform.SetParent(cameraPivot, false);
            playerCamera.transform.localPosition = Vector3.zero;
            playerCamera.clearFlags = CameraClearFlags.SolidColor;
            playerCamera.backgroundColor = new Color(0.35f, 0.57f, 0.66f, 1f);
            playerCamera.fieldOfView = 70f;
            playerCamera.nearClipPlane = 0.1f;
            playerCamera.gameObject.AddComponent<AudioListener>();
        }

        private void BuildGameplayUi()
        {
            ClearPage();
            page = CreatePanel("Gameplay UI", canvas.transform, Vector2.zero, Vector2.one, new Color(0f, 0f, 0f, 0f));
            waveLabel = CreateText(page.transform, "WAVE 1 / 3", 30, Color.white, TextAnchor.UpperLeft, new Vector2(0.025f, 0.90f), new Vector2(0.38f, 0.97f));
            healthLabel = CreateText(page.transform, "HP 100", 30, new Color(0.54f, 1f, 0.7f), TextAnchor.UpperLeft, new Vector2(0.025f, 0.84f), new Vector2(0.38f, 0.91f));
            ammoLabel = CreateText(page.transform, "30 / 120", 30, Color.white, TextAnchor.UpperRight, new Vector2(0.62f, 0.84f), new Vector2(0.975f, 0.91f));
            statusLabel = CreateText(page.transform, "UI READY", 20, new Color(0.75f, 0.94f, 0.91f), TextAnchor.UpperLeft, new Vector2(0.025f, 0.79f), new Vector2(0.72f, 0.85f));
            CreateTouchSurface(page.transform, "Pause Surface", "PAUSE", RedlineRebuildTouchSurface.Role.Pause, new Vector2(0.84f, 0.91f), new Vector2(0.975f, 0.98f), new Color(0.20f, 0.30f, 0.36f, 0.95f));

            var look = CreateTouchSurface(page.transform, "Look Surface", string.Empty, RedlineRebuildTouchSurface.Role.Look, new Vector2(0.44f, 0.04f), new Vector2(0.98f, 0.82f), new Color(0f, 0f, 0f, 0.012f));
            look.GetComponent<Image>().raycastTarget = true;
            CreateTouchSurface(page.transform, "Move Surface", "MOVE", RedlineRebuildTouchSurface.Role.Move, new Vector2(0.02f, 0.04f), new Vector2(0.39f, 0.35f), new Color(0.08f, 0.36f, 0.36f, 0.55f));
            CreateTouchSurface(page.transform, "Fire Surface", "FIRE", RedlineRebuildTouchSurface.Role.Fire, new Vector2(0.76f, 0.08f), new Vector2(0.97f, 0.24f), new Color(0.67f, 0.18f, 0.12f, 0.9f));
            CreateTouchSurface(page.transform, "Reload Surface", "RELOAD", RedlineRebuildTouchSurface.Role.Reload, new Vector2(0.76f, 0.27f), new Vector2(0.97f, 0.36f), new Color(0.26f, 0.38f, 0.44f, 0.92f));
            CreateText(page.transform, "+", 45, Color.white, TextAnchor.MiddleCenter, new Vector2(0.485f, 0.46f), new Vector2(0.515f, 0.54f)).raycastTarget = false;
        }

        private void ReadHomePointerFallback()
        {
            // Direct EventSystem pointer ownership is the primary route. This
            // narrow legacy pointer fallback covers Android devices that expose
            // their first touch only as a primary mouse press.
            if (!Input.GetMouseButtonDown(0) || operationStartRoutine != null)
            {
                return;
            }
            var point = (Vector2)Input.mousePosition;
            var startArea = new Rect(Screen.width * 0.32f, Screen.height * 0.30f, Screen.width * 0.36f, Screen.height * 0.13f);
            if (startArea.Contains(point))
            {
                BeginOperation();
            }
        }

        private void ShowStartupFailure(string detail)
        {
            state = AppState.Home;
            ClearPage();
            ClearWorld();
            page = CreatePanel("Startup Failure", canvas.transform, Vector2.zero, Vector2.one, new Color(0.14f, 0.03f, 0.03f, 1f));
            CreateText(page.transform, "OPERATION START FAILED\nশুরু করা যায়নি", 38, new Color(1f, 0.7f, 0.65f), TextAnchor.MiddleCenter, new Vector2(0.15f, 0.58f), new Vector2(0.85f, 0.76f));
            CreateText(page.transform, "The game returned safely instead of silently freezing.\nDiagnostic: " + detail, 19, Color.white, TextAnchor.MiddleCenter, new Vector2(0.14f, 0.40f), new Vector2(0.86f, 0.55f));
            CreateTouchSurface(page.transform, "Retry Operation", "RETRY START", RedlineRebuildTouchSurface.Role.StartOperation, new Vector2(0.33f, 0.20f), new Vector2(0.67f, 0.31f), new Color(0.12f, 0.55f, 0.42f, 1f));
        }

        private void ReadDesktopInput()
        {
            if (Application.isMobilePlatform)
            {
                return;
            }
            var keyboardMove = Vector2.zero;
            if (Input.GetKey(KeyCode.A)) keyboardMove.x -= 1f;
            if (Input.GetKey(KeyCode.D)) keyboardMove.x += 1f;
            if (Input.GetKey(KeyCode.S)) keyboardMove.y -= 1f;
            if (Input.GetKey(KeyCode.W)) keyboardMove.y += 1f;
            if (keyboardMove.sqrMagnitude > 0.01f)
            {
                uiMove = keyboardMove.normalized;
            }
            else if (!Input.GetMouseButton(0))
            {
                uiMove = Vector2.zero;
            }
            if (Input.GetMouseButton(1))
            {
                AddUiLook(new Vector2(Input.GetAxis("Mouse X"), Input.GetAxis("Mouse Y")) * 12f);
            }
            if (Input.GetKey(KeyCode.Space))
            {
                uiFireHeld = true;
            }
            if (Input.GetKeyUp(KeyCode.Space))
            {
                uiFireHeld = false;
            }
            if (Input.GetKeyDown(KeyCode.R)) StartReload();
            if (Input.GetKeyDown(KeyCode.Escape)) PauseOperation();
        }

        private void TickPlayer(float deltaTime)
        {
            if (playerController == null || playerRoot == null)
            {
                return;
            }
            yaw += queuedLook.x * 0.13f;
            pitch = Mathf.Clamp(pitch - queuedLook.y * 0.10f, -72f, 72f);
            queuedLook = Vector2.zero;
            playerRoot.transform.rotation = Quaternion.Euler(0f, yaw, 0f);
            cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, 0f);
            if (playerController.isGrounded && verticalVelocity < 0f)
            {
                verticalVelocity = -1f;
            }
            verticalVelocity -= PlayerGravity * deltaTime;
            var move = (playerRoot.transform.right * uiMove.x + playerRoot.transform.forward * uiMove.y);
            move = Vector3.ClampMagnitude(move, 1f) * PlayerWalkSpeed;
            playerController.Move((move + Vector3.up * verticalVelocity) * deltaTime);
        }

        private void TickCombat(float deltaTime)
        {
            fireCooldown = Mathf.Max(0f, fireCooldown - deltaTime);
            if (reloadInProgress)
            {
                reloadTimer -= deltaTime;
                if (reloadTimer <= 0f)
                {
                    var required = 30 - ammo;
                    var transferred = Mathf.Min(required, reserveAmmo);
                    ammo += transferred;
                    reserveAmmo -= transferred;
                    reloadInProgress = false;
                    SetStatus("RELOAD COMPLETE");
                }
                return;
            }
            if (uiFireHeld && fireCooldown <= 0f)
            {
                FireShot();
            }
        }

        private void FireShot()
        {
            if (ammo <= 0)
            {
                StartReload();
                return;
            }
            ammo--;
            shotsFired++;
            fireCooldown = FireInterval;
            var ray = playerCamera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f));
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit, 90f, Physics.DefaultRaycastLayers, QueryTriggerInteraction.Ignore))
            {
                var enemy = hit.collider.GetComponent<RedlineRebuildEnemy>();
                if (enemy == null)
                {
                    enemy = hit.collider.GetComponentInParent<RedlineRebuildEnemy>();
                }
                if (enemy != null)
                {
                    shotsHit++;
                    enemy.ApplyDamage(34f);
                    SetStatus("CONTACT HIT");
                    return;
                }
            }
            SetStatus("SHOT FIRED");
        }

        private void StartReload()
        {
            if (reloadInProgress || ammo >= 30 || reserveAmmo <= 0 || state != AppState.Playing)
            {
                return;
            }
            reloadInProgress = true;
            reloadTimer = 1.05f;
            SetStatus("RELOADING");
        }

        private void TickEnemies(float deltaTime)
        {
            for (var index = enemies.Count - 1; index >= 0; index--)
            {
                if (enemies[index] == null)
                {
                    enemies.RemoveAt(index);
                    continue;
                }
                enemies[index].Tick(deltaTime);
            }
        }

        private void TickWaves(float deltaTime)
        {
            if (pendingSpawns > 0)
            {
                spawnTimer -= deltaTime;
                if (spawnTimer <= 0f)
                {
                    SpawnEnemy();
                    pendingSpawns--;
                    spawnTimer = EnemySpawnCadence;
                }
                return;
            }
            if (enemies.Count > 0)
            {
                return;
            }
            intermissionTimer += deltaTime;
            if (intermissionTimer < 2f)
            {
                return;
            }
            if (wave >= TotalWaves)
            {
                EndOperation(true);
                return;
            }
            wave++;
            pendingSpawns = WaveSize(wave);
            spawnTimer = 0f;
            intermissionTimer = 0f;
            SetStatus("WAVE " + wave + " INCOMING");
        }

        private int WaveSize(int index)
        {
            return index == 1 ? 4 : index == 2 ? 6 : 8;
        }

        private void SpawnEnemy()
        {
            var lane = spawnSequence % 5;
            spawnSequence++;
            var positions = new[]
            {
                new Vector3(0f, 1.3f, 15f), new Vector3(-7f, 1.3f, 20f), new Vector3(7f, 1.3f, 20f),
                new Vector3(-13f, 1.3f, 25f), new Vector3(13f, 1.3f, 25f),
            };
            var enemyObject = RedlineRebuildAssetResolver.InstantiateIfPresent("raider", worldRoot.transform, positions[lane], Quaternion.identity, new Vector3(1.05f, 1.3f, 1.05f));
            if (enemyObject == null)
            {
                enemyObject = CreatePrimitive("Raider", PrimitiveType.Capsule, positions[lane], new Vector3(1.05f, 1.3f, 1.05f), CreateMaterial(new Color(0.84f, 0.20f, 0.13f, 1f), null));
                enemyObject.transform.SetParent(worldRoot.transform, true);
            }
            var enemy = enemyObject.AddComponent<RedlineRebuildEnemy>();
            enemy.Configure(this, playerRoot.transform, 68f + wave * 8f, 2.1f + wave * 0.18f);
            enemies.Add(enemy);
            SetStatus("CONTACTS " + enemies.Count + "  +" + pendingSpawns);
        }

        public void ActivateTouchAction(RedlineRebuildTouchSurface.Role role)
        {
            if (role == RedlineRebuildTouchSurface.Role.StartOperation)
            {
                BeginOperation();
            }
            else if (role == RedlineRebuildTouchSurface.Role.Reload)
            {
                StartReload();
            }
            else if (role == RedlineRebuildTouchSurface.Role.Pause)
            {
                PauseOperation();
            }
            else if (role == RedlineRebuildTouchSurface.Role.Resume)
            {
                ResumeOperation();
            }
            else if (role == RedlineRebuildTouchSurface.Role.ReturnToMenu)
            {
                ShowHome();
            }
        }

        public void SetUiMove(Vector2 value)
        {
            if (state == AppState.Playing)
            {
                uiMove = Vector2.ClampMagnitude(value, 1f);
            }
        }

        public void AddUiLook(Vector2 delta)
        {
            if (state == AppState.Playing)
            {
                queuedLook += delta;
            }
        }

        public void SetUiFire(bool held)
        {
            if (state == AppState.Playing)
            {
                uiFireHeld = held;
            }
        }

        public void ApplyEnemyDamage(float amount)
        {
            if (state != AppState.Playing)
            {
                return;
            }
            health = Mathf.Max(0, health - Mathf.RoundToInt(amount));
            SetStatus("UNDER ATTACK");
            if (health <= 0)
            {
                EndOperation(false);
            }
        }

        public void EliminateEnemy(RedlineRebuildEnemy enemy)
        {
            if (enemy == null)
            {
                return;
            }
            enemies.Remove(enemy);
            enemiesDefeated++;
            Destroy(enemy.gameObject);
            SetStatus("CONTACT ELIMINATED");
        }

        private void PauseOperation()
        {
            if (state != AppState.Playing)
            {
                return;
            }
            state = AppState.Paused;
            uiFireHeld = false;
            uiMove = Vector2.zero;
            pauseOverlay = CreatePanel("Pause Overlay", page.transform, Vector2.zero, Vector2.one, new Color(0.01f, 0.03f, 0.05f, 0.88f));
            CreateText(pauseOverlay.transform, "OPERATION PAUSED\nঅপারেশন বিরতিতে", 40, Color.white, TextAnchor.MiddleCenter, new Vector2(0.2f, 0.59f), new Vector2(0.8f, 0.74f));
            CreateTouchSurface(pauseOverlay.transform, "Resume Surface", "RESUME", RedlineRebuildTouchSurface.Role.Resume, new Vector2(0.34f, 0.39f), new Vector2(0.66f, 0.49f), new Color(0.12f, 0.55f, 0.42f, 1f));
            CreateTouchSurface(pauseOverlay.transform, "Menu Surface", "RETURN TO MENU", RedlineRebuildTouchSurface.Role.ReturnToMenu, new Vector2(0.34f, 0.25f), new Vector2(0.66f, 0.35f), new Color(0.42f, 0.20f, 0.18f, 1f));
        }

        private void ResumeOperation()
        {
            if (state != AppState.Paused)
            {
                return;
            }
            if (pauseOverlay != null)
            {
                Destroy(pauseOverlay);
                pauseOverlay = null;
            }
            state = AppState.Playing;
            SetStatus("OPERATION RESUMED");
        }

        private void EndOperation(bool succeeded)
        {
            resultSuccess = succeeded;
            state = AppState.Results;
            uiFireHeld = false;
            ClearPage();
            ClearWorld();
            page = CreatePanel("Results", canvas.transform, Vector2.zero, Vector2.one, new Color(0.025f, 0.055f, 0.075f, 1f));
            var title = resultSuccess ? "OUTPOST SECURED" : "OPERATION FAILED";
            var localized = resultSuccess ? "মিশন সম্পন্ন" : "মিশন ব্যর্থ";
            CreateText(page.transform, title + "\n" + localized, 48, resultSuccess ? new Color(0.52f, 1f, 0.72f) : new Color(1f, 0.42f, 0.35f), TextAnchor.MiddleCenter, new Vector2(0.18f, 0.63f), new Vector2(0.82f, 0.80f));
            var accuracy = shotsFired == 0 ? 0 : Mathf.RoundToInt(shotsHit * 100f / shotsFired);
            CreateText(page.transform, "Waves reached: " + wave + " / " + TotalWaves + "\nContacts eliminated: " + enemiesDefeated + "\nAccuracy: " + accuracy + "%", 26, Color.white, TextAnchor.MiddleCenter, new Vector2(0.26f, 0.42f), new Vector2(0.74f, 0.57f));
            CreateTouchSurface(page.transform, "Play Again Surface", "PLAY AGAIN", RedlineRebuildTouchSurface.Role.StartOperation, new Vector2(0.33f, 0.23f), new Vector2(0.67f, 0.34f), new Color(0.12f, 0.55f, 0.42f, 1f));
            CreateTouchSurface(page.transform, "Main Menu Surface", "MAIN MENU", RedlineRebuildTouchSurface.Role.ReturnToMenu, new Vector2(0.33f, 0.10f), new Vector2(0.67f, 0.20f), new Color(0.26f, 0.38f, 0.44f, 0.92f));
        }

        private void RefreshHud()
        {
            if (waveLabel == null)
            {
                return;
            }
            waveLabel.text = "WAVE " + wave + " / " + TotalWaves + "   CONTACTS " + enemies.Count + (pendingSpawns > 0 ? "  +" + pendingSpawns : string.Empty);
            healthLabel.text = "HP " + health + "   SIM " + elapsed.ToString("0.0") + "s";
            ammoLabel.text = reloadInProgress ? "RELOADING" : ammo + " / " + reserveAmmo;
        }

        private void SetStatus(string value)
        {
            if (statusLabel != null)
            {
                statusLabel.text = value;
            }
        }

        private Material GroundMaterial()
        {
            return GroundMaterial(Color.white);
        }

        private Material GroundMaterial(Color color)
        {
            var material = CreateMaterial(color, RedlineRebuildAssetResolver.TextureOrFallback("desert_ground", groundTexture));
            material.mainTextureScale = new Vector2(12f, 12f);
            return material;
        }

        private Material CreateMaterial(Color color, Texture2D texture)
        {
            var shader = mobileShader != null ? mobileShader : Shader.Find("Unlit/Color");
            var material = new Material(shader);
            if (material.HasProperty("_Color"))
            {
                material.color = color;
            }
            if (texture != null && material.HasProperty("_MainTex"))
            {
                material.mainTexture = texture;
            }
            worldMaterials.Add(material);
            return material;
        }

        private GameObject CreatePrimitive(string objectName, PrimitiveType type, Vector3 position, Vector3 scale, Material material)
        {
            var primitive = GameObject.CreatePrimitive(type);
            primitive.name = objectName;
            primitive.transform.position = position;
            primitive.transform.localScale = scale;
            var renderer = primitive.GetComponent<Renderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = material;
            }
            return primitive;
        }

        private GameObject CreateWorldProp(string assetKey, string fallbackName, PrimitiveType type, Vector3 position, Vector3 scale, Material material)
        {
            var supplied = RedlineRebuildAssetResolver.InstantiateIfPresent(assetKey, worldRoot.transform, position, Quaternion.identity, scale);
            if (supplied != null)
            {
                return supplied;
            }
            var fallback = CreatePrimitive(fallbackName, type, position, scale, material);
            fallback.transform.SetParent(worldRoot.transform, true);
            return fallback;
        }

        private void ClearWorld()
        {
            enemies.Clear();
            if (worldRoot != null)
            {
                Destroy(worldRoot);
                worldRoot = null;
            }
            if (playerRoot != null)
            {
                Destroy(playerRoot);
                playerRoot = null;
                playerController = null;
                playerCamera = null;
                cameraPivot = null;
            }
            foreach (var material in worldMaterials)
            {
                if (material != null)
                {
                    Destroy(material);
                }
            }
            worldMaterials.Clear();
        }

        private void ClearPage()
        {
            if (page != null)
            {
                Destroy(page);
                page = null;
            }
            pauseOverlay = null;
            statusLabel = null;
            healthLabel = null;
            waveLabel = null;
            ammoLabel = null;
        }

        private GameObject CreatePanel(string objectName, Transform parent, Vector2 anchorMin, Vector2 anchorMax, Color color)
        {
            var panel = new GameObject(objectName, typeof(RectTransform), typeof(Image));
            panel.transform.SetParent(parent, false);
            var rect = panel.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            panel.GetComponent<Image>().color = color;
            return panel;
        }

        private Text CreateText(Transform parent, string value, int size, Color color, TextAnchor alignment, Vector2 anchorMin, Vector2 anchorMax)
        {
            var item = new GameObject("Text", typeof(RectTransform), typeof(Text));
            item.transform.SetParent(parent, false);
            var rect = item.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            var text = item.GetComponent<Text>();
            text.font = uiFont;
            text.text = value;
            text.fontSize = size;
            text.color = color;
            text.alignment = alignment;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            return text;
        }

        private Button CreateButton(Transform parent, string label, Vector2 anchorMin, Vector2 anchorMax, Color color, UnityAction action)
        {
            var item = CreatePanel("Button " + label, parent, anchorMin, anchorMax, color);
            var button = item.AddComponent<Button>();
            button.targetGraphic = item.GetComponent<Image>();
            button.onClick.AddListener(action);
            var text = CreateText(item.transform, label, 25, Color.white, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one);
            text.raycastTarget = false;
            return button;
        }

        private GameObject CreateTouchSurface(Transform parent, string objectName, string label, RedlineRebuildTouchSurface.Role role, Vector2 anchorMin, Vector2 anchorMax, Color color)
        {
            var item = CreatePanel(objectName, parent, anchorMin, anchorMax, color);
            var surface = item.AddComponent<RedlineRebuildTouchSurface>();
            surface.Configure(this, role, 135f);
            if (!string.IsNullOrEmpty(label))
            {
                var text = CreateText(item.transform, label, 25, Color.white, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one);
                text.raycastTarget = false;
            }
            return item;
        }
    }
}
