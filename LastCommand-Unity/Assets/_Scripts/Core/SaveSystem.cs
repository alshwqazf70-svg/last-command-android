using UnityEngine;

namespace LastCommand
{
    public static class SaveSystem
    {
        private const string GoldKey = "LC_Gold";
        private const string FoodKey = "LC_Food";
        private const string MetalKey = "LC_Metal";
        private const string LevelKey = "LC_Level";

        public static void Save(GameBootstrap game)
        {
            if (game == null) return;
            PlayerPrefs.SetInt(GoldKey, game.Gold);
            PlayerPrefs.SetInt(FoodKey, game.Food);
            PlayerPrefs.SetInt(MetalKey, game.Metal);
            PlayerPrefs.SetInt(LevelKey, game.PlayerLevel);
            PlayerPrefs.Save();
        }

        public static void Load(GameBootstrap game)
        {
            if (game == null) return;
            if (PlayerPrefs.HasKey(GoldKey))
            {
                game.RestoreSavedState(
                    PlayerPrefs.GetInt(GoldKey, game.Gold),
                    PlayerPrefs.GetInt(FoodKey, game.Food),
                    PlayerPrefs.GetInt(MetalKey, game.Metal),
                    PlayerPrefs.GetInt(LevelKey, game.PlayerLevel));
            }
        }
    }
}
