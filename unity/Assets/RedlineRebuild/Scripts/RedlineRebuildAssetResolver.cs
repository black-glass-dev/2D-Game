using UnityEngine;

namespace OperationRedline.Rebuild
{
    /// <summary>
    /// Stable asset handoff seam. Final player-provided models can be imported as
    /// Resources/Rebuild/Prefabs/&lt;key&gt;.prefab. The rebuild automatically uses a
    /// supplied prefab and otherwise keeps its safe temporary fallback.
    /// </summary>
    public static class RedlineRebuildAssetResolver
    {
        private const string PrefabRoot = "Rebuild/Prefabs/";
        private const string TextureRoot = "Rebuild/Textures/";

        public static GameObject InstantiateIfPresent(string key, Transform parent, Vector3 position, Quaternion rotation, Vector3 scale)
        {
            var prefab = Resources.Load<GameObject>(PrefabRoot + key);
            if (prefab == null)
            {
                return null;
            }
            var instance = Object.Instantiate(prefab, position, rotation, parent);
            instance.name = "Player Asset " + key;
            instance.transform.localScale = scale;
            return instance;
        }

        public static Texture2D TextureOrFallback(string key, Texture2D fallback)
        {
            var suppliedTexture = Resources.Load<Texture2D>(TextureRoot + key);
            return suppliedTexture != null ? suppliedTexture : fallback;
        }
    }
}
