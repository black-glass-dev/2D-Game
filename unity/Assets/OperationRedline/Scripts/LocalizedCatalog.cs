using System.Collections.Generic;

namespace OperationRedline.Unity
{
    public enum SupportedLanguage
    {
        English,
        Bengali,
    }

    /// <summary>
    /// Small, code-owned player-facing catalog for the Unity migration baseline.
    /// It keeps the menu legible before importing the full Godot CSV pipeline and
    /// deliberately contains all labels exposed by OperationGame.
    /// </summary>
    public static class LocalizedCatalog
    {
        private static readonly Dictionary<string, string> English = new Dictionary<string, string>
        {
            { "app.title", "OPERATION REDLINE" },
            { "app.subtitle", "TACTICAL SURVIVAL" },
            { "menu.play", "PLAY" },
            { "menu.continue", "CONTINUE" },
            { "menu.settings", "SETTINGS" },
            { "menu.quit", "QUIT" },
            { "menu.map_select", "MAP SELECT" },
            { "menu.back", "BACK" },
            { "menu.start", "START MISSION" },
            { "menu.locked", "COMING SOON" },
            { "map.desert", "DESERT OUTPOST" },
            { "map.desert.detail", "Defend the border outpost through three survival waves." },
            { "map.highrise", "ROOFTOP HIGHRISE" },
            { "map.highrise.detail", "Locked pending authoritative B2 design inputs." },
            { "settings.title", "SETTINGS" },
            { "settings.language", "LANGUAGE" },
            { "settings.quality", "QUALITY" },
            { "settings.audio", "MUSIC" },
            { "quality.low", "LOW" },
            { "quality.medium", "MEDIUM" },
            { "quality.high", "HIGH" },
            { "game.wave", "WAVE" },
            { "game.score", "SCORE" },
            { "game.health", "HP" },
            { "game.pause", "PAUSED" },
            { "game.resume", "RESUME" },
            { "game.maps", "MAP SELECT" },
            { "game.restart", "RESTART" },
            { "game.complete", "MISSION COMPLETE" },
            { "game.failed", "MISSION FAILED" },
            { "game.fire", "FIRE" },
            { "game.aim", "AIM" },
            { "hint.desktop", "WASD move • mouse look • click/FIRE to shoot • ESC pause" },
            { "hint.mobile", "Left side: move • drag right side: look • FIRE to shoot" },
        };

        private static readonly Dictionary<string, string> Bengali = new Dictionary<string, string>
        {
            { "app.title", "অপারেশন রেডলাইন" },
            { "app.subtitle", "কৌশলগত সারভাইভাল" },
            { "menu.play", "খেলুন" },
            { "menu.continue", "চালিয়ে যান" },
            { "menu.settings", "সেটিংস" },
            { "menu.quit", "বন্ধ করুন" },
            { "menu.map_select", "ম্যাপ নির্বাচন" },
            { "menu.back", "ফিরে যান" },
            { "menu.start", "মিশন শুরু করুন" },
            { "menu.locked", "শীঘ্রই আসছে" },
            { "map.desert", "ডেজার্ট আউটপোস্ট" },
            { "map.desert.detail", "তিনটি সারভাইভাল ওয়েভে সীমান্ত ঘাঁটি রক্ষা করুন।" },
            { "map.highrise", "রুফটপ হাইরাইজ" },
            { "map.highrise.detail", "অনুমোদিত B2 নকশা তথ্য না আসা পর্যন্ত লকড।" },
            { "settings.title", "সেটিংস" },
            { "settings.language", "ভাষা" },
            { "settings.quality", "কোয়ালিটি" },
            { "settings.audio", "মিউজিক" },
            { "quality.low", "লো" },
            { "quality.medium", "মিডিয়াম" },
            { "quality.high", "হাই" },
            { "game.wave", "ওয়েভ" },
            { "game.score", "স্কোর" },
            { "game.health", "এইচপি" },
            { "game.pause", "বিরতি" },
            { "game.resume", "আবার শুরু" },
            { "game.maps", "ম্যাপ নির্বাচন" },
            { "game.restart", "আবার শুরু" },
            { "game.complete", "মিশন সম্পন্ন" },
            { "game.failed", "মিশন ব্যর্থ" },
            { "game.fire", "ফায়ার" },
            { "game.aim", "এম" },
            { "hint.desktop", "WASD চলুন • মাউস দিয়ে তাকান • ক্লিক/FIRE দিয়ে গুলি • ESC বিরতি" },
            { "hint.mobile", "বাম পাশে চলুন • ডান পাশে টেনে তাকান • FIRE দিয়ে গুলি করুন" },
        };

        public static string Get(string key, SupportedLanguage language)
        {
            var catalog = language == SupportedLanguage.Bengali ? Bengali : English;
            return catalog.TryGetValue(key, out var value) ? value : key;
        }
    }
}
