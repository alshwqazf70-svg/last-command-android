using UnityEngine;

namespace LastCommand
{
    public class HeroController : MonoBehaviour
    {
        public float MoveSpeed = 6f;
        public float Health = 100f;
        public float MaxHealth = 100f;
        public float Damage = 20f;
        private Vector3 destination;
        private float fireTimer;
        private float shieldTimer;
        private float grenadeCooldown;

        private void Start() { destination = transform.position; }

        private void Update()
        {
            Vector3 input = new Vector3(Input.GetAxisRaw("Horizontal"), 0, Input.GetAxisRaw("Vertical"));
            if (input.sqrMagnitude > .01f) destination = transform.position + input.normalized * 4f;
            if (Input.GetMouseButtonDown(0))
            {
                Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
                if (Physics.Raycast(ray, out RaycastHit hit, 200f)) destination = hit.point;
            }
            Vector3 delta = destination - transform.position; delta.y = 0;
            if (delta.magnitude > .25f)
            {
                transform.position += delta.normalized * MoveSpeed * Time.deltaTime;
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(delta), 10f * Time.deltaTime);
            }
            shieldTimer -= Time.deltaTime;
            grenadeCooldown -= Time.deltaTime;
            fireTimer -= Time.deltaTime;
            Enemy target = Enemy.Nearest(transform.position, 13f);
            if (target != null && fireTimer <= 0f)
            {
                fireTimer = .55f;
                target.TakeDamage(Damage);
                GameBootstrap.Instance.Status = "Engaging hostile target";
            }
            if (Health <= 0) { Health = MaxHealth; transform.position = new Vector3(0,1,-9); GameBootstrap.Instance.Status = "Commander respawned"; }
        }

        public void Grenade()
        {
            if (grenadeCooldown > 0) return;
            grenadeCooldown = 5f;
            foreach (Enemy e in Enemy.All) if (e != null && Vector3.Distance(transform.position, e.transform.position) < 6f) e.TakeDamage(65f);
            GameBootstrap.Instance.Status = "Grenade detonated";
            VFXManager.Burst(transform.position + Vector3.forward * 2f, new Color(1f,.48f,.12f));
        }

        public void ActivateShield() { shieldTimer = 4f; GameBootstrap.Instance.Status = "Shield active"; }
        public void TakeDamage(float amount) { if (shieldTimer <= 0) Health -= amount; }
    }
}
