using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>Minimal procedural hostile used by the portable Desert baseline.</summary>
    public sealed class RaiderActor : MonoBehaviour
    {
        private OperationGame owner;
        private Transform target;
        private float health;
        private float attackCooldown;
        private float speed;

        public void Initialize(OperationGame game, Transform playerTarget, int wave)
        {
            owner = game;
            target = playerTarget;
            health = 45f + wave * 12f;
            speed = 2.2f + wave * 0.16f;
        }

        public void TakeDamage(float amount)
        {
            health -= amount;
            if (health <= 0f)
            {
                if (owner != null)
                {
                    owner.OnRaiderEliminated(this);
                }
                Destroy(gameObject);
            }
        }

        private void Update()
        {
            if (owner == null || target == null || owner.IsGameplayStopped)
            {
                return;
            }

            var direction = target.position - transform.position;
            direction.y = 0f;
            var distance = direction.magnitude;
            if (distance > 1.65f)
            {
                transform.position += direction.normalized * speed * Time.deltaTime;
                if (direction.sqrMagnitude > 0.001f)
                {
                    transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(direction), 10f * Time.deltaTime);
                }
                return;
            }

            attackCooldown -= Time.deltaTime;
            if (attackCooldown <= 0f)
            {
                owner.ApplyPlayerDamage(7f);
                attackCooldown = 0.85f;
            }
        }
    }
}
