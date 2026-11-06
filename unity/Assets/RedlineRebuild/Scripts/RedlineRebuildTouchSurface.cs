using UnityEngine;
using UnityEngine.EventSystems;

namespace OperationRedline.Rebuild
{
    /// <summary>
    /// A UGUI/EventSystem touch surface. Unlike the retired prototype's raw
    /// Input.touches polling, Android pointer events are delivered directly by
    /// the active UI control and retain pointer ownership until release.
    /// </summary>
    public sealed class RedlineRebuildTouchSurface : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler, ICancelHandler
    {
        public enum Role
        {
            Move,
            Look,
            Fire,
        }

        private RedlineRebuildGame owner;
        private Role role;
        private float moveRadius;
        private int activePointer = int.MinValue;
        private Vector2 origin;
        private Vector2 previous;

        public void Configure(RedlineRebuildGame activeOwner, Role activeRole, float radius)
        {
            owner = activeOwner;
            role = activeRole;
            moveRadius = Mathf.Max(30f, radius);
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (activePointer != int.MinValue)
            {
                return;
            }
            activePointer = eventData.pointerId;
            origin = eventData.position;
            previous = origin;
            Dispatch(eventData.position);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (eventData.pointerId != activePointer)
            {
                return;
            }
            Dispatch(eventData.position);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (eventData.pointerId == activePointer)
            {
                Release();
            }
        }

        public void OnCancel(BaseEventData eventData)
        {
            Release();
        }

        private void OnDisable()
        {
            Release();
        }

        private void Dispatch(Vector2 position)
        {
            if (owner == null)
            {
                return;
            }
            if (role == Role.Move)
            {
                owner.SetUiMove(Vector2.ClampMagnitude((position - origin) / moveRadius, 1f));
            }
            else if (role == Role.Look)
            {
                owner.AddUiLook(position - previous);
                previous = position;
            }
            else
            {
                owner.SetUiFire(true);
            }
        }

        private void Release()
        {
            if (activePointer == int.MinValue)
            {
                return;
            }
            if (owner != null)
            {
                if (role == Role.Move)
                {
                    owner.SetUiMove(Vector2.zero);
                }
                else if (role == Role.Fire)
                {
                    owner.SetUiFire(false);
                }
            }
            activePointer = int.MinValue;
        }
    }
}
