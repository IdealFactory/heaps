package h3d.prim;

import hxd.fmt.gltf.Geometry;

class GltfModel extends MeshPrimitive {
	
	public var geom(default, null):Geometry;
	public var multiMaterial:Bool;

	var skin : h3d.anim.Skin;
	var tcount : Int = -1;
	var curMaterial : Int = -1;

	public function new( g ) {
		this.geom = g;
	}

	override public function triCount() : Int {
		if (tcount == -1) {
			tcount = 0;
			for ( prim in geom.root.primitives ) {
				tcount += Std.int(geom.l.root.accessors[prim.indices].count / 3);
			}
		}
		return tcount;
	}

	override public function vertexCount():Int
	{
		return triCount() * 3;
	}

	public function setSkin( skin : h3d.anim.Skin ) {
		skin.primitive = this;
		this.skin = skin;
	}

	override public function selectMaterial(material:Int)
	{
		curMaterial = material;
	}

	override public function alloc(engine:Engine)
	{
		dispose();
		

	}

}