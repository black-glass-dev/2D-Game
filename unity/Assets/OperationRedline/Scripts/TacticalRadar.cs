using System.Collections.Generic;
using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Compact source-owned tactical radar for Desert Outpost. It intentionally
    /// derives positions from the live Unity world instead of a pre-authored map
    /// texture, so the procedural migration scene retains truthful contacts.
    /// </summary>
    public sealed class TacticalRadar : MonoBehaviour
    {
        private const float Range = 48f;

        public void Draw(Rect rect, Transform player, IList<RaiderActor> contacts, bool colorblindMode)
        {
            if (player == null)
            {
                return;
            }

            GUI.color = new Color(0.015f, 0.07f, 0.08f, 0.86f);
            GUI.DrawTexture(rect, Texture2D.whiteTexture);
            GUI.color = colorblindMode ? new Color(1f, 0.92f, 0.32f) : new Color(0.42f, 0.92f, 0.88f);
            GUI.DrawTexture(new Rect(rect.center.x - 1f, rect.center.y - 1f, 2f, 2f), Texture2D.whiteTexture);
            GUI.color = Color.white;

            foreach (var contact in contacts)
            {
                if (contact == null)
                {
                    continue;
                }
                var worldOffset = contact.transform.position - player.position;
                worldOffset.y = 0f;
                var localOffset = player.InverseTransformDirection(worldOffset);
                var normalized = Vector2.ClampMagnitude(new Vector2(localOffset.x, localOffset.z) / Range, 1f);
                var point = rect.center + normalized * (rect.width * 0.42f);
                GUI.color = colorblindMode ? new Color(1f, 0.38f, 0.16f) : new Color(0.96f, 0.22f, 0.18f);
                GUI.DrawTexture(new Rect(point.x - 3f, point.y - 3f, 6f, 6f), Texture2D.whiteTexture);
            }
            GUI.color = Color.white;
        }
    }
}
