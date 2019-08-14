package hxd.fmt.gltf;

import haxe.io.Bytes;
import h3d.anim.Animation;
import hxd.fmt.gltf.Data;

class BaseLibrary {
	
	public var fileName:String;
	public var root:Gltf;
	public var buffers:Map<String, Bytes>;

	public function new( fileName:String, root:Gltf, buffers:Map<String, Bytes> ) {

		this.fileName = fileName;
		this.root = root;
		this.buffers = buffers;

	}

	function applySampler( index : Int, mat : h3d.mat.Texture ) {
		var sampler = root.samplers[index];
		// TODO: mag/min filter separately
		if ( sampler.minFilter != null ) {
			switch ( sampler.minFilter ) {
				case Nearest: mat.filter = Nearest;
				case Linear: mat.filter = Linear;
				case NearestMipmapLinear:
					mat.mipMap = Nearest;
					mat.filter = Linear;
				case NearestMipmapNearest:
					mat.mipMap = Nearest;
					mat.filter = Nearest;
				case  LinearMipmapLinear:
					mat.mipMap = Linear;
					mat.filter = Linear;
				case LinearMipmapNearest:
					mat.mipMap = Linear;
					mat.filter = Nearest;
				default: throw "Unsupported magFilter value!";
			}
		}
		// TODO: Wrap separately
		if ( sampler.wrapS != null ) {
			switch ( sampler.wrapS ) {
				case ClampToEdge: mat.wrap = Clamp;
				case MirroredRepeat: throw "Mirrored Repeat not supported!";
				case Repeat: mat.wrap = Repeat;
				default: "Unsupported sampler wrapS!";
			}
		}
	}

	function getTexture( index : Int, loadTexture : String->h3d.mat.Texture ) : h3d.mat.Texture {
		var node = root.textures[index];
		var img = root.images[node.source];
		var tex : h3d.mat.Texture;
		if ( img.bufferView != null ) throw "TODO: Gltf Texture from buffers";
		else {
			tex = loadTexture(img.uri);
		}
		if ( tex == null ) tex = h3d.mat.Texture.fromColor(0xff0000);
		applySampler(node.sampler, tex);
		return tex;
	}

	function loadMaterial( index : Int, loadTexture : String->h3d.mat.Texture ) : h3d.mat.Material {
		var node = root.materials[index];
		if (node == null) return null;

		var mat = h3d.mat.Material.create();
		if ( node.name != null ) mat.name = node.name;
		if ( node.pbrMetallicRoughness != null ) {
			var pbrmr = node.pbrMetallicRoughness;
			if ( pbrmr.baseColorTexture != null ) {
				mat.texture = getTexture(pbrmr.baseColorTexture.index, loadTexture);
				// TODO: texCoord
			}
			// metallicRoughnessTexture
			// baseColorFactor
			// metallicFactor
			// metallicFactor
			// roughtnessFactor
		}
		if ( node.normalTexture != null ) {
			// TODO: Scale
			mat.normalMap = getTexture(node.normalTexture.index, loadTexture);
		}
		// occlusionTexture
		// emissiveTexture
		// emissiveFactor

		return mat;
	}

	static final STRIDES:Map<AccessorType, Int> = [
		Scalar => 1,
		Vec2 => 2,
		Vec3 => 3,
		Vec4 => 4,
		Mat2 => 4,
		Mat3 => 9,
		Mat4 => 16
	];

	static final ATTRIBUTE_OFFSETS:Map<String, Int> = [
		"POSITION" => 0,
		"NORMAL" => 3,
		"TEXCOORD_0" => 6,
		// "TANGENT" => 8,
		// "TEXCOORD_1" =>
	];

	@:access(h3d.prim.MeshPrimitive)
	function loadPrimitive( prim : MeshPrimitive, loadTexture : String->h3d.mat.Texture ) {
		if (prim.mode == null) prim.mode = Triangles;
		// TODO: Modes other than triangles?
		if ( prim.mode != Triangles ) throw "Only triangles mode allowed in mesh primitive!";
		var mat = loadMaterial(prim.material, loadTexture);
		var stride:Int = 0;
		var vcount:Int = -1;
		var attrs = prim.attributes.keys();

		var baseFlags : Array<h3d.Buffer.BufferFlag> = [RawFormat];
		if (prim.indices == null) throw "Primitives without indexes are not supported!"; // TODO

		for ( attr in attrs ) {
			var accessor = root.accessors[prim.attributes.get(attr)];
			// TODO: Sparce accessor, non-float accessors
			if (accessor.sparce != null) throw "Sparse accessors not supported!";
			if (accessor.componentType != CTFloat) throw "Primitive attributes should be of type Float!";
			var view = root.bufferViews[accessor.bufferView];
			var buf = root.buffers[view.buffer];
			var bytes = buffers[buf.uri];
			var attrBuf = new h3d.Buffer(accessor.count, view.byteStride >> 2, baseFlags);
			// mprim.addBuffer("123", accessor.byteOffset)
			// attrBuf.uploadBytes(buffers[buf.uri], accessor.byteOffset)
		}

		// var accessors:Array<Accessor>;
		// for (attr in attrs) {
		// 	var accessor = root.accessors[prim.attributes.get(attr)];
		// 	accessors.push(accessor);
		// 	if (accessor.sparce != null) throw "Sparse accessors not supported!";
		// 	if (accessor.componentType != CTFloat) throw "Primitive attributes should be of type Float!";
		// 	if (vcount == -1) vcount = accessor.count;
		// 	else if (vcount != accessor.count) throw "Vertex data count mismatch!";
		// 	stride += STRIDES[accessor.type];
		// }
		// var stride = 8;
		
		// for (i in 0...attrs.length)
		// {
		// 	var offset = ATTRIBUTE_OFFSETS[attrs[i]];
		// 	var accessor = accessors[i];
		// 	var size = STRIDES[accessor.type];
		// 	if ( offset == null ) {
		// 		offset = stride;
		// 		stride += size;
		// 	}
		// 	for (k in 0...vcount)
		// 	{
				
		// 	}
		// }
		// var idxAcc = root.accessors[prim.indices]
	}

	public function loadMesh( index : Int, loadTexture : String->h3d.mat.Texture ) : h3d.scene.Mesh {
		var node = root.meshes[index];
		if (node == null) return null;
		// TODO: Multiple primitives
		if (node.primitives.length != 1) throw "Only one primitive allowed per mesh!";

		var materials:Map<GltfId, h3d.mat.Material> = new Map();
		var geom = new Geometry(this, node);
		for ( prim in node.primitives ) {
			if ( materials.get(prim.material) == null ) {
				materials.set(prim.material, loadMaterial(prim.material, loadTexture));
			}
		}
		

		return null;
	}

	public function loadModel() : h3d.scene.Object {

		return null;

	}

	function getAnimation( name : String ) {
		for ( a in root.animations )
			if ( a.name == name )
				return a;
		return null;
	}

	public function loadAnimation( name : String ) : h3d.anim.Animation {
		var anim = getAnimation(name);
		// var a = new h3d.anim.Animation(name, );

		return null;
	}

	public function getAnimationNames() : Array<String> {
		return [for ( a in root.animations ) a.name];
	}

}