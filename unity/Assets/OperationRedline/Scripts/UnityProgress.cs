using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Minimal durable operation record. It stores only migration-owned Unity
    /// keys so installing the Unity review APK cannot erase the retained Godot
    /// rollback profile.
    /// </summary>
    public sealed class UnityProgress
    {
        private const string Prefix = "operation_redline.unity.progress.";
        private const string LastMapKey = Prefix + "last_map";
        private const string BestScorePrefix = Prefix + "best_score.";
        private const string BestWavePrefix = Prefix + "best_wave.";

        public string LastMapId
        {
            get { return PlayerPrefs.GetString(LastMapKey, "MP_DS_01"); }
        }

        public void SetLastMap(string mapId)
        {
            if (string.IsNullOrEmpty(mapId))
            {
                return;
            }
            PlayerPrefs.SetString(LastMapKey, mapId);
            PlayerPrefs.Save();
        }

        public OperationRecord GetRecord(string mapId)
        {
            var safeId = SanitizeMapId(mapId);
            return new OperationRecord(
                PlayerPrefs.GetInt(BestScorePrefix + safeId, 0),
                PlayerPrefs.GetInt(BestWavePrefix + safeId, 0));
        }

        public OperationRecord RecordResult(string mapId, int score, int wave)
        {
            var safeId = SanitizeMapId(mapId);
            var before = GetRecord(safeId);
            var bestScore = Mathf.Max(before.BestScore, Mathf.Max(0, score));
            var bestWave = Mathf.Max(before.BestWave, Mathf.Max(0, wave));
            PlayerPrefs.SetInt(BestScorePrefix + safeId, bestScore);
            PlayerPrefs.SetInt(BestWavePrefix + safeId, bestWave);
            PlayerPrefs.Save();
            return new OperationRecord(bestScore, bestWave);
        }

        private static string SanitizeMapId(string mapId)
        {
            return string.IsNullOrEmpty(mapId) ? "MP_DS_01" : mapId.Replace(" ", "_");
        }
    }

    public struct OperationRecord
    {
        public readonly int BestScore;
        public readonly int BestWave;

        public OperationRecord(int bestScore, int bestWave)
        {
            BestScore = bestScore;
            BestWave = bestWave;
        }
    }
}
