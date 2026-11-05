using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>Self-cleaning procedural visual used for muzzle/tracer feedback.</summary>
    public sealed class UnityTransientEffect : MonoBehaviour
    {
        private float remaining;

        public void Initialize(float lifetime)
        {
            remaining = Mathf.Max(0.01f, lifetime);
        }

        private void Update()
        {
            remaining -= Time.deltaTime;
            if (remaining <= 0f)
            {
                Destroy(gameObject);
            }
        }
    }
}
