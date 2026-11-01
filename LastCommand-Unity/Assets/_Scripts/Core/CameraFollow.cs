using UnityEngine;

namespace LastCommand
{
    public class CameraFollow : MonoBehaviour
    {
        public Transform Target;
        private void LateUpdate()
        {
            if (Target == null) return;
            Vector3 wanted = Target.position + new Vector3(0, 13, -17);
            transform.position = Vector3.Lerp(transform.position, wanted, 5f * Time.deltaTime);
            transform.LookAt(Target.position + Vector3.up);
        }
    }
}
