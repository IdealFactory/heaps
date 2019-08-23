package hxd.fmt.gltf;

import haxe.io.Bytes;
import h3d.anim.Animation;
import h3d.prim.GltfModel;
import h3d.scene.Mesh;
import h3d.scene.Object;
import hxd.Pixels;
import hxd.fmt.gltf.Data;

class BaseLibrary {
	
	public var fileName:String;
	public var root:Gltf;
	public var buffers:Array<Bytes>;
    public var scenes:Array<h3d.scene.Object>;
    public var cameras:Array<h3d.Camera>;
    public var images:Array<hxd.res.Image>;
    public var materials:Array<h3d.mat.Material>;
    public var textures:Array<h3d.mat.Texture>;
	public var primitives:Map<Mesh, Array<GltfModel>>;
	public var meshes:Array<h3d.scene.Object>;

	public var currentScene:h3d.scene.Scene;
    var s3d : h3d.scene.Scene;

	public function new( fileName:String, root:Gltf, buffers:Array<Bytes>, s3d ) {
		this.s3d = s3d;

		load( fileName, root, buffers );
	}

	function load( fileName:String, root:Gltf, buffers:Array<Bytes> ) {
		
		reset();

		this.fileName = fileName;
		this.root = root;
		this.buffers = buffers;
	}

    public function dispose() {
        reset();

		root = null;
		fileName = "";
        buffers = null;
    }

    public function reset() {
        scenes = [];
        cameras = [];
        images = [];
        materials = [];
		textures = [];
        primitives = new Map<Mesh, Array<GltfModel>>();
		meshes = [];
    }

	function processURI( uri ) : hxd.fs.FileEntry {
		if ( StringTools.startsWith(uri, "data:") ) {
			var mimeType = uri.split(";")[0].substr(5);
			var data = uri.substr( uri.indexOf(",")+1 );
			trace("Process URI: Data URI:"+mimeType+"\ndat="+data.substr(0, 100)+"...");
			trace(" - "+haxe.CallStack.callStack());
			return new DataURIEntry( "no-name-image-"+images.length, uri, haxe.crypto.Base64.decode( data ) );
		} else {
			trace("Process URI: Loading URI:"+uri);
			return hxd.Res.load( uri ).entry;
		}
	}

    function loadBuffer( uri:String ) : haxe.io.Bytes {
        return hxd.Res.load( uri ).entry.getBytes();
    }

	function createCamera( cameraNode ) {
		
		var camera = new h3d.Camera();
		switch cameraNode.type {
			case CameraType.Orthographic:
				var orthoBounds = new h3d.col.Bounds();
				// TODO: Fix Orthographic camera
				// cameraNode.orthographic.xmag;
				// cameraNode.orthographic.ymag;
				camera.orthoBounds = orthoBounds;
				camera.zNear = cameraNode.orthographic.zfar;
				camera.zFar = cameraNode.orthographic.znear;
			case CameraType.Perspective:
				camera.fovY = cameraNode.perspective.aspectRatio;
				camera.screenRatio = cameraNode.perspective.yfov;
				camera.zNear = cameraNode.perspective.zfar;
				camera.zFar = cameraNode.perspective.znear;
		}
		return camera;
	} 

	function loadImage( imageNode ) {
		var entry;
		if (imageNode.uri != null) {
			entry = processURI( imageNode.uri );
		} else {
			var buf = GltfTools.getBufferBytes( this, imageNode.bufferView );
			entry = new DataURIEntry( "no-name-image-"+images.length, "no-uri", buf ); 
		}
		return new hxd.res.Image( entry );
	}

	function createMaterial( materialNode ) {
		if (materialNode == null) return h3d.mat.Material.create(h3d.mat.Texture.fromColor(0xFF808080));

		var material:h3d.mat.Material = null;
		var pbrValues = new h3d.shader.pbr.PropsValues();
		var pbrTexture:h3d.shader.pbr.PropsTexture = null;

		if ( materialNode.pbrMetallicRoughness != null ) {
			var pbrmr = materialNode.pbrMetallicRoughness;
			if ( pbrmr.baseColorTexture != null ) {
				var tex = getTexture(pbrmr.baseColorTexture.index);
				material = h3d.mat.Material.create( tex );
			}
			if ( pbrmr.baseColorFactor != null ) {
				var a:Float = pbrmr.baseColorFactor[3];
				var r:Float = pbrmr.baseColorFactor[0];
				var g:Float = pbrmr.baseColorFactor[1];
				var b:Float = pbrmr.baseColorFactor[2];

				var col = ( Std.int(a * 0xFF) << 24) | (Std.int(r * 0xFF) << 16) | (Std.int(g * 0xFF) << 8) | Std.int(b * 0xFF);
				if (material == null) material = h3d.mat.Material.create(h3d.mat.Texture.fromColor( col ));
				var color = new h3d.Vector(r, g, b);
				material.color.load(color);
				trace("CreatingColorMaterial:0x"+StringTools.hex(col, 8));
			}

			if (pbrmr.metallicRoughnessTexture != null) {

				if (pbrTexture == null) pbrTexture = new h3d.shader.pbr.PropsTexture();
				pbrTexture.texture = getTexture(pbrmr.metallicRoughnessTexture.index);
				
				pbrValues.metalness = Reflect.hasField(pbrmr, "metallicFactor") ? pbrmr.metallicFactor : 0.6;
				pbrValues.roughness = Reflect.hasField(pbrmr, "roughnessFactor") ? pbrmr.roughnessFactor : 0.3;
			}
		}

		if (material != null) {
			material.mainPass.addShader( pbrValues );
			if ( pbrTexture!=null ) material.mainPass.addShader( pbrTexture );

			if ( materialNode.normalTexture != null )
				material.normalMap = getTexture( materialNode.normalTexture.index, true );

		// TODO Implement RGB EmissiveFactor
		// if ( materialNode.emissiveFactor != null ) {
		// 	var eR:Float = materialNode.emissiveFactor[0];
		// 	var eG:Float = materialNode.emissiveFactor[1];
		// 	var eB:Float = materialNode.emissiveFactor[2];
		// 	pbrValues.emissive = ( eR + eG + eB ) / 3; // Currently average the RGB to a single float
		// }
		// TODO Implement Emissive Map 
		// if ( materialNode.emissiveTexture != null ) {
		// 	pbrTexture.hasEmissiveMap = true;
		// 	pbrTexture.emissiveMap = getTexture( materialNode.emissiveTexture.index );
		// }

		// TODO Implement Occlusion Map 
			if ( materialNode.occlusionTexture != null ) {
				pbrTexture.hasOcclusionMap = true;
				pbrTexture.occlusionMap = getTexture( materialNode.occlusionTexture.index );
			}

			if ( materialNode.name != null ) material.name = materialNode.name;
			if ( Reflect.hasField(materialNode, "doubleSided" )) material.mainPass.culling = materialNode.doubleSided ? None : Back;

			trace("Material:"+material.name+" m="+pbrValues.metalness+" r="+pbrValues.roughness+" o="+pbrValues.occlusion+" e="+pbrValues.emissive);

		} else trace("Material is NULL");

		return material;
	} 

	function getMaterial( matId ) {
		return materials[ matId ];
	}

	function applySampler( index : Int, mat : h3d.mat.Texture ) {
		var sampler = root.samplers[index];
		mat.filter = Nearest;
		mat.wrap = Clamp;
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

	function getTexture( index : Int, remapNormals = false ) : h3d.mat.Texture {
		var node = root.textures[index];
		var img = images[node.source]; // Pre-loaded image array

		var size = img.getSize();
		var format = h3d.mat.Texture.nativeFormat;
		var tex = new h3d.mat.Texture(size.width, size.height, [NoAlloc], format);

		tex.setName(img.entry.path);
		
		tex.alloc();
		var pixels = img.getPixels(tex.format);
		if( pixels.width != tex.width || pixels.height != tex.height )
			pixels.makeSquare();

		if (remapNormals) {
			// pixels.flipChannel( Channel.R );
			// pixels.flipChannel( Channel.G );
		}

		if ( Reflect.hasField(node, "sampler") ) 
			applySampler(node.sampler, tex);

		if (tex.mipMap!=None) tex.flags.set(MipMapped);

		tex.uploadPixels(pixels);
		pixels.dispose();

		return tex;
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
		var mat = getMaterial( prim.material );
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
			var bytes = buffers[view.buffer];
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

	public function loadMesh( index : Int, transform : h3d.Matrix, parent:h3d.scene.Object ) : h3d.scene.Object {
		var meshNode = root.meshes[ index ];
		if (meshNode == null) {trace("meshNode returned NULL for idx:"+index); return null; }

		// Create collection of primitives for this mesh
		if (!primitives.exists(meshNode)) primitives[meshNode] = [];

		var meshName = (meshNode.name != null) ? meshNode.name : StringTools.hex(Std.random(0xFFFFFFFF), 8);
		
		var mesh = new h3d.scene.Object( parent );
		mesh.name = meshName;
		mesh.setTransform( transform );
		meshes.push( mesh );
		trace("Create Mesh(Container):"+mesh.name+" parent:"+(parent.name == null ? Type.getClassName(Type.getClass(parent)) : parent.name)+" transform:"+transform);

		var primCounter = 0;
		for ( prim in meshNode.primitives ) {
			if ( prim.mode == null ) prim.mode = Triangles;

			// TODO: Modes other than triangles?
			if ( prim.mode != Triangles ) throw "Only triangles mode allowed in mesh primitive!";

			var meshPrim = new GltfModel( new Geometry(this, prim) );	
			primitives[meshNode].push( meshPrim );
			var mat = materials[ prim.material ];

			var primMesh = new h3d.scene.Mesh( meshPrim, mat, mesh );
			primMesh.name = meshName+"_"+primCounter++;
			trace(" - mesh primitive:"+primMesh.name);

			#if debug_gltf
			primMesh.material.mainPass.wireframe = true;
			
			var nm = new h3d.scene.Graphics(primMesh);
			var l = 0.0003;
			var l1 = l / 4;
			var v = new h3d.Vector();
			for (f in meshPrim.getFaces()) {
				nm.lineStyle(1, 0xFFFFFF);
				nm.moveTo( f.v0.x - l1, f.v0.y, f.v0.z );
				nm.lineTo( f.v0.x + l1, f.v0.y, f.v0.z );
				nm.moveTo( f.v0.x, f.v0.y - l1, f.v0.z );
				nm.lineTo( f.v0.x, f.v0.y + l1, f.v0.z );
				nm.moveTo( f.v0.x, f.v0.y, f.v0.z - l1 );
				nm.lineTo( f.v0.x, f.v0.y, f.v0.z + l1 );

				nm.moveTo( f.v1.x - l1, f.v1.y, f.v1.z );
				nm.lineTo( f.v1.x + l1, f.v1.y, f.v1.z );
				nm.moveTo( f.v1.x, f.v1.y - l1, f.v1.z );
				nm.lineTo( f.v1.x, f.v1.y + l1, f.v1.z );
				nm.moveTo( f.v1.x, f.v1.y, f.v1.z - l1 );
				nm.lineTo( f.v1.x, f.v1.y, f.v1.z + l1 );

				nm.moveTo( f.v2.x - l1, f.v2.y, f.v2.z );
				nm.lineTo( f.v2.x + l1, f.v2.y, f.v2.z );
				nm.moveTo( f.v2.x, f.v2.y - l1, f.v2.z );
				nm.lineTo( f.v2.x, f.v2.y + l1, f.v2.z );
				nm.moveTo( f.v2.x, f.v2.y, f.v2.z - l1 );
				nm.lineTo( f.v2.x, f.v2.y, f.v2.z + l1 );

				nm.lineStyle(1, 0xFF0000);
				v.set( f.n0.x, f.n0.y, f.n0.z );
				v.scale3( l );
				nm.moveTo( f.v0.x, f.v0.y, f.v0.z );
				nm.lineTo( f.v0.x + v.x, f.v0.y + v.y, f.v0.z + v.z );
				v.set( f.n1.x, f.n1.y, f.n1.z );
				v.scale3( l );
				nm.moveTo( f.v1.x, f.v1.y, f.v1.z );
				nm.lineTo( f.v1.x + v.x, f.v1.y + v.y, f.v1.z + v.z );
				v.set( f.n2.x, f.n2.y, f.n2.z );
				v.scale3( l );
				nm.moveTo( f.v2.x, f.v2.y, f.v2.z );
				nm.lineTo( f.v2.x + v.x, f.v2.y + v.y, f.v2.z + v.z );
			}

			nm.material.props = h3d.mat.MaterialSetup.current.getDefaults("ui");
			nm.material.mainPass.depthWrite = true;
			#end
		}
		return mesh;
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