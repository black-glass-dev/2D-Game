using UnityEngine;

namespace OperationRedline.Rebuild
{
    /// <summary>
    /// Entry point for the clean Unity rebuild. This intentionally starts a
    /// separate runtime from the earlier migration prototype so the new mobile
    /// game has no hidden dependency on its screen or input code.
    /// </summary>
    public static class RedlineRebuildBootstrap
    {
        public static void EnsureRuntime()
        {
            if (Object.FindObjectOfType<RedlineRebuildGame>() != null)
            {
                return;
            }

            var root = new GameObject("Operation Redline Rebuild Runtime");
            Object.DontDestroyOnLoad(root);
            root.AddComponent<RedlineRebuildGame>();
        }
    }
}
