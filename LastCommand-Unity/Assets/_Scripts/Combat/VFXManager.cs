using UnityEngine;

namespace LastCommand
{
    public static class VFXManager
    {
        public static void Burst(Vector3 position, Color color)
        {
            var fx = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            fx.name = "Temporary impact effect";
            fx.transform.position = position;
            fx.transform.localScale = Vector3.one * .35f;
            fx.GetComponent<Renderer>().material = GameBootstrap.Mat(color);
            Object.Destroy(fx.GetComponent<Collider>());
            Object.Destroy(fx, .22f);
        }

        public static void Tracer(Vector3 start, Vector3 end, Color color)
        {
            var go = new GameObject("Bullet tracer");
            var line = go.AddComponent<LineRenderer>();
            line.positionCount = 2;
            line.SetPosition(0, start);
            line.SetPosition(1, end);
            line.startWidth = .045f;
            line.endWidth = .012f;
            line.useWorldSpace = true;
            Shader shader = Shader.Find("Sprites/Default");
            if (shader == null) shader = Shader.Find("Unlit/Color");
            if (shader != null) line.material = new Material(shader);
            line.startColor = color;
            line.endColor = new Color(color.r, color.g, color.b, 0f);
            Object.Destroy(go, .09f);
        }
    }
}