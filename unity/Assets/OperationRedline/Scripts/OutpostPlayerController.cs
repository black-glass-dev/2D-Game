using UnityEngine;

namespace OperationRedline.Unity
{
    /// <summary>
    /// First-person movement controller for the Unity Desert migration. It owns
    /// keyboard, gamepad-axis and explicit two-zone touch locomotion while the
    /// operation controller owns enemies, waves and UI state.
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public sealed class OutpostPlayerController : MonoBehaviour
    {
        private const float StandHeight = 1.8f;
        private const float CrouchHeight = 1.2f;
        private const float WalkSpeed = 5.2f;
        private const float SprintSpeed = 7.35f;
        private const float CrouchSpeed = 2.75f;
        private const float JumpVelocity = 7.4f;
        private const float Gravity = 21f;

        private CharacterController controller;
        private Transform cameraPivot;
        private Camera playerCamera;
        private UnitySettings settings;
        private UnityControls controls;
        private float verticalVelocity;
        private float yaw;
        private float pitch;
        private bool crouching;
        private bool aiming;
        private int moveTouch = -1;
        private int lookTouch = -1;
        private Vector2 moveTouchOrigin;
        private Vector2 touchMove;
        private Rect[] mobileUiExclusions = new Rect[0];
        private bool fallbackPointerMove;
        private bool fallbackPointerLook;
        private Vector2 fallbackPointerLast;
        private bool touchJumpQueued;
        private bool landedThisFrame;

        public Camera PlayerCamera { get { return playerCamera; } }
        public bool IsAiming { get { return aiming; } }
        public bool IsCrouching { get { return crouching; } }
        public bool LandedThisFrame { get { return landedThisFrame; } }
        public bool HasMoveTouch { get { return moveTouch >= 0 || fallbackPointerMove; } }
        public Vector2 MoveTouchOrigin { get { return moveTouchOrigin; } }
        public Vector2 TouchMove { get { return touchMove; } }

        public void Initialize(UnitySettings activeSettings, UnityControls activeControls)
        {
            settings = activeSettings;
            controls = activeControls;
            controller = GetComponent<CharacterController>();
            controller.height = StandHeight;
            controller.radius = 0.38f;
            controller.center = new Vector3(0f, StandHeight * 0.5f, 0f);
            controller.stepOffset = 0.35f;
            controller.slopeLimit = 45f;

            cameraPivot = new GameObject("Camera Pivot").transform;
            cameraPivot.SetParent(transform, false);
            cameraPivot.localPosition = new Vector3(0f, 1.48f, 0f);
            playerCamera = new GameObject("Player Camera").AddComponent<Camera>();
            playerCamera.tag = "MainCamera";
            playerCamera.transform.SetParent(cameraPivot, false);
            playerCamera.transform.localPosition = Vector3.zero;
            ApplySettings();
        }

        public void ApplySettings()
        {
            if (settings == null || playerCamera == null)
            {
                return;
            }
            playerCamera.fieldOfView = aiming ? Mathf.Min(settings.FieldOfView, 55f) : settings.FieldOfView;
        }

        public void SetAiming(bool value)
        {
            aiming = value;
            ApplySettings();
        }

        public void SetMobileUiExclusions(Rect[] exclusions)
        {
            mobileUiExclusions = exclusions ?? new Rect[0];
        }

        public void RequestTouchJump()
        {
            touchJumpQueued = true;
        }

        public void ToggleCrouch()
        {
            crouching = !crouching;
            if (controller == null)
            {
                return;
            }
            controller.height = crouching ? CrouchHeight : StandHeight;
            controller.center = new Vector3(0f, controller.height * 0.5f, 0f);
            if (cameraPivot != null)
            {
                cameraPivot.localPosition = new Vector3(0f, crouching ? 1.02f : 1.48f, 0f);
            }
        }

        public void UpdateMovement(bool controlsEnabled)
        {
            landedThisFrame = false;
            if (!controlsEnabled || controller == null || settings == null || controls == null)
            {
                return;
            }

            ReadTouchInput();
            var horizontal = ReadAxis(controls.GetKey(UnityControls.Action.MoveRight), controls.GetKey(UnityControls.Action.MoveLeft), Input.GetAxisRaw("Horizontal"));
            var forward = ReadAxis(controls.GetKey(UnityControls.Action.MoveForward), controls.GetKey(UnityControls.Action.MoveBack), -Input.GetAxisRaw("Vertical"));
            if (touchMove.sqrMagnitude > 0.0025f)
            {
                horizontal = touchMove.x;
                forward = touchMove.y;
            }

            var lookScale = settings.LookSensitivity;
            if (aiming)
            {
                lookScale *= 0.45f;
            }
            var lookX = Input.GetAxis("Mouse X") * 2.6f * lookScale;
            var lookY = Input.GetAxis("Mouse Y") * 2.1f * lookScale;
            yaw += lookX;
            pitch = Mathf.Clamp(pitch - lookY, -78f, 78f);
            transform.rotation = Quaternion.Euler(0f, yaw, 0f);
            cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, 0f);

            if (Input.GetKeyDown(controls.GetKey(UnityControls.Action.Crouch)) || Input.GetKeyDown(KeyCode.JoystickButton9))
            {
                ToggleCrouch();
            }

            var jumpPressed = touchJumpQueued || Input.GetKeyDown(controls.GetKey(UnityControls.Action.Jump)) || Input.GetKeyDown(KeyCode.JoystickButton0);
            touchJumpQueued = false;
            var wasGrounded = controller.isGrounded;
            if (wasGrounded && verticalVelocity < 0f)
            {
                verticalVelocity = -1f;
            }
            if (wasGrounded && jumpPressed && !crouching)
            {
                verticalVelocity = JumpVelocity;
            }
            verticalVelocity -= Gravity * Time.unscaledDeltaTime;

            var sprint = (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift) || Input.GetKey(KeyCode.JoystickButton8))
                         && !crouching && !aiming && new Vector2(horizontal, forward).sqrMagnitude > 0.04f;
            var speed = crouching ? CrouchSpeed : sprint ? SprintSpeed : aiming ? 3.15f : WalkSpeed;
            var move = (transform.right * horizontal + transform.forward * forward).normalized * speed;
            var oldVertical = verticalVelocity;
            controller.Move((move + Vector3.up * verticalVelocity) * Time.unscaledDeltaTime);
            if (!wasGrounded && controller.isGrounded && oldVertical < -5f)
            {
                landedThisFrame = true;
            }
        }

        private float ReadAxis(KeyCode positive, KeyCode negative, float fallbackAxis)
        {
            var direct = 0f;
            if (Input.GetKey(positive)) direct += 1f;
            if (Input.GetKey(negative)) direct -= 1f;
            return Mathf.Abs(direct) > 0f ? direct : Mathf.Abs(fallbackAxis) >= settings.GamepadDeadzone ? fallbackAxis : 0f;
        }

        private void ReadTouchInput()
        {
            touchMove = Vector2.zero;
            if (Application.isMobilePlatform && Input.touchCount == 0)
            {
                ReadPrimaryPointerFallback();
                return;
            }
            fallbackPointerMove = false;
            fallbackPointerLook = false;
            foreach (var touch in Input.touches)
            {
                if (touch.phase == TouchPhase.Began)
                {
                    if (IsOverMobileUi(touch.position))
                    {
                        continue;
                    }
                    var movementHalf = settings.LeftHanded
                        ? touch.position.x >= Screen.width * 0.5f
                        : touch.position.x < Screen.width * 0.5f;
                    if (movementHalf && moveTouch < 0)
                    {
                        moveTouch = touch.fingerId;
                        moveTouchOrigin = touch.position;
                    }
                    else if (lookTouch < 0)
                    {
                        lookTouch = touch.fingerId;
                    }
                }
                if (touch.fingerId == moveTouch && (touch.phase == TouchPhase.Moved || touch.phase == TouchPhase.Stationary))
                {
                    var radius = 78f * settings.JoystickScale;
                    var movement = (touch.position - moveTouchOrigin) / Mathf.Max(28f, radius);
                    touchMove = Vector2.ClampMagnitude(movement, 1f);
                }
                if (touch.fingerId == lookTouch && touch.phase == TouchPhase.Moved)
                {
                    yaw += touch.deltaPosition.x * 0.075f * settings.LookSensitivity;
                    pitch = Mathf.Clamp(pitch - touch.deltaPosition.y * 0.06f * settings.LookSensitivity, -78f, 78f);
                }
                if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
                {
                    if (touch.fingerId == moveTouch) moveTouch = -1;
                    if (touch.fingerId == lookTouch) lookTouch = -1;
                }
            }
        }

        private void ReadPrimaryPointerFallback()
        {
            var pointer = (Vector2)Input.mousePosition;
            if (Input.GetMouseButtonDown(0))
            {
                if (IsOverMobileUi(pointer))
                {
                    fallbackPointerMove = false;
                    fallbackPointerLook = false;
                    return;
                }
                var movementHalf = settings.LeftHanded
                    ? pointer.x >= Screen.width * 0.5f
                    : pointer.x < Screen.width * 0.5f;
                if (movementHalf)
                {
                    fallbackPointerMove = true;
                    fallbackPointerLook = false;
                    moveTouchOrigin = pointer;
                }
                else
                {
                    fallbackPointerMove = false;
                    fallbackPointerLook = true;
                    fallbackPointerLast = pointer;
                }
            }
            if (!Input.GetMouseButton(0))
            {
                fallbackPointerMove = false;
                fallbackPointerLook = false;
                return;
            }
            if (fallbackPointerMove)
            {
                var radius = 78f * settings.JoystickScale;
                touchMove = Vector2.ClampMagnitude((pointer - moveTouchOrigin) / Mathf.Max(28f, radius), 1f);
            }
            if (fallbackPointerLook)
            {
                var delta = pointer - fallbackPointerLast;
                yaw += delta.x * 0.075f * settings.LookSensitivity;
                pitch = Mathf.Clamp(pitch - delta.y * 0.06f * settings.LookSensitivity, -78f, 78f);
                fallbackPointerLast = pointer;
            }
        }

        private bool IsOverMobileUi(Vector2 touchPosition)
        {
            var guiPosition = new Vector2(touchPosition.x, Screen.height - touchPosition.y);
            foreach (var excludedRect in mobileUiExclusions)
            {
                if (excludedRect.Contains(guiPosition))
                {
                    return true;
                }
            }
            return false;
        }
    }
}
