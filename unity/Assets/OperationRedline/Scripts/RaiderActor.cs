using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>Procedural hostile for the portable Unity Desert survival loop.</summary>
    public sealed class RaiderActor : MonoBehaviour
    {
        private OperationGame owner;
        private Transform target;
        private float health;
        private float attackCooldown;
        private float speed;
        private float damage;
        private bool eliminated;

        public void Initialize(OperationGame game, Transform playerTarget, int wave, float difficultyMultiplier)
        {
            owner = game;
            target = playerTarget;
            health = (45f + wave * 12f) * difficultyMultiplier;
            speed = (2.2f + wave * 0.16f) * Mathf.Lerp(0.92f, 1.12f, difficultyMultiplier - 0.7f);
            damage = 7f * difficultyMultiplier;
        }

        public void TakeDamage(float amount, bool headshot)
        {
            if (eliminated)
            {
                return;
            }
            health -= headshot ? amount * 2f : amount;
            if (health <= 0f)
            {
                eliminated = true;
                if (owner != null)
                {
                    owner.OnRaiderEliminated(this, headshot);
                }
                Destroy(gameObject);
            }
        }

        private void Update()
        {
            if (eliminated || owner == null || target == null || owner.IsGameplayStopped)
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
                owner.ApplyPlayerDamage(damage);
                attackCooldown = 0.85f;
            }
        }
    }
}
