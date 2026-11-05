using System.Collections.Generic;
using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Unity migration baseline for the playable Desert Outpost. It owns the
    /// menu, map selection, first-person survival loop, local settings, sound,
    /// and truthful locked Highrise card without depending on imported scenes.
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

        private static readonly int[] WaveSizes = { 6, 9, 12 };
        private readonly List<RaiderActor> raiders = new List<RaiderActor>();
        private readonly List<GameObject> worldObjects = new List<GameObject>();
        private readonly Vector3[] spawnPoints =
        {
            new Vector3(-32f, 1f, -28f), new Vector3(31f, 1f, -26f),
            new Vector3(-30f, 1f, 27f), new Vector3(30f, 1f, 29f),
            new Vector3(0f, 1f, -37f), new Vector3(36f, 1f, 0f),
        };

        private UnitySettings settings;
        private GameScreen screen;
        private float splashUntil;
        private Transform player;
        private Transform cameraPivot;
        private Camera playerCamera;
        private float yaw;
        private float pitch;
        private float health;
        private int score;
        private int wave;
        private int pendingSpawns;
        private float waveDelay;
        private float spawnDelay;
        private float fireDelay;
        private bool operationComplete;
        private bool operationFailed;
        private AudioSource music;
        private AudioSource effects;
        private AudioClip rifleShot;
        private AudioClip pistolShot;
        private AudioClip reloadClick;
        private Texture2D menuBackdrop;
        private Font bengaliFont;

        public bool IsGameplayStopped => screen != GameScreen.Gameplay;

        private void Awake()
        {
            settings = new UnitySettings();
            settings.SetQuality(settings.Quality);
            Application.targetFrameRate = 60;
            splashUntil = Time.unscaledTime + 1.15f;
            screen = GameScreen.Splash;
            LoadPresentationAssets();
            CreateAudio();
        }

        private void LoadPresentationAssets()
        {
            menuBackdrop = Resources.Load<Texture2D>("UI/menu_desert_outpost");
            bengaliFont = Resources.Load<Font>("Fonts/NotoSansBengali-Regular");
            rifleShot = Resources.Load<AudioClip>("Audio/rifle_shot");
            pistolShot = Resources.Load<AudioClip>("Audio/pistol_shot");
            reloadClick = Resources.Load<AudioClip>("Audio/reload_click");
        }

        private void CreateAudio()
        {
            music = gameObject.AddComponent<AudioSource>();
            music.clip = Resources.Load<AudioClip>("Audio/outpost_watch");
            music.loop = true;
            music.volume = settings.MusicVolume;
            if (music.clip != null)
            {
                music.Play();
            }
            effects = gameObject.AddComponent<AudioSource>();
            effects.volume = 0.85f;
        }

        private void Update()
        {
            music.volume = settings.MusicVolume;
            if (screen == GameScreen.Splash && Time.unscaledTime >= splashUntil)
            {
                screen = GameScreen.Menu;
            }

            if (Input.GetKeyDown(KeyCode.Escape))
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
                screen = GameScreen.Paused;
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }
            else if (screen == GameScreen.Paused)
            {
                ResumeOperation();
            }
            else if (screen == GameScreen.MapSelect || screen == GameScreen.Settings || screen == GameScreen.Results)
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
            score = 0;
            wave = 0;
            pendingSpawns = 0;
            waveDelay = 1.25f;
            spawnDelay = 0f;
            fireDelay = 0f;
            operationComplete = false;
            operationFailed = false;
            screen = GameScreen.Gameplay;
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        private void ResumeOperation()
        {
            screen = GameScreen.Gameplay;
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        private void UpdateGameplay()
        {
            if (player == null || playerCamera == null)
            {
                operationFailed = true;
                screen = GameScreen.Results;
                return;
            }

            UpdatePlayerMotion();
            UpdateWaveSpawning();
            fireDelay -= Time.deltaTime;
            if ((Input.GetMouseButton(0) || Input.GetKey(KeyCode.Space)) && fireDelay <= 0f)
            {
                FireRifle();
            }
        }

        private void UpdatePlayerMotion()
        {
            var horizontal = Input.GetAxisRaw("Horizontal");
            var vertical = Input.GetAxisRaw("Vertical");
            var lookX = Input.GetAxis("Mouse X") * 2.6f;
            var lookY = Input.GetAxis("Mouse Y") * 2.1f;

            foreach (var touch in Input.touches)
            {
                if (touch.position.x < Screen.width * 0.48f)
                {
                    var movement = (touch.position - new Vector2(Screen.width * 0.24f, Screen.height * 0.2f)) / 120f;
                    horizontal = Mathf.Clamp(movement.x, -1f, 1f);
                    vertical = Mathf.Clamp(movement.y, -1f, 1f);
                }
                else if (touch.phase == TouchPhase.Moved)
                {
                    lookX += touch.deltaPosition.x * 0.07f;
                    lookY += touch.deltaPosition.y * 0.06f;
                }
            }

            yaw += lookX;
            pitch = Mathf.Clamp(pitch - lookY, -62f, 62f);
            player.rotation = Quaternion.Euler(0f, yaw, 0f);
            cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, 0f);

            var move = (player.forward * vertical + player.right * horizontal).normalized;
            player.position += move * 8f * Time.deltaTime;
            player.position = new Vector3(Mathf.Clamp(player.position.x, -52f, 52f), 1.8f, Mathf.Clamp(player.position.z, -52f, 52f));
        }

        private void UpdateWaveSpawning()
        {
            if (pendingSpawns > 0)
            {
                spawnDelay -= Time.deltaTime;
                if (spawnDelay <= 0f)
                {
                    SpawnRaider();
                    pendingSpawns--;
                    spawnDelay = Mathf.Max(0.45f, 0.95f - wave * 0.1f);
                }
                return;
            }

            if (raiders.Count > 0)
            {
                return;
            }

            waveDelay -= Time.deltaTime;
            if (waveDelay > 0f)
            {
                return;
            }

            if (wave >= WaveSizes.Length)
            {
                operationComplete = true;
                screen = GameScreen.Results;
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
                return;
            }

            wave++;
            pendingSpawns = WaveSizes[wave - 1];
            spawnDelay = 0.15f;
            waveDelay = 4f;
        }

        private void SpawnRaider()
        {
            var enemy = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            enemy.name = "Raider Wave " + wave;
            var spawn = spawnPoints[(pendingSpawns + wave + raiders.Count) % spawnPoints.Length];
            enemy.transform.position = spawn;
            enemy.transform.localScale = new Vector3(1.1f, 1.3f, 1.1f);
            var renderer = enemy.GetComponent<Renderer>();
            renderer.material.color = wave == 3 ? new Color(0.58f, 0.16f, 0.12f) : new Color(0.35f, 0.24f, 0.16f);
            var actor = enemy.AddComponent<RaiderActor>();
            actor.Initialize(this, player, wave);
            raiders.Add(actor);
            worldObjects.Add(enemy);
        }

        private void FireRifle()
        {
            fireDelay = 0.17f;
            if (rifleShot != null)
            {
                effects.PlayOneShot(rifleShot, 0.55f);
            }
            if (Physics.Raycast(playerCamera.transform.position, playerCamera.transform.forward, out var hit, 90f))
            {
                var enemy = hit.collider.GetComponent<RaiderActor>();
                if (enemy != null)
                {
                    enemy.TakeDamage(28f);
                }
            }
        }

        public void OnRaiderEliminated(RaiderActor actor)
        {
            raiders.Remove(actor);
            score += 100;
        }

        public void ApplyPlayerDamage(float amount)
        {
            health = Mathf.Max(0f, health - amount);
            if (health <= 0f)
            {
                operationFailed = true;
                screen = GameScreen.Results;
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }
        }

        private void BuildDesertOutpost()
        {
            var world = new GameObject("MP_DS_01 Desert Outpost");
            worldObjects.Add(world);

            var light = new GameObject("Desert Sun").AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.15f;
            light.color = new Color(1f, 0.77f, 0.5f);
            light.transform.rotation = Quaternion.Euler(42f, -34f, 0f);
            worldObjects.Add(light.gameObject);

            RenderSettings.ambientLight = new Color(0.37f, 0.36f, 0.31f);
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.63f, 0.48f, 0.32f);
            RenderSettings.fogDensity = 0.006f;

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Desert Ground";
            ground.transform.localScale = new Vector3(12f, 1f, 12f);
            ground.GetComponent<Renderer>().material.color = new Color(0.54f, 0.36f, 0.18f);
            worldObjects.Add(ground);

            CreateBlock("Command Yard", new Vector3(0f, 2.2f, -8f), new Vector3(14f, 4.4f, 6f), new Color(0.25f, 0.28f, 0.25f));
            CreateBlock("North Hangar", new Vector3(-20f, 2f, -24f), new Vector3(13f, 4f, 9f), new Color(0.31f, 0.32f, 0.28f));
            CreateBlock("South Checkpoint", new Vector3(21f, 1.3f, 20f), new Vector3(11f, 2.6f, 5f), new Color(0.35f, 0.3f, 0.22f));
            CreateBlock("Radio Tower", new Vector3(28f, 8f, -8f), new Vector3(2.2f, 16f, 2.2f), new Color(0.16f, 0.19f, 0.19f));
            for (var index = 0; index < 8; index++)
            {
                var position = new Vector3(-35f + index * 10f, 1f, 32f);
                CreateBlock("Supply Cover " + index, position, new Vector3(3.6f, 2f, 2.2f), new Color(0.36f, 0.25f, 0.13f));
            }

            var playerRoot = new GameObject("Player");
            playerRoot.transform.position = new Vector3(0f, 1.8f, 13f);
            player = playerRoot.transform;
            worldObjects.Add(playerRoot);
            cameraPivot = new GameObject("Camera Pivot").transform;
            cameraPivot.SetParent(player, false);
            playerCamera = new GameObject("Player Camera").AddComponent<Camera>();
            playerCamera.tag = "MainCamera";
            playerCamera.transform.SetParent(cameraPivot, false);
            playerCamera.transform.localPosition = Vector3.zero;
            playerCamera.fieldOfView = 72f;
            worldObjects.Add(playerCamera.gameObject);
        }

        private void CreateBlock(string blockName, Vector3 position, Vector3 scale, Color color)
        {
            var block = GameObject.CreatePrimitive(PrimitiveType.Cube);
            block.name = blockName;
            block.transform.position = position;
            block.transform.localScale = scale;
            block.GetComponent<Renderer>().material.color = color;
            worldObjects.Add(block);
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
            raiders.Clear();
            player = null;
            playerCamera = null;
            cameraPivot = null;
            RenderSettings.fog = false;
        }

        private void OnGUI()
        {
            var titleStyle = Style(42, new Color(0.56f, 0.97f, 1f), TextAnchor.MiddleCenter, true);
            var subtitleStyle = Style(18, new Color(1f, 0.58f, 0.25f), TextAnchor.MiddleCenter, false);
            var bodyStyle = Style(18, Color.white, TextAnchor.MiddleCenter, false);
            var leftStyle = Style(17, Color.white, TextAnchor.UpperLeft, false);
            var buttonStyle = Style(20, Color.white, TextAnchor.MiddleCenter, true);
            var language = settings.Language;

            if (screen != GameScreen.Gameplay)
            {
                DrawMenuBackdrop();
            }

            if (screen == GameScreen.Splash)
            {
                GUI.Label(new Rect(0, Screen.height * 0.31f, Screen.width, 65), LocalizedCatalog.Get("app.title", language), titleStyle);
                GUI.Label(new Rect(0, Screen.height * 0.41f, Screen.width, 32), LocalizedCatalog.Get("app.subtitle", language), subtitleStyle);
                GUI.Label(new Rect(0, Screen.height * 0.59f, Screen.width, 30), "Tap / ENTER", bodyStyle);
                if (Event.current.type == EventType.MouseDown || Input.anyKeyDown)
                {
                    screen = GameScreen.Menu;
                }
                return;
            }

            if (screen == GameScreen.Menu)
            {
                DrawPanel(new Rect(Screen.width * 0.5f - 235f, Screen.height * 0.5f - 180f, 470f, 380f));
                GUI.Label(new Rect(0, Screen.height * 0.16f, Screen.width, 58), LocalizedCatalog.Get("app.title", language), titleStyle);
                GUI.Label(new Rect(0, Screen.height * 0.25f, Screen.width, 32), LocalizedCatalog.Get("app.subtitle", language), subtitleStyle);
                if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.43f, 340f, 58f), LocalizedCatalog.Get("menu.play", language), buttonStyle)) screen = GameScreen.MapSelect;
                if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.51f, 340f, 58f), LocalizedCatalog.Get("menu.continue", language), buttonStyle)) BeginOperation();
                if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.59f, 340f, 58f), LocalizedCatalog.Get("menu.settings", language), buttonStyle)) screen = GameScreen.Settings;
                if (Button(new Rect(Screen.width * 0.5f - 170f, Screen.height * 0.67f, 340f, 58f), LocalizedCatalog.Get("menu.quit", language), buttonStyle)) Application.Quit();
                return;
            }

            if (screen == GameScreen.MapSelect)
            {
                DrawPanel(new Rect(35f, 85f, Screen.width - 70f, Screen.height - 150f));
                GUI.Label(new Rect(0, 28f, Screen.width, 45f), LocalizedCatalog.Get("menu.map_select", language), titleStyle);
                DrawMapCard(new Rect(Screen.width * 0.16f, 145f, Screen.width * 0.3f, 305f), "map.desert", "map.desert.detail", true, buttonStyle, bodyStyle);
                DrawMapCard(new Rect(Screen.width * 0.54f, 145f, Screen.width * 0.3f, 305f), "map.highrise", "map.highrise.detail", false, buttonStyle, bodyStyle);
                if (Button(new Rect(42f, Screen.height - 60f, 180f, 42f), LocalizedCatalog.Get("menu.back", language), buttonStyle)) screen = GameScreen.Menu;
                return;
            }

            if (screen == GameScreen.Settings)
            {
                DrawPanel(new Rect(Screen.width * 0.5f - 280f, 90f, 560f, Screen.height - 170f));
                GUI.Label(new Rect(0, 35f, Screen.width, 48f), LocalizedCatalog.Get("settings.title", language), titleStyle);
                GUI.Label(new Rect(Screen.width * 0.5f - 220f, 145f, 200f, 36f), LocalizedCatalog.Get("settings.language", language), leftStyle);
                if (Button(new Rect(Screen.width * 0.5f + 10f, 140f, 210f, 45f), language == SupportedLanguage.English ? "English" : "বাংলা", buttonStyle)) settings.ToggleLanguage();
                GUI.Label(new Rect(Screen.width * 0.5f - 220f, 215f, 200f, 36f), LocalizedCatalog.Get("settings.quality", settings.Language), leftStyle);
                for (var index = 0; index < 3; index++)
                {
                    var qualityKey = index == 0 ? "quality.low" : index == 1 ? "quality.medium" : "quality.high";
                    if (Button(new Rect(Screen.width * 0.5f - 220f + index * 148f, 265f, 138f, 44f), LocalizedCatalog.Get(qualityKey, settings.Language), buttonStyle)) settings.SetQuality(index);
                }
                GUI.Label(new Rect(Screen.width * 0.5f - 220f, 345f, 200f, 36f), LocalizedCatalog.Get("settings.audio", settings.Language), leftStyle);
                settings.SetMusicVolume(GUI.HorizontalSlider(new Rect(Screen.width * 0.5f - 30f, 355f, 250f, 24f), settings.MusicVolume, 0f, 1f));
                if (Button(new Rect(Screen.width * 0.5f - 100f, Screen.height - 115f, 200f, 46f), LocalizedCatalog.Get("menu.back", settings.Language), buttonStyle)) screen = GameScreen.Menu;
                return;
            }

            if (screen == GameScreen.Gameplay)
            {
                DrawGameplayHud(leftStyle, buttonStyle);
                return;
            }

            if (screen == GameScreen.Paused)
            {
                DrawPanel(new Rect(Screen.width * 0.5f - 220f, Screen.height * 0.5f - 150f, 440f, 315f));
                GUI.Label(new Rect(0, Screen.height * 0.33f, Screen.width, 50f), LocalizedCatalog.Get("game.pause", language), titleStyle);
                if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.47f, 300f, 52f), LocalizedCatalog.Get("game.resume", language), buttonStyle)) ResumeOperation();
                if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.55f, 300f, 52f), LocalizedCatalog.Get("game.maps", language), buttonStyle)) { ClearWorld(); screen = GameScreen.MapSelect; }
                if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.63f, 300f, 52f), LocalizedCatalog.Get("menu.settings", language), buttonStyle)) screen = GameScreen.Settings;
                return;
            }

            if (screen == GameScreen.Results)
            {
                DrawPanel(new Rect(Screen.width * 0.5f - 250f, Screen.height * 0.5f - 160f, 500f, 335f));
                var result = operationComplete ? LocalizedCatalog.Get("game.complete", language) : LocalizedCatalog.Get("game.failed", language);
                GUI.Label(new Rect(0, Screen.height * 0.31f, Screen.width, 56f), result, titleStyle);
                GUI.Label(new Rect(0, Screen.height * 0.42f, Screen.width, 40f), LocalizedCatalog.Get("game.score", language) + "  " + score, bodyStyle);
                GUI.Label(new Rect(0, Screen.height * 0.48f, Screen.width, 36f), LocalizedCatalog.Get("game.wave", language) + "  " + wave + " / 3", bodyStyle);
                if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.58f, 300f, 52f), LocalizedCatalog.Get("game.restart", language), buttonStyle)) BeginOperation();
                if (Button(new Rect(Screen.width * 0.5f - 150f, Screen.height * 0.66f, 300f, 52f), LocalizedCatalog.Get("game.maps", language), buttonStyle)) { ClearWorld(); screen = GameScreen.MapSelect; }
            }
        }

        private void DrawMapCard(Rect rect, string titleKey, string detailKey, bool playable, GUIStyle buttonStyle, GUIStyle bodyStyle)
        {
            DrawPanel(rect);
            GUI.Label(new Rect(rect.x + 18f, rect.y + 18f, rect.width - 36f, 48f), LocalizedCatalog.Get(titleKey, settings.Language), Style(24, new Color(1f, 0.7f, 0.39f), TextAnchor.MiddleCenter, true));
            GUI.Label(new Rect(rect.x + 20f, rect.y + 82f, rect.width - 40f, 112f), LocalizedCatalog.Get(detailKey, settings.Language), bodyStyle);
            if (playable)
            {
                if (Button(new Rect(rect.x + 25f, rect.y + rect.height - 70f, rect.width - 50f, 48f), LocalizedCatalog.Get("menu.start", settings.Language), buttonStyle)) BeginOperation();
            }
            else
            {
                GUI.Label(new Rect(rect.x + 18f, rect.y + rect.height - 67f, rect.width - 36f, 45f), LocalizedCatalog.Get("menu.locked", settings.Language), Style(19, new Color(0.78f, 0.57f, 0.42f), TextAnchor.MiddleCenter, true));
            }
        }

        private void DrawGameplayHud(GUIStyle leftStyle, GUIStyle buttonStyle)
        {
            GUI.Box(new Rect(14f, 14f, 250f, 115f), string.Empty);
            GUI.Label(new Rect(28f, 26f, 230f, 27f), LocalizedCatalog.Get("game.wave", settings.Language) + "  " + Mathf.Max(wave, 1) + " / 3", leftStyle);
            GUI.Label(new Rect(28f, 55f, 230f, 27f), LocalizedCatalog.Get("game.score", settings.Language) + "  " + score, leftStyle);
            GUI.Label(new Rect(28f, 84f, 230f, 27f), LocalizedCatalog.Get("game.health", settings.Language) + "  " + Mathf.CeilToInt(health), leftStyle);
            GUI.Label(new Rect(Screen.width * 0.5f - 8f, Screen.height * 0.5f - 18f, 16f, 36f), "+", Style(28, Color.white, TextAnchor.MiddleCenter, true));
            GUI.Label(new Rect(0f, Screen.height - 38f, Screen.width, 28f), Application.isMobilePlatform ? LocalizedCatalog.Get("hint.mobile", settings.Language) : LocalizedCatalog.Get("hint.desktop", settings.Language), Style(13, Color.white, TextAnchor.MiddleCenter, false));
            if (GUI.RepeatButton(new Rect(Screen.width - 140f, Screen.height - 150f, 120f, 120f), LocalizedCatalog.Get("game.fire", settings.Language), buttonStyle) && fireDelay <= 0f) FireRifle();
            if (Button(new Rect(Screen.width - 120f, 18f, 105f, 40f), LocalizedCatalog.Get("game.pause", settings.Language), buttonStyle)) HandleBack();
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
            ClearWorld();
        }
    }
}
