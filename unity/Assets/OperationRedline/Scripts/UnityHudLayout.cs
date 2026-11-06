using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Persistent, resolution-independent placement for touch HUD controls.
    /// Only the migration-owned controls are moved; gameplay/map coordinates
    /// never change as a side effect of a layout edit.
    /// </summary>
    public sealed class UnityHudLayout
    {
        public enum Element
        {
            Fire,
            Radar,
            Pause,
        }

        private const string Prefix = "operation_redline.unity.hud.";

        public Rect Resolve(Element element, Vector2 size, Vector2 screenSize, bool leftHanded)
        {
            var fallback = DefaultAnchor(element, leftHanded);
            var x = PlayerPrefs.GetFloat(Prefix + element + ".x", fallback.x);
            var y = PlayerPrefs.GetFloat(Prefix + element + ".y", fallback.y);
            var maxX = Mathf.Max(0f, screenSize.x - size.x);
            var maxY = Mathf.Max(0f, screenSize.y - size.y);
            return new Rect(Mathf.Clamp01(x) * maxX, Mathf.Clamp01(y) * maxY, size.x, size.y);
        }

        public void Store(Element element, Rect rect, Vector2 screenSize)
        {
            var maxX = Mathf.Max(1f, screenSize.x - rect.width);
            var maxY = Mathf.Max(1f, screenSize.y - rect.height);
            PlayerPrefs.SetFloat(Prefix + element + ".x", Mathf.Clamp01(rect.x / maxX));
            PlayerPrefs.SetFloat(Prefix + element + ".y", Mathf.Clamp01(rect.y / maxY));
            PlayerPrefs.Save();
        }

        public void Reset()
        {
            foreach (Element element in System.Enum.GetValues(typeof(Element)))
            {
                PlayerPrefs.DeleteKey(Prefix + element + ".x");
                PlayerPrefs.DeleteKey(Prefix + element + ".y");
            }
            PlayerPrefs.Save();
        }

        private static Vector2 DefaultAnchor(Element element, bool leftHanded)
        {
            switch (element)
            {
                case Element.Fire: return new Vector2(leftHanded ? 0.02f : 0.98f, 0.96f);
                case Element.Radar: return new Vector2(0.98f, 0.14f);
                default: return new Vector2(0.98f, 0.025f);
            }
        }
    }
}
