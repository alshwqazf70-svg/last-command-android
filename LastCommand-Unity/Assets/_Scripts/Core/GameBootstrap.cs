using UnityEngine;

namespace LastCommand
{
    public class GameBootstrap : MonoBehaviour
    {
        public static GameBootstrap Instance { get; private set; }
        public HeroController Hero { get; private set; }
        public BaseManager Base { get; private set; }
        public int Gold { get; private set; } = 500;
        public int Food { get; private set; } = 300;
        public int Metal { get; private set; } = 200;
        public int PlayerLevel { get; private set; } = 1;
        public int XP { get; private set; }
        public string Status { get; set; } = "Secure the outpost";

        private float spawnTimer;
        private int wave = 1;
        private int pendingBaseLevel = 1;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            Enemy.ResetRegistry();
            Application.targetFrameRate = 60;
            QualitySettings.vSyncCount = 0;
            SaveSystem.Load(this);
        }

        private void Start()
        {
            BuildWorld();
            SpawnHero();
            SpawnCamera();
            SpawnWave();
        }

        private void Update()
        {
            spawnTimer += Time.deltaTime;
            if (spawnTimer >= 24f && Enemy.ActiveCount < 3)
            {
                spawnTimer = 0f;
                wave++;
                SpawnWave();
                Status = "Enemy wave " + wave;
            }
        }

        private void BuildWorld()
        {
            RenderSettings.ambientLight = new Color(.48f, .52f, .57f);
            var light = new GameObject("Sun").AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.15f;
            light.transform.rotation = Quaternion.Euler(48f, -32f, 0f);

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Military terrain";
            ground.transform.localScale = new Vector3(7, 1, 7);
            ground.GetComponent<Renderer>().material = Mat(new Color(.22f, .29f, .20f));

            CreateRoad(new Vector3(0, .025f, -5), new Vector3(3, .04f, 24));
            CreateBuilding("COMMAND HQ", new Vector3(0, 1.1f, 8), new Vector3(5, 2.2f, 4), new Color(.27f,.31f,.27f));
            CreateBuilding("BARRACKS", new Vector3(-8, .8f, 7), new Vector3(4, 1.6f, 4), new Color(.34f,.37f,.30f));
            CreateBuilding("SUPPLY DEPOT", new Vector3(8, .8f, 7), new Vector3(4, 1.6f, 4), new Color(.36f,.32f,.24f));
            CreateBuilding("METAL WORKS", new Vector3(-9, .65f, -1), new Vector3(3, 1.3f, 3), new Color(.31f,.34f,.35f));
            CreateBuilding("FIELD FARM", new Vector3(9, .65f, -1), new Vector3(3, 1.3f, 3), new Color(.28f,.39f,.22f));
            for (int i = 0; i < 8; i++)
            {
                float a = i * Mathf.PI / 4f;
                var post = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                post.name = "Perimeter defense";
                post.transform.position = new Vector3(Mathf.Cos(a) * 17f, .65f, Mathf.Sin(a) * 17f);
                post.transform.localScale = new Vector3(.45f, .65f, .45f);
                post.GetComponent<Renderer>().material = Mat(new Color(.22f,.25f,.22f));
            }
            Base = gameObject.AddComponent<BaseManager>();
            Base.RestoreLevel(pendingBaseLevel);
        }

        private void SpawnHero()
        {
            var heroObject = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            heroObject.name = "Player Commander";
            heroObject.transform.position = new Vector3(0, 1, -9);
            heroObject.GetComponent<Renderer>().material = Mat(new Color(.18f,.38f,.22f));
            heroObject.AddComponent<SoldierVisual>().Build(new Color(.22f,.34f,.20f), new Color(.16f,.19f,.15f));
            Hero = heroObject.AddComponent<HeroController>();
        }

        private void SpawnCamera()
        {
            var camObject = new GameObject("Main Camera");
            camObject.tag = "MainCamera";
            var cam = camObject.AddComponent<Camera>();
            cam.fieldOfView = 58f;
            camObject.AddComponent<AudioListener>();
            var follow = camObject.AddComponent<CameraFollow>();
            follow.Target = Hero.transform;
            camObject.transform.position = Hero.transform.position + new Vector3(0, 13, -17);
            camObject.transform.LookAt(Hero.transform.position);
        }

        private void SpawnWave()
        {
            for (int i = 0; i < Mathf.Min(3 + wave, 6); i++)
            {
                var enemyObject = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                enemyObject.name = "Hostile raider";
                enemyObject.transform.position = new Vector3(Random.Range(-12f, 12f), 1f, Random.Range(13f, 20f));
                enemyObject.GetComponent<Renderer>().material = Mat(new Color(.48f,.16f,.13f));
                enemyObject.AddComponent<SoldierVisual>().Build(new Color(.38f,.20f,.16f), new Color(.19f,.16f,.14f));
                enemyObject.AddComponent<Enemy>();
            }
        }

        public void RestoreSavedState(int gold, int food, int metal, int level, int baseLevel)
        {
            Gold = Mathf.Max(0, gold); Food = Mathf.Max(0, food); Metal = Mathf.Max(0, metal);
            PlayerLevel = Mathf.Max(1, level); pendingBaseLevel = Mathf.Max(1, baseLevel);
        }

        public void AddReward(int gold, int xp)
        {
            Gold += gold; XP += xp;
            while (XP >= PlayerLevel * 100) { XP -= PlayerLevel * 100; PlayerLevel++; Status = "Commander level increased!"; }
            SaveSystem.Save(this);
        }

        public bool SpendGold(int amount)
        {
            if (Gold < amount) return false;
            Gold -= amount; SaveSystem.Save(this); return true;
        }

        public void UpgradeBase()
        {
            if (Base != null && !Base.UpgradeHeadquarters()) Status = "Not enough gold";
        }

        public void AddProduction(int gold, int food, int metal)
        {
            Gold += gold; Food += food; Metal += metal; SaveSystem.Save(this);
            Status = "Resource production collected";
        }

        public static Material Mat(Color color)
        {
            var shader = Shader.Find("Universal Render Pipeline/Lit");
            if (shader == null) shader = Shader.Find("Standard");
            var m = new Material(shader); m.color = color; return m;
        }

        private void CreateRoad(Vector3 pos, Vector3 scale)
        {
            var road = GameObject.CreatePrimitive(PrimitiveType.Cube);
            road.name = "Concrete access road"; road.transform.position = pos; road.transform.localScale = scale;
            road.GetComponent<Renderer>().material = Mat(new Color(.25f,.27f,.27f));
        }

        private void CreateBuilding(string label, Vector3 pos, Vector3 size, Color color)
        {
            var root = new GameObject(label);
            root.transform.position = pos;
            var body = GameObject.CreatePrimitive(PrimitiveType.Cube);
            body.transform.SetParent(root.transform, false); body.transform.localScale = size;
            body.GetComponent<Renderer>().material = Mat(color);
            var roof = GameObject.CreatePrimitive(PrimitiveType.Cube);
            roof.transform.SetParent(root.transform, false); roof.transform.localPosition = new Vector3(0, size.y * .55f, 0);
            roof.transform.localScale = new Vector3(size.x * 1.04f, .18f, size.z * 1.04f);
            roof.GetComponent<Renderer>().material = Mat(new Color(.16f,.19f,.17f));
            var labelObject = new GameObject("Label");
            labelObject.transform.SetParent(root.transform, false); labelObject.transform.localPosition = new Vector3(0, size.y * .8f, -size.z * .55f);
        }

        private void OnGUI()
        {
            if (Hero == null) return;
            GUI.color = new Color(.08f,.10f,.09f,.92f);
            GUI.Box(new Rect(12, 12, 300, 116), GUIContent.none);
            GUI.color = Color.white;
            GUI.Label(new Rect(24, 20, 280, 24), "LAST COMMAND  |  COMMANDER Lv." + PlayerLevel);
            GUI.Label(new Rect(24, 46, 280, 22), "GOLD  " + Gold + "     FOOD  " + Food + "     METAL  " + Metal);
            GUI.Label(new Rect(24, 72, 280, 22), "BASE Lv." + (Base != null ? Base.Level : 1) + "    HP " + Mathf.CeilToInt(Hero.Health) + "    ENEMIES " + Enemy.ActiveCount);
            GUI.Label(new Rect(24, 98, 280, 22), Status);
            float y = Screen.height - 64;
            if (GUI.Button(new Rect(12, y, 125, 48), "GRENADE")) Hero.Grenade();
            if (GUI.Button(new Rect(145, y, 125, 48), "SHIELD")) Hero.ActivateShield();
            if (GUI.Button(new Rect(Screen.width - 150, y, 138, 48), "UPGRADE BASE")) UpgradeBase();
            GUI.Label(new Rect(12, Screen.height - 92, 280, 24), "Tap ground to move  |  WASD on PC  |  Auto-fire");
        }
    }
}
