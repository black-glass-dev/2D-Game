using UnityEngine;

namespace OperationRedline.Rebuild
{
    /// <summary>Small deterministic enemy actor owned by the clean rebuild loop.</summary>
    public sealed class RedlineRebuildEnemy : MonoBehaviour
    {
        private RedlineRebuildGame owner;
        private Transform target;
        private float health;
        private float speed;
        private float attackCooldown;

        public void Configure(RedlineRebuildGame activeOwner, Transform activeTarget, float startingHealth, float movementSpeed)
        {
            owner = activeOwner;
            target = activeTarget;
            health = startingHealth;
            speed = movementSpeed;
        }

        public void Tick(float deltaTime)
        {
            if (target == null || owner == null)
            {
                return;
            }

            var flatTarget = target.position;
            flatTarget.y = transform.position.y;
            var direction = flatTarget - transform.position;
            var distance = direction.magnitude;
            if (distance > 1.85f)
            {
                var step = Mathf.Min(distance - 1.85f, speed * deltaTime);
                transform.position += direction.normalized * step;
                if (direction.sqrMagnitude > 0.0001f)
                {
                    transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(direction), Mathf.Clamp01(deltaTime * 9f));
                }
                return;
            }

            attackCooldown -= deltaTime;
            if (attackCooldown <= 0f)
            {
                attackCooldown = 0.8f;
                owner.ApplyEnemyDamage(7f);
            }
        }

        public void ApplyDamage(float amount)
        {
            health -= amount;
            if (health <= 0f && owner != null)
            {
                owner.EliminateEnemy(this);
            }
        }
    }
}
