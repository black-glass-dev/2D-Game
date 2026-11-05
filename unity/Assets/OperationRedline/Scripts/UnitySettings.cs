using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>Small persisted migration schema for language, quality, and music.</summary>
    public sealed class UnitySettings
    {
        private const string LanguageKey = "operation_redline.unity.language";
        private const string QualityKey = "operation_redline.unity.quality";
        private const string MusicKey = "operation_redline.unity.music";

        public SupportedLanguage Language { get; private set; }
        public int Quality { get; private set; }
        public float MusicVolume { get; private set; }

        public UnitySettings()
        {
            Language = PlayerPrefs.GetInt(LanguageKey, 0) == 1 ? SupportedLanguage.Bengali : SupportedLanguage.English;
            Quality = Mathf.Clamp(PlayerPrefs.GetInt(QualityKey, 1), 0, 2);
            MusicVolume = Mathf.Clamp01(PlayerPrefs.GetFloat(MusicKey, 0.65f));
        }

        public void ToggleLanguage()
        {
            Language = Language == SupportedLanguage.English ? SupportedLanguage.Bengali : SupportedLanguage.English;
            PlayerPrefs.SetInt(LanguageKey, Language == SupportedLanguage.Bengali ? 1 : 0);
            PlayerPrefs.Save();
        }

        public void SetQuality(int quality)
        {
            Quality = Mathf.Clamp(quality, 0, 2);
            PlayerPrefs.SetInt(QualityKey, Quality);
            PlayerPrefs.Save();
            QualitySettings.SetQualityLevel(Quality, true);
        }

        public void SetMusicVolume(float volume)
        {
            MusicVolume = Mathf.Clamp01(volume);
            PlayerPrefs.SetFloat(MusicKey, MusicVolume);
            PlayerPrefs.Save();
        }
    }
}
