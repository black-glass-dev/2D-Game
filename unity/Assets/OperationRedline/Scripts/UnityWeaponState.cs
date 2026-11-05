using UnityEngine;

namespace OperationRedline.Unity
{
    public enum WeaponKind
    {
        Carbine,
        Sidearm,
    }

    /// <summary>Deterministic ammo, cooldown and reload authority for the two Desert weapons.</summary>
    public sealed class UnityWeaponState
    {
        public WeaponKind Kind { get; private set; }
        public int MagazineSize { get; private set; }
        public int Ammo { get; private set; }
        public int Reserve { get; private set; }
        public float Damage { get; private set; }
        public float Range { get; private set; }
        public float FireInterval { get; private set; }
        public float ReloadDuration { get; private set; }
        public bool IsReloading { get { return reloadLeft > 0f; } }

        private float cooldownLeft;
        private float reloadLeft;

        public UnityWeaponState(WeaponKind kind)
        {
            Kind = kind;
            if (kind == WeaponKind.Carbine)
            {
                MagazineSize = 30;
                Reserve = 150;
                Damage = 28f;
                Range = 90f;
                FireInterval = 0.17f;
                ReloadDuration = 1.15f;
            }
            else
            {
                MagazineSize = 12;
                Reserve = 72;
                Damage = 29f;
                Range = 62f;
                FireInterval = 0.19f;
                ReloadDuration = 1f;
            }
            Ammo = MagazineSize;
        }

        public void Update(float deltaTime)
        {
            cooldownLeft = Mathf.Max(0f, cooldownLeft - deltaTime);
            if (reloadLeft <= 0f)
            {
                return;
            }
            reloadLeft -= deltaTime;
            if (reloadLeft <= 0f)
            {
                var required = MagazineSize - Ammo;
                var transferred = Mathf.Min(required, Reserve);
                Ammo += transferred;
                Reserve -= transferred;
            }
        }

        public bool TryFire()
        {
            if (cooldownLeft > 0f || IsReloading)
            {
                return false;
            }
            if (Ammo <= 0)
            {
                StartReload();
                return false;
            }
            Ammo--;
            cooldownLeft = FireInterval;
            return true;
        }

        public bool StartReload()
        {
            if (IsReloading || Ammo >= MagazineSize || Reserve <= 0)
            {
                return false;
            }
            reloadLeft = ReloadDuration;
            return true;
        }
    }
}
