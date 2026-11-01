using System.Collections.Generic;
using UnityEngine;

namespace LastCommand
{
    public class Enemy : MonoBehaviour
    {
        public static readonly List<Enemy> All = new List<Enemy>();
        public static int ActiveCount => All.FindAll(e => e != null).Count;
        public float Health = 60f;
        private float attackTimer;

        private void OnEnable() { if (!All.Contains(this)) All.Add(this); }
        private void OnDisable() { All.Remove(this); }

        private void Update()
        {
            if (GameBootstrap.Instance == null || GameBootstrap.Instance.Hero == null) return;
            Transform hero = GameBootstrap.Instance.Hero.transform;
            Vector3 d = hero.position - transform.position; d.y = 0;
            if (d.magnitude > 2f)
            {
                transform.position += d.normalized * 2.1f * Time.deltaTime;
                transform.rotation = Quaternion.LookRotation(d);
            }
            else
            {
                attackTimer -= Time.deltaTime;
                if (attackTimer <= 0f) { attackTimer = 1.1f; GameBootstrap.Instance.Hero.TakeDamage(8f); }
            }
        }

        public void TakeDamage(float amount)
        {
            Health -= amount;
            if (Health <= 0f)
            {
                Vector3 p = transform.position;
                Destroy(gameObject);
                GameBootstrap.Instance.AddReward(25, 20);
                VFXManager.Burst(p, new Color(1f,.32f,.12f));
                GameBootstrap.Instance.Status = "Hostile eliminated +25 gold";
            }
        }

        public static Enemy Nearest(Vector3 from, float range)
        {
            Enemy best = null; float bestD = range;
            foreach (Enemy e in All)
            {
                if (e == null) continue;
                float d = Vector3.Distance(from, e.transform.position);
                if (d < bestD) { bestD = d; best = e; }
            }
            return best;
        }
    }
}
