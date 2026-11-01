using UnityEngine;
namespace LastCommand {
 public class SoldierVisual:MonoBehaviour {
  public void Build(Color uniform,Color equipment) {
   Renderer rootRenderer=GetComponent<Renderer>();if(rootRenderer!=null)rootRenderer.enabled=false;
   Part(PrimitiveType.Capsule,"Torso",new Vector3(0,.12f,0),new Vector3(.52f,.58f,.34f),uniform);
   Part(PrimitiveType.Sphere,"Head",new Vector3(0,.88f,0),new Vector3(.30f,.30f,.30f),new Color(.68f,.55f,.43f));
   Part(PrimitiveType.Cube,"Helmet",new Vector3(0,1.04f,0),new Vector3(.38f,.15f,.38f),equipment);
   Part(PrimitiveType.Capsule,"Left arm",new Vector3(-.34f,.20f,0),new Vector3(.19f,.43f,.19f),uniform);
   Part(PrimitiveType.Capsule,"Right arm",new Vector3(.34f,.20f,0),new Vector3(.19f,.43f,.19f),uniform);
   Part(PrimitiveType.Capsule,"Left leg",new Vector3(-.14f,-.48f,0),new Vector3(.20f,.48f,.20f),equipment);
   Part(PrimitiveType.Capsule,"Right leg",new Vector3(.14f,-.48f,0),new Vector3(.20f,.48f,.20f),equipment);
   Part(PrimitiveType.Cube,"Rifle",new Vector3(.39f,.04f,.30f),new Vector3(.10f,.10f,.72f),new Color(.10f,.12f,.10f));
  }
  private void Part(PrimitiveType type,string partName,Vector3 localPosition,Vector3 scale,Color color) {
   GameObject part=GameObject.CreatePrimitive(type);part.name=partName;part.transform.SetParent(transform,false);part.transform.localPosition=localPosition;part.transform.localScale=scale;
   Renderer r=part.GetComponent<Renderer>();r.material=GameBootstrap.Mat(color);Collider c=part.GetComponent<Collider>();if(c!=null)Destroy(c);
  }
 }
}