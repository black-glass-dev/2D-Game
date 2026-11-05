using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Versioned player-preference schema for the Unity migration. Values stay
    /// local to Unity PlayerPrefs; the Godot files remain untouched as rollback
    /// evidence during the engine transition.
    /// </summary>
    public sealed class UnitySettings
    {
        private const int CurrentSchema = 2;
        private const string Prefix = "operation_redline.unity.";
        private const string SchemaKey = Prefix + "settings_schema";

        private const string LanguageKey = Prefix + "language";
        private const string QualityKey = Prefix + "quality";
        private const string MasterKey = Prefix + "master";
        private const string MusicKey = Prefix + "music";
        private const string SfxKey = Prefix + "sfx";
        private const string UiKey = Prefix + "ui";
        private const string MuteFocusKey = Prefix + "mute_unfocused";
        private const string LookKey = Prefix + "look_sensitivity";
        private const string AimAssistKey = Prefix + "aim_assist";
        private const string FireModeKey = Prefix + "fire_mode";
        private const string FovKey = Prefix + "fov";
        private const string BrightnessKey = Prefix + "brightness";
        private const string FpsKey = Prefix + "fps_limit";
        private const string FpsDisplayKey = Prefix + "show_fps";
        private const string SubtitleKey = Prefix + "subtitles";
        private const string DamageNumbersKey = Prefix + "damage_numbers";
        private const string ReducedMotionKey = Prefix + "reduce_motion";
        private const string ColorblindKey = Prefix + "colorblind";
        private const string HapticsKey = Prefix + "haptics";
        private const string DeadzoneKey = Prefix + "gamepad_deadzone";
        private const string JoystickScaleKey = Prefix + "joystick_scale";
        private const string ButtonScaleKey = Prefix + "button_scale";
        private const string TouchOpacityKey = Prefix + "touch_opacity";
        private const string LeftHandedKey = Prefix + "left_handed";

        public SupportedLanguage Language { get; private set; }
        public int Quality { get; private set; }
        public float MasterVolume { get; private set; }
        public float MusicVolume { get; private set; }
        public float SfxVolume { get; private set; }
        public float UiVolume { get; private set; }
        public bool MuteWhenUnfocused { get; private set; }
        public float LookSensitivity { get; private set; }
        public bool AimAssist { get; private set; }
        public bool AutoFire { get; private set; }
        public float FieldOfView { get; private set; }
        public float Brightness { get; private set; }
        public int FpsLimit { get; private set; }
        public bool ShowFps { get; private set; }
        public bool Subtitles { get; private set; }
        public bool DamageNumbers { get; private set; }
        public bool ReducedMotion { get; private set; }
        public bool ColorblindMode { get; private set; }
        public bool Haptics { get; private set; }
        public float GamepadDeadzone { get; private set; }
        public float JoystickScale { get; private set; }
        public float ButtonScale { get; private set; }
        public float TouchOpacity { get; private set; }
        public bool LeftHanded { get; private set; }

        public UnitySettings()
        {
            MigrateAndLoad();
        }

        public void ToggleLanguage()
        {
            SetLanguage(Language == SupportedLanguage.English ? SupportedLanguage.Bengali : SupportedLanguage.English);
        }

        public void SetLanguage(SupportedLanguage language)
        {
            Language = language;
            SaveInt(LanguageKey, language == SupportedLanguage.Bengali ? 1 : 0);
        }

        public void SetQuality(int quality)
        {
            Quality = Mathf.Clamp(quality, 0, Mathf.Max(0, QualitySettings.names.Length - 1));
            SaveInt(QualityKey, Quality);
            QualitySettings.SetQualityLevel(Quality, true);
        }

        public void SetMasterVolume(float volume) { MasterVolume = SaveVolume(MasterKey, volume); }
        public void SetMusicVolume(float volume) { MusicVolume = SaveVolume(MusicKey, volume); }
        public void SetSfxVolume(float volume) { SfxVolume = SaveVolume(SfxKey, volume); }
        public void SetUiVolume(float volume) { UiVolume = SaveVolume(UiKey, volume); }
        public void SetMuteWhenUnfocused(bool value) { MuteWhenUnfocused = SaveBool(MuteFocusKey, value); }
        public void SetLookSensitivity(float value) { LookSensitivity = SaveClamped(LookKey, value, 0.55f, 1.65f); }
        public void SetAimAssist(bool value) { AimAssist = SaveBool(AimAssistKey, value); }
        public void SetAutoFire(bool value) { AutoFire = SaveBool(FireModeKey, value); }
        public void SetFieldOfView(float value) { FieldOfView = SaveClamped(FovKey, value, 60f, 90f); }
        public void SetBrightness(float value) { Brightness = SaveClamped(BrightnessKey, value, 0.65f, 1.35f); }

        public void SetFpsLimit(int value)
        {
            FpsLimit = value <= 0 ? 0 : Mathf.Clamp(value, 30, 120);
            SaveInt(FpsKey, FpsLimit);
            Application.targetFrameRate = FpsLimit <= 0 ? 60 : FpsLimit;
        }

        public void SetShowFps(bool value) { ShowFps = SaveBool(FpsDisplayKey, value); }
        public void SetSubtitles(bool value) { Subtitles = SaveBool(SubtitleKey, value); }
        public void SetDamageNumbers(bool value) { DamageNumbers = SaveBool(DamageNumbersKey, value); }
        public void SetReducedMotion(bool value) { ReducedMotion = SaveBool(ReducedMotionKey, value); }
        public void SetColorblindMode(bool value) { ColorblindMode = SaveBool(ColorblindKey, value); }
        public void SetHaptics(bool value) { Haptics = SaveBool(HapticsKey, value); }
        public void SetGamepadDeadzone(float value) { GamepadDeadzone = SaveClamped(DeadzoneKey, value, 0.05f, 0.85f); }
        public void SetJoystickScale(float value) { JoystickScale = SaveClamped(JoystickScaleKey, value, 0.75f, 1.35f); }
        public void SetButtonScale(float value) { ButtonScale = SaveClamped(ButtonScaleKey, value, 0.75f, 1.35f); }
        public void SetTouchOpacity(float value) { TouchOpacity = SaveClamped(TouchOpacityKey, value, 0.35f, 1f); }
        public void SetLeftHanded(bool value) { LeftHanded = SaveBool(LeftHandedKey, value); }

        public void ResetToDefaults()
        {
            PlayerPrefs.DeleteKey(LanguageKey);
            PlayerPrefs.DeleteKey(QualityKey);
            PlayerPrefs.DeleteKey(MasterKey);
            PlayerPrefs.DeleteKey(MusicKey);
            PlayerPrefs.DeleteKey(SfxKey);
            PlayerPrefs.DeleteKey(UiKey);
            PlayerPrefs.DeleteKey(MuteFocusKey);
            PlayerPrefs.DeleteKey(LookKey);
            PlayerPrefs.DeleteKey(AimAssistKey);
            PlayerPrefs.DeleteKey(FireModeKey);
            PlayerPrefs.DeleteKey(FovKey);
            PlayerPrefs.DeleteKey(BrightnessKey);
            PlayerPrefs.DeleteKey(FpsKey);
            PlayerPrefs.DeleteKey(FpsDisplayKey);
            PlayerPrefs.DeleteKey(SubtitleKey);
            PlayerPrefs.DeleteKey(DamageNumbersKey);
            PlayerPrefs.DeleteKey(ReducedMotionKey);
            PlayerPrefs.DeleteKey(ColorblindKey);
            PlayerPrefs.DeleteKey(HapticsKey);
            PlayerPrefs.DeleteKey(DeadzoneKey);
            PlayerPrefs.DeleteKey(JoystickScaleKey);
            PlayerPrefs.DeleteKey(ButtonScaleKey);
            PlayerPrefs.DeleteKey(TouchOpacityKey);
            PlayerPrefs.DeleteKey(LeftHandedKey);
            PlayerPrefs.Save();
            MigrateAndLoad();
        }

        private void MigrateAndLoad()
        {
            if (PlayerPrefs.GetInt(SchemaKey, 0) < CurrentSchema)
            {
                PlayerPrefs.SetInt(SchemaKey, CurrentSchema);
                PlayerPrefs.Save();
            }

            Language = PlayerPrefs.GetInt(LanguageKey, 0) == 1 ? SupportedLanguage.Bengali : SupportedLanguage.English;
            Quality = Mathf.Clamp(PlayerPrefs.GetInt(QualityKey, DefaultQuality()), 0, Mathf.Max(0, QualitySettings.names.Length - 1));
            MasterVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(MasterKey, 1f));
            MusicVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(MusicKey, 0.65f));
            SfxVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(SfxKey, 0.85f));
            UiVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(UiKey, 0.85f));
            MuteWhenUnfocused = PlayerPrefs.GetInt(MuteFocusKey, 1) == 1;
            LookSensitivity = Mathf.Clamp(PlayerPrefs.GetFloat(LookKey, 1f), 0.55f, 1.65f);
            AimAssist = PlayerPrefs.GetInt(AimAssistKey, 1) == 1;
            AutoFire = PlayerPrefs.GetInt(FireModeKey, 0) == 1;
            FieldOfView = Mathf.Clamp(PlayerPrefs.GetFloat(FovKey, 75f), 60f, 90f);
            Brightness = Mathf.Clamp(PlayerPrefs.GetFloat(BrightnessKey, 1f), 0.65f, 1.35f);
            FpsLimit = PlayerPrefs.GetInt(FpsKey, 60);
            ShowFps = PlayerPrefs.GetInt(FpsDisplayKey, 0) == 1;
            Subtitles = PlayerPrefs.GetInt(SubtitleKey, 1) == 1;
            DamageNumbers = PlayerPrefs.GetInt(DamageNumbersKey, 1) == 1;
            ReducedMotion = PlayerPrefs.GetInt(ReducedMotionKey, 0) == 1;
            ColorblindMode = PlayerPrefs.GetInt(ColorblindKey, 0) == 1;
            Haptics = PlayerPrefs.GetInt(HapticsKey, 1) == 1;
            GamepadDeadzone = Mathf.Clamp(PlayerPrefs.GetFloat(DeadzoneKey, 0.2f), 0.05f, 0.85f);
            JoystickScale = Mathf.Clamp(PlayerPrefs.GetFloat(JoystickScaleKey, 1f), 0.75f, 1.35f);
            ButtonScale = Mathf.Clamp(PlayerPrefs.GetFloat(ButtonScaleKey, 1f), 0.75f, 1.35f);
            TouchOpacity = Mathf.Clamp(PlayerPrefs.GetFloat(TouchOpacityKey, 1f), 0.35f, 1f);
            LeftHanded = PlayerPrefs.GetInt(LeftHandedKey, 0) == 1;
            QualitySettings.SetQualityLevel(Quality, true);
            Application.targetFrameRate = FpsLimit <= 0 ? 60 : FpsLimit;
        }

        private static int DefaultQuality()
        {
            return Mathf.Clamp(QualitySettings.names.Length > 2 ? 2 : 0, 0, Mathf.Max(0, QualitySettings.names.Length - 1));
        }

        private static float SaveVolume(string key, float value)
        {
            return SaveClamped(key, value, 0f, 1f);
        }

        private static float SaveClamped(string key, float value, float minimum, float maximum)
        {
            var result = Mathf.Clamp(value, minimum, maximum);
            PlayerPrefs.SetFloat(key, result);
            PlayerPrefs.Save();
            return result;
        }

        private static bool SaveBool(string key, bool value)
        {
            SaveInt(key, value ? 1 : 0);
            return value;
        }

        private static void SaveInt(string key, int value)
        {
            PlayerPrefs.SetInt(key, value);
            PlayerPrefs.Save();
        }
    }
}
