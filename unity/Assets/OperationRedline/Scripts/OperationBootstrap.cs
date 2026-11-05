using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Creates the complete Unity vertical slice from the Bootstrap scene.  The
    /// project intentionally uses one code-owned runtime root during migration:
    /// it avoids a hidden dependency on generated scene objects and makes the
    /// Android build runnable immediately after import.
    /// </summary>
    public static class OperationBootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void StartOperationRedline()
        {
            if (Object.FindObjectOfType<OperationGame>() != null)
            {
                return;
            }

            var root = new GameObject("Operation Redline Unity Runtime");
            Object.DontDestroyOnLoad(root);
            root.AddComponent<OperationGame>();
        }
    }
}
