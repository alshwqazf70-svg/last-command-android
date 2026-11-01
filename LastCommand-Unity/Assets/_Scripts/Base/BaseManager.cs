using UnityEngine;

namespace LastCommand
{
    public class BaseManager : MonoBehaviour
    {
        public int Level { get; private set; } = 1;
        private float productionTimer;

        private void Update()
        {
            productionTimer += Time.deltaTime;
            if (productionTimer >= 60f)
            {
                productionTimer -= 60f;
                if (GameBootstrap.Instance != null)
                    GameBootstrap.Instance.AddProduction(30 * Level, 45 * Level, 18 * Level);
            }
        }

        public void RestoreLevel(int level)
        {
            Level = Mathf.Max(1, level);
        }

        public bool UpgradeHeadquarters()
        {
            int cost = 150 * Level;
            if (GameBootstrap.Instance == null || !GameBootstrap.Instance.SpendGold(cost))
                return false;

            Level++;
            Refresh();
            GameBootstrap.Instance.Status = "Headquarters upgraded to level " + Level;
            return true;
        }

        public void Refresh()
        {
            if (GameBootstrap.Instance == null) return;
            GameBootstrap.Instance.Status = "Base systems upgraded";
            SaveSystem.Save(GameBootstrap.Instance);
        }
    }
}