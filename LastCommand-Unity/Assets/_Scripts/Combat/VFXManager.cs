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
            Object.Destroy(fx, .22f);
        }
    }
}
