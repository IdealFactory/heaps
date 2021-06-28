package h3d.prim;

import hxd.fmt.gltf.Geometry;
import hxd.FloatBuffer;
import hxd.IndexBuffer;

class GltfModel extends MeshPrimitive {
	
	public var geom(default, null):Geometry;
	public var skin : h3d.anim.Skin;
	public var multiMaterial:Bool;
	public var name:String;

	var bounds : h3d.col.Bounds;
	var tcount : Int = -1;
	var curMaterial : Int = -1;
	var collider : h3d.col.Collider;
	var lib : hxd.fmt.gltf.BaseLibrary;

	public function new( g, lib ) {
		this.geom = g;
		this.lib = lib;
	}

	override public function triCount() : Int {
		return Std.int( geom.getIndices().length / 3 );
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

	override function getBounds() {
		if( bounds != null )
			return bounds;
		bounds = new h3d.col.Bounds();
		bounds.empty();
		var verts = geom.getVertices();
		// var gm = geom.getGeomMatrix();
		var tmp = new h3d.col.Point();
		bounds.xMin = bounds.yMin = bounds.zMin = Math.POSITIVE_INFINITY;
		bounds.xMax = bounds.yMax = bounds.zMax = Math.NEGATIVE_INFINITY;
		var pos = 0;
		while( pos < verts.length ) {
			var x = verts[pos++];
			var y = verts[pos++];
			var z = verts[pos++];
			// if( gm != null ) {
			// 	tmp.set(x, y, z);
			// 	tmp.transform(gm);
			// 	x = tmp.x;
			// 	y = tmp.y;
			// 	z = tmp.z;
			// }
			if( x > bounds.xMax ) bounds.xMax = x;
			if( x < bounds.xMin ) bounds.xMin = x;
			if( y > bounds.yMax ) bounds.yMax = y;
			if( y < bounds.yMin ) bounds.yMin = y;
			if( z > bounds.zMax ) bounds.zMax = z;
			if( z < bounds.zMin ) bounds.zMin = z;
		}
		return bounds;
	}

	override public function alloc(engine:Engine)
	{
		dispose();
		
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		var tangents = geom.getTangents();
		var idx = geom.getIndices();
		var uvs = geom.getUVs();
		var uv2s = geom.getUV2s(); //TODO: Implement 2nd UV coords

		addBuffer("position", h3d.Buffer.ofFloats(verts, 3));
		if( norms != null ) addBuffer("normal", h3d.Buffer.ofFloats(norms, 3));
		if( tangents != null ) addBuffer("tangent", h3d.Buffer.ofFloats(tangents, 4));
		addBuffer("uv", h3d.Buffer.ofFloats(uvs, 2));
		var moreThan64KVertices = verts.length>65535;
		indexes = h3d.Indexes.alloc(idx, 0, -1, moreThan64KVertices);
	}

	public function getFaces():Array<TriFace> {
		var verts = geom.getVertices();
		var norms = geom.getNormals();
		var tangents = geom.getTangents();
		var idx = geom.getIndices();
		var uvs = geom.getUVs();
		var uv2s = geom.getUV2s();

		var faces:Array<TriFace> = [];
		var i = 0;
		var v0 = new h3d.Vector();
		var v1 = new h3d.Vector();
		var v2 = new h3d.Vector();
		var n0 = new h3d.Vector();
		var n1 = new h3d.Vector();
		var n2 = new h3d.Vector();
		var uv0 = new h3d.Vector();
		var uv1 = new h3d.Vector();
		var uv2 = new h3d.Vector();

		while (i < idx.length) {
			var bI = idx[i] * 9;
			var cI = idx[i++] * 6;
			v0 = new Vector( verts[bI], verts[bI+1], verts[bI+2] );
			n0 = new Vector( norms[bI], norms[bI+1], norms[bI+2] );
			uv0 = new Vector( uvs[cI], uvs[cI+1] );
			
			bI = idx[i] * 9;
			cI = idx[i++] * 6;
			v1 = new Vector( verts[bI], verts[bI+1], verts[bI+2] );
			n1 = new Vector( norms[bI], norms[bI+1], norms[bI+2] );
			uv1 = new Vector( uvs[cI], uvs[cI+1] );

			bI = idx[i] * 9;
			cI = idx[i++] * 6;
			v2 = new Vector( verts[bI], verts[bI+1], verts[bI+2] );
			n2 = new Vector( norms[bI], norms[bI+1], norms[bI+2] );
			uv2 = new Vector( uvs[cI], uvs[cI+1] );

			faces.push( new TriFace( v0, v1, v2, n0 ,n1, n2, uv0, uv1, uv2 ) );
		}

		return faces;
	}

	override function render( engine : h3d.Engine ) {
		if( curMaterial < 0 ) {
			super.render(engine);
			return;
		}
		if( indexes == null || indexes.isDisposed() )
			alloc(engine);
		var idx = indexes;
		
		if( indexes != null ) super.render(engine);
		indexes = idx;
		curMaterial = -1;
	}

	function initCollider( poly : h3d.col.PolygonBuffer ) {
		#if neko
		var verts = haxe.ds.Vector.fromArrayCopy(geom.getVertices().getNative());
		var inds = haxe.ds.Vector.fromArrayCopy(geom.getIndices().getNative());
		#elseif flash
		var verts = haxe.ds.Vector.fromData(geom.getVertices().getNative());
		var i = geom.getIndices();
		var inds:haxe.ds.Vector<hxd.impl.UInt16> = new haxe.ds.Vector<hxd.impl.UInt16>(i.length);
		for (pos in 0...i.length)
			inds[pos] = i[pos];
		#else
		var verts = haxe.ds.Vector.fromData(geom.getVertices().getNative());
		var inds = haxe.ds.Vector.fromData(geom.getIndices().getNative());
		var uvs = haxe.ds.Vector.fromData(geom.getUVs().getNative());
		#end

		poly.setData(verts, inds, uvs);
		if( collider == null ) {
			collider = new h3d.col.Collider.OptimizedCollider(getBounds(), poly);
		}
	}

	override function getCollider() {
		if( collider != null )
			return collider;
		var poly = new h3d.col.PolygonBuffer();
		poly.source = {
			entry : null,
			geometryName : name,
		};
		initCollider(poly);
		return collider;
	}

}

class TriFace {
	public var v0:h3d.Vector;
	public var v1:h3d.Vector;
	public var v2:h3d.Vector;
	public var n0:h3d.Vector;
	public var n1:h3d.Vector;
	public var n2:h3d.Vector;
	public var uv0:h3d.Vector;
	public var uv1:h3d.Vector;
	public var uv2:h3d.Vector;

	public function new(v0, v1, v2, n0, n1, n2, uv0, uv1, uv2) { 
		this.v0 = v0;
		this.v1 = v1;
		this.v2 = v2;
		this.n0 = n0;
		this.n1 = n1;
		this.n2 = n2;
		this.uv0 = uv0;
		this.uv1 = uv1;
		this.uv2 = uv2;
	}
}