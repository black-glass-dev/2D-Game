using OperationRedline.Rebuild;
using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Compatibility entry point kept so the Bootstrap scene remains stable.
    /// The former procedural migration runtime is retired from execution; all
    /// new gameplay now starts through the clean RedlineRebuild runtime.
    /// </summary>
    public static class OperationBootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void StartOperationRedline()
        {
            RedlineRebuildBootstrap.EnsureRuntime();
        }
    }
}
