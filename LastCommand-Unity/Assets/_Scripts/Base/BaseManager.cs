using UnityEngine;

namespace LastCommand
{
    public class BaseManager : MonoBehaviour
    {
        public int Level { get; set; } = 1;
        public void Refresh()
        {
            GameBootstrap.Instance.Status = "Base systems upgraded";
            SaveSystem.Save(GameBootstrap.Instance);
        }
    }
}
