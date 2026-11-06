using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// Named migration-owned bindings. Keyboard overrides are persisted without
    /// modifying Unity's project-wide Input Manager, and touch remains explicit
    /// in the playable HUD rather than becoming a screen-wide fire binding.
    /// </summary>
    public sealed class UnityControls
    {
        public enum Action
        {
            MoveForward,
            MoveBack,
            MoveLeft,
            MoveRight,
            Fire,
            Aim,
            Jump,
            Crouch,
            SwapWeapon,
            Reload,
            Pause,
        }

        private const string Prefix = "operation_redline.unity.binding.";

        public KeyCode GetKey(Action action)
        {
            return (KeyCode)PlayerPrefs.GetInt(Prefix + action, (int)DefaultKey(action));
        }

        public void SetKey(Action action, KeyCode key)
        {
            if (!IsRebindable(action) || key == KeyCode.None || IsReserved(key) || HasConflict(action, key))
            {
                return;
            }
            PlayerPrefs.SetInt(Prefix + action, (int)key);
            PlayerPrefs.Save();
        }

        public bool HasConflict(Action action, KeyCode key)
        {
            foreach (Action candidate in System.Enum.GetValues(typeof(Action)))
            {
                if (candidate != action && GetKey(candidate) == key)
                {
                    return true;
                }
            }
            return false;
        }

        public void ResetDefaults()
        {
            foreach (Action action in System.Enum.GetValues(typeof(Action)))
            {
                PlayerPrefs.DeleteKey(Prefix + action);
            }
            PlayerPrefs.Save();
        }

        public static bool IsRebindable(Action action)
        {
            return action != Action.Pause;
        }

        public static bool IsReserved(KeyCode key)
        {
            return key == KeyCode.Escape || key == KeyCode.Return || key == KeyCode.KeypadEnter;
        }

        public static string Label(Action action)
        {
            switch (action)
            {
                case Action.MoveForward: return "bindings.move_forward";
                case Action.MoveBack: return "bindings.move_back";
                case Action.MoveLeft: return "bindings.move_left";
                case Action.MoveRight: return "bindings.move_right";
                case Action.Fire: return "bindings.fire";
                case Action.Aim: return "bindings.aim";
                case Action.Jump: return "bindings.jump";
                case Action.Crouch: return "bindings.crouch";
                case Action.SwapWeapon: return "bindings.swap";
                case Action.Reload: return "bindings.reload";
                default: return "bindings.pause";
            }
        }

        private static KeyCode DefaultKey(Action action)
        {
            switch (action)
            {
                case Action.MoveForward: return KeyCode.W;
                case Action.MoveBack: return KeyCode.S;
                case Action.MoveLeft: return KeyCode.A;
                case Action.MoveRight: return KeyCode.D;
                case Action.Fire: return KeyCode.Mouse0;
                case Action.Aim: return KeyCode.Mouse1;
                case Action.Jump: return KeyCode.Space;
                case Action.Crouch: return KeyCode.C;
                case Action.SwapWeapon: return KeyCode.Q;
                case Action.Reload: return KeyCode.R;
                default: return KeyCode.Escape;
            }
        }
    }
}
