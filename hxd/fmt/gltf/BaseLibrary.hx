package hxd.fmt.gltf;

import haxe.io.Bytes;
//import h3d.anim.Animation;
import h3d.prim.GltfModel;
import h3d.scene.Mesh;
import h3d.scene.Object;
import hxd.Pixels;
import h3d.mat.Data;
import hxd.fmt.gltf.Data;

#if openfl
import openfl.display3D.Context3D;
import openfl.display3D._internal.Context3DState;

typedef LoadInfo = {
	var type:String;
	var totalBytes:Int;
	var bytesLoaded:Int;
}
#end

@:access(hxd.Window)
@:access(h3d.Engine)
@:access(h3d.impl.GlDriver)
class BaseLibrary #if openfl extends openfl.events.EventDispatcher #end {
	
	public var fileName:String;
	public var root:Gltf;
	public var buffers:Array<Bytes>;
    public var scenes:Array<h3d.scene.Object>;
    public var cameras:Array<h3d.Camera>;
    public var images:Array<hxd.BitmapData>;
    public var materials:Array<h3d.mat.PBRSinglePass>;
    public var textures:Array<h3d.mat.Texture>;
	public var primitives:Map<h3d.scene.Object, Array<h3d.scene.Mesh>>;
	public var meshes:Array<h3d.scene.Object>;
	public var animations:Array<h3d.anim.Animation>;
	public var nodeObjects:Array<h3d.scene.Object>;
	public var animator:TimelineAnimator = new TimelineAnimator();

	public var hasDracoExt:Bool = false;
	public var requiresDracoExt:Bool = false;

	public static var brdfTexture:h3d.mat.Texture;
	
	var s2d : h2d.Scene;
	var s3d : h3d.scene.Scene;
	public var baseURL:String = "";

	#if openfl
	var dependencyInfo:Map<openfl.net.URLLoader,LoadInfo>;
	var totalBytesToLoad = 0;
	#end

	public function new( s2d, ?s3d = null ) {
		#if openfl super(); #end
		this.s2d = s2d;
		this.s3d = s3d;
		
		reset();
	}

    public function dispose() {
        reset();

		root = null;
		fileName = "";
		baseURL = "";
        buffers = null;
    }

    public function reset() {
        scenes = [];
        cameras = [];
        images = [];
        materials = [];
		textures = [];
        primitives = new Map<h3d.scene.Object, Array<h3d.scene.Mesh>>();
		meshes = [];
		animations = [];
		nodeObjects = [];
		#if openfl
		dependencyInfo = new Map<openfl.net.URLLoader,BaseLibrary.LoadInfo>();
        #end
    }

    function loadBuffer( uri:String, bytesLoaded:Bytes->Array<Bytes>->Int->Void, bin:Array<Bytes>, idx:Int ) {
		var bytes:haxe.io.Bytes;
		#if debug_gltf
		trace("loadBuffer:uri="+uri+" idx="+idx);
		#end
		#if openfl
		if (baseURL!="" || uri.indexOf("http://")>-1 || uri.indexOf("https://")>-1) {
			if (baseURL!="" && uri.indexOf("http://")==-1) uri = baseURL + uri;
			requestURL( uri, function(e) {
				bytes = #if !flash cast( e.target, openfl.net.URLLoader).data #else Bytes.ofData( cast (e.target, openfl.net.URLLoader).data) #end;
        		bytesLoaded( bytes, bin, idx );
			} );
		} else {
			bytes = hxd.Res.load( uri ).entry.getBytes();
			bytesLoaded( bytes, bin, idx );
		}
		#else
        bytes = hxd.Res.load( uri ).entry.getBytes();
		bytesLoaded( bytes, bin, idx );
		#end
    }

	function loadImage( imageNode:Image, imgIdx, imageLoaded ) {
		var entry;
		if (imageNode.uri != null) {
			var uri = imageNode.uri;
			if ( StringTools.startsWith(uri, "data:") ) {
				// Data URI for image bytes
				var mimeType = uri.split(";")[0].substr(5);
				var imageBytes = haxe.crypto.Base64.decode( uri.substr( uri.indexOf(",")+1 ) );
				#if debug_gltf
				trace("LoadImage: Data URI:"+mimeType+"\ndat="+uri.substr( uri.indexOf(",")+1 ).substr(0, 100)+"...");
				#end
				#if (lime && js)
				images[ imgIdx ] = decodeJSImage( imageBytes, imageLoaded );
				#else 
				images[ imgIdx ] = new hxd.res.Image( new DataURIEntry( "no-name-image-"+images.length+"."+imageNode.mimeType.toString().split("/")[1], uri, imageBytes ) ).toBitmap();
				imageLoaded();
				#end
			#if openfl
			} else if (baseURL != "" || StringTools.startsWith(uri, "http://") || StringTools.startsWith(uri, "https://")) {
				// Remote URL request for image bytes (OpenFL only)
				if (baseURL != "" && !StringTools.startsWith(uri, "http")) uri = baseURL + uri;
				#if debug_gltf
				trace("LoadImage: Remote URI:"+uri);
				#end
				requestURL( uri, function(e) {
					var imageBytes = #if !flash cast( e.target, openfl.net.URLLoader).data #else Bytes.ofData( cast (e.target, openfl.net.URLLoader).data) #end;
					#if (lime && js)
					images[ imgIdx ] = decodeJSImage( imageBytes, imageLoaded );
					#else 
					images[ imgIdx ] = new hxd.res.Image( new DataURIEntry( uri.substr(uri.lastIndexOf("/")+1), uri, imageBytes ) ).toBitmap();
					imageLoaded();
					#end
				} );
			#end
			} else {
				// Local Heaps Resource image
				#if debug_gltf
				trace("LoadImage: Loading URI:"+uri);
				#end
				#if (lime && js)
				var imageBytes = hxd.Res.load( uri ).entry.getBytes();
				images[ imgIdx ] = decodeJSImage( imageBytes, imageLoaded );
				#else 
				images[ imgIdx ] = cast hxd.Res.load( uri ).toImage().toBitmap();
				imageLoaded();
				#end
			}
		} else {
			// Binary buffer for image
			var imageBytes = GltfTools.getBufferBytes( this, imageNode.bufferView );
			#if debug_gltf
			trace("LoadImage: from buffer view:"+imageNode.bufferView);
			#end
			#if (lime && js)
			images[ imgIdx ] = decodeJSImage( imageBytes, imageLoaded );
			#else 
			entry = new DataURIEntry( "no-name-image-"+images.length+"."+imageNode.mimeType.toString().split("/")[1], "no-uri", imageBytes ); 
			images[ imgIdx ] = new hxd.res.Image( entry ).toBitmap();
			imageLoaded();
			#end
		}
	}

	#if (lime && js)
	function decodeJSImage( imageBytes:haxe.io.Bytes, imageLoaded ) {
		var mimeType = "";
		var header = imageBytes.getUInt16(0);
		switch( header ) {
			case 0xD8FF: mimeType = "image/jpeg";
			case 0x5089: mimeType = "image/png";
			case 0x4947: mimeType = "image/gif";
			case 0x4444: mimeType = "image/vnd-ms.dds";
			default: mimeType = "image/tga";
		}

		var b = new BitmapData( -101, -102 );
		@:privateAccess b.data = new lime.graphics.Image(null, 0, 0, 1, 1);
		var imgElement = new js.html.Image();
		@:privateAccess var blob = new js.html.Blob( [ imageBytes.b ], { type: mimeType } );
		@:privateAccess imgElement.src = js.html.URL.createObjectURL( blob );
		imgElement.onload = function() { 
			for (img in images)
				@:privateAccess if (img!=null && img.data.buffer.__srcImage == imgElement) {
				@:privateAccess img.data = lime.graphics.Image.fromImageElement( imgElement );
				@:privateAccess lime._internal.graphics.ImageCanvasUtil.convertToCanvas(b.data);
			
				@:privateAccess 	img.data.width = imgElement.width; 
				@:privateAccess 	img.data.height = imgElement.height; 
								}
			imageLoaded();
		};

		@:privateAccess b.data.buffer.__srcImage = imgElement;
		return b;
	}
	#end

 	#if openfl
    function requestURL( url:String, onComplete:openfl.events.Event->Void ) {
		trace("requestURL:"+url);
        var request = new openfl.net.URLRequest( url );
        var loader = new openfl.net.URLLoader();
        loader.dataFormat = openfl.net.URLLoaderDataFormat.BINARY;
		var ext = url.substr( url.lastIndexOf(".")+1 );
		dependencyInfo[ loader ] = { type:ext, totalBytes: -1, bytesLoaded: 0};

        loader.addEventListener( openfl.events.Event.COMPLETE, function(e) {
			loader = null;
			onComplete(e);
		});
        loader.addEventListener( openfl.events.Event.OPEN, function(e) trace("requestURL.OPEN:"+e) );
        loader.addEventListener( openfl.events.ProgressEvent.PROGRESS, onProgress );
        loader.addEventListener( openfl.events.SecurityErrorEvent.SECURITY_ERROR, function(e) trace("requestURL.SECURITY_ERROR:"+e) );
        loader.addEventListener( openfl.events.HTTPStatusEvent.HTTP_STATUS, function(e) trace("requestURL.HTTP_STATUS:"+e) );
        loader.addEventListener( openfl.events.IOErrorEvent.IO_ERROR, function(e) trace("requestURL.IOErrorEvent:"+e) );
        loader.load( request );
    }

	function onProgress( pe:openfl.events.ProgressEvent ) {
		
		pe.stopPropagation();
		var info = dependencyInfo[pe.target];
		if ( info != null) {
			if (info.totalBytes==-1 ) {
				info.totalBytes = Std.int(pe.bytesTotal);
				totalBytesToLoad = 0; 
				for (i in dependencyInfo) {
					totalBytesToLoad += i.totalBytes;
				}
			}

			info.bytesLoaded = Std.int(pe.bytesLoaded);
		}

		var progressSoFar = 0;
		var currentTotal = 0;
		for (i in dependencyInfo) {
			progressSoFar = i.bytesLoaded;
			currentTotal = i.totalBytes;
		}
		dispatchEvent(new openfl.events.ProgressEvent(openfl.events.ProgressEvent.PROGRESS, false, false, progressSoFar, currentTotal));
	}
	#end

	function createCamera( cameraNode ) {
		
		var camera = new h3d.Camera();
		camera.rightHanded = true;
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

	function createMaterial( materialNode ) {
		var material = new h3d.mat.PBRSinglePass();
		material.mainPass.culling = Front;
		// material.environmentBRDF = brdfTexture;
		// material.output.debug = true;

		if (materialNode == null) {
			material.texture = h3d.mat.Texture.fromColor(0xFF808080);
			return material;
		}

		if ( materialNode.name != null ) {
			material.name = materialNode.name;
		}
		
		if ( materialNode.pbrMetallicRoughness != null ) {
			var pbrmr = materialNode.pbrMetallicRoughness;
			var tex:h3d.mat.Texture = null;

			if ( pbrmr.baseColorTexture != null ) {
				tex = getTexture(pbrmr.baseColorTexture.index);
				material.texture = tex;

				//TODO: Alpha mode is still not quite working
				if ( materialNode.alphaMode == MaterialAlphaMode.Blend || materialNode.alphaMode == MaterialAlphaMode.Mask) {
					material.uv1.hasAlpha = 1;
					material.blendMode = Alpha;
					if (materialNode.alphaMode == MaterialAlphaMode.Mask)
						material.uv1.alphaCutoff = Reflect.hasField(materialNode, "alphaCutoff") ? materialNode.alphaCutoff : 0.5;
				}
			}

			var a:Float, r:Float, g:Float, b:Float;
			a = r = g = b = 1;
			if ( pbrmr.baseColorFactor != null ) {
				a = pbrmr.baseColorFactor[3];
				r = pbrmr.baseColorFactor[0];
				g = pbrmr.baseColorFactor[1];
				b = pbrmr.baseColorFactor[2];
			}

			material.setColorRGBA( r, g, b, a );

			#if debug_gltf
			trace("BaseColor:RGBA"+r+", "+g+", "+b+", "+a);
			#end

			if (pbrmr.metallicRoughnessTexture != null) {
				material.reflectivityMap = getTexture(pbrmr.metallicRoughnessTexture.index);
			}

			material.metalnessFactor = Reflect.hasField(pbrmr, "metallicFactor") ? pbrmr.metallicFactor : 1;
			material.roughnessFactor = Reflect.hasField(pbrmr, "roughnessFactor") ? pbrmr.roughnessFactor : 1;
			#if debug_gltf
			trace("MATERIAL:setting m/r factors: "+material.metalnessFactor+"/"+material.roughnessFactor);
			#end
		}


		if ( materialNode.normalTexture != null ) {
			material.normalMap = getTexture( materialNode.normalTexture.index );
		}

		var emit = new h3d.Vector();
		if ( materialNode.emissiveFactor != null ) {
			emit.r = materialNode.emissiveFactor[0];
			emit.g = materialNode.emissiveFactor[1];
			emit.b = materialNode.emissiveFactor[2];
		} 
		//TODO-REMOVED FOR WEBGL1 INTEGRATION
		// pbrValues.emissive.set( emit.r, emit.g, emit.b );

		if ( materialNode.emissiveTexture != null ) {
			material.emissiveLightMap = getTexture( materialNode.emissiveTexture.index );
		}

		if ( materialNode.occlusionTexture != null ) {
			material.occlusionMap = getTexture( materialNode.occlusionTexture.index );
		}

		if ( Reflect.hasField(materialNode, "doubleSided" )) {
			material.mainPass.culling = materialNode.doubleSided ? None : Front;
		}

		if (materialNode.extensions != null) addMaterialExtensions(materialNode, material);

		if (material.texture == null) {
			h3d.mat.Texture.fromColor(0xFF808080);
		}
		return material;
	} 

	function addMaterialExtensions( materialNode, material ) {
		var exts:Array<Dynamic> = cast materialNode.extensions;
		
		// Clearcoat
		if (Reflect.hasField( materialNode.extensions, "KHR_materials_clearcoat")) {
			var cc:MaterialClearCoatExt = cast materialNode.extensions.KHR_materials_clearcoat;
			var ccFactor = (cc.clearcoatFactor == null ? 1. : cc.clearcoatFactor);
			var ccRoughnessFactor = (cc.clearcoatRoughnessFactor == null ? 0. : cc.clearcoatRoughnessFactor);
			var ccTex = (cc.clearcoatTexture != null ? getTexture( cc.clearcoatTexture.index ) : null);
			var ccRoughTex = (cc.clearcoatRoughnessTexture != null ? getTexture( cc.clearcoatRoughnessTexture.index ) : null);
			var ccNormalTex = (cc.clearcoatNormalTexture != null ? getTexture( cc.clearcoatNormalTexture.index ) : null);
			material.addClearCoat( ccFactor, ccRoughnessFactor, ccTex, ccRoughTex, ccNormalTex );
			#if debug_gltf
			trace( "ClearCoatExt: ccF="+ccFactor+" ccRF="+ccRoughnessFactor);
			#end
		}

		// Sheen
		if (Reflect.hasField( materialNode.extensions, "KHR_materials_sheen")) {
			var sheen:MaterialSheenExt = cast materialNode.extensions.KHR_materials_sheen;
			var sheenColorFactor = (sheen.sheenColorFactor == null ? [1., 1., 1.] : [ sheen.sheenColorFactor[0], sheen.sheenColorFactor[1], sheen.sheenColorFactor[2] ]);
			var sheenIntensity = (sheen.sheenColorFactor == null || sheen.sheenColorFactor.length < 4 ? 1. : sheen.sheenColorFactor[3]);
			var sheenRoughnessFactor = (sheen.sheenRoughnessFactor == null ? 0. : sheen.sheenRoughnessFactor);
			var sheenTex = (sheen.sheenTexture != null ? getTexture( sheen.sheenTexture.index ) : null);
			material.addSheen( sheenColorFactor, sheenIntensity, sheenRoughnessFactor, sheenTex );
			#if debug_gltf
			trace( "SheenExt: mat:"+material.name+" sheenCol="+sheenColorFactor+" sheenIntensity:"+sheenIntensity+" sheenRF="+sheenRoughnessFactor);
			#end
		}
	}

	function addPrimitiveExtensions( primitiveNode, material ) {
		// Draco mesh compression
		if (Reflect.hasField( primitiveNode.extensions, "KHR_draco_mesh_compression")) {
			var draco:DracoMeshCompressionExt = cast primitiveNode.extensions.KHR_draco_mesh_compression;
			#if debug_gltf
			trace( "DracoMeshCompressionExt:");
			#end
		}

	}

	function createAnimations( animationNode:Animation ) {
		
		if (animationNode.channels == null || animationNode.samplers == null) return null;
		
		var anims = new Map<Int, h3d.anim.TimelineLinearAnimation>();

		for (channel in animationNode.channels) {
			var o = nodeObjects[ channel.target.node ];
			var path = channel.target.path;
			var sampler =  animationNode.samplers[ channel.sampler ];
			#if debug_gltf
			trace("Animation.channel: target:"+channel.target.node+" o:"+(o!=null ? o.name : "null")+" path:"+path);
			trace("Animation.sampler: input:"+sampler.input+" output:"+sampler.output+" inter:"+sampler.interpolation);
			#end
			
			var keyFrames = GltfTools.getAnimationScalarFloatBufferByAccessor( this, sampler.input );
			
			var translationData = path==AnimationPath.Translation ? GltfTools.getAnimationFloatArrayBufferByAccessor( this, sampler.output ) : null;
			var rotationData = path==AnimationPath.Rotation ? GltfTools.getAnimationFloatArrayBufferByAccessor( this, sampler.output ) : null;
			var scaleData = path==AnimationPath.Scale ? GltfTools.getAnimationFloatArrayBufferByAccessor( this, sampler.output ) : null;
			var weightsData = path==AnimationPath.Weights ?  GltfTools.getAnimationScalarFloatBufferByAccessor( this, sampler.output ) : null;

			#if debug_gltf
			var times = "";
			for (k in keyFrames) times += k+", ";
			trace("Keyframes:"+times);
			if (translationData!=null) {
				var times = "Translation:";
				for (k in translationData) times += k+", ";
				trace(times);
			}
			if (rotationData!=null) {
				var times = "Rotation:";
				for (k in rotationData) times += k+", ";
				trace(times);
			}
			if (scaleData!=null) {
				var times = "Scale:";
				for (k in scaleData) times += k+", ";
				trace(times);
			}
			if (weightsData!=null) {
				var times = "Weights:";
				for (k in weightsData) times += k+", ";
				trace(times);
			}
			#end


			var frameCount = keyFrames.length;
			var anim = anims.exists(channel.target.node) ? anims[channel.target.node] : new h3d.anim.TimelineLinearAnimation("anim1", frameCount, keyFrames[keyFrames.length - 1]);
			@:privateAccess if (keyFrames[keyFrames.length - 1] > anim.totalDuration) anim.totalDuration = keyFrames[keyFrames.length - 1];
			@:privateAccess trace("Anim["+channel.target.node+"].totalDuration="+anim.totalDuration);
			var frames = new haxe.ds.Vector<h3d.anim.TimelineLinearAnimation.TimelineLinearFrame>(frameCount);
			for( i in 0...frameCount ) {
				var f = new h3d.anim.TimelineLinearAnimation.TimelineLinearFrame();
				f.keyTime = keyFrames[i];
				if( translationData!=null ) {
					f.tx = translationData[i][0];
					f.ty = translationData[i][1];
					f.tz = translationData[i][2];
				} else {
					f.tx = 0;
					f.ty = 0;
					f.tz = 0;
				}
				if( rotationData!=null ) {
					f.qx = rotationData[i][0];
					f.qy = rotationData[i][1];
					f.qz = rotationData[i][2];
					f.qw = rotationData[i][3];
				} else {
					f.qx = 0;
					f.qy = 0;
					f.qz = 0;
					f.qw = 1;
				}
				if( scaleData!=null ) {
					f.sx = scaleData[i][0];
					f.sy = scaleData[i][1];
					f.sz = scaleData[i][2];
				} else {
					f.sx = 1;
					f.sy = 1;
					f.sz = 1;
				}
				frames[i] = f;
			}
			anim.addCurve(o.name, frames, false, true, false);

			animations.push( anim );

			animator.addAnimtion( o, anim );
		}
			

		return null;//animation;
	}

	function applySampler( index : Null<Int>, mat : h3d.mat.Texture ) {
		
		if (index == null) {
			mat.mipMap = Linear;
			mat.filter = Linear;
			mat.wrap = Repeat;
			return;
		}

		var sampler = root.samplers[index];
		mat.mipMap = Linear;
		mat.filter = Linear;
		mat.wrap = Repeat;
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
		// TODO: Wrap separately - wrapS, wrapT
		if ( sampler.wrapS != null ) {
			switch ( sampler.wrapS ) {
				case ClampToEdge: mat.wrap = Clamp;
				case MirroredRepeat: throw "Mirrored Repeat not supported!";
				case Repeat: mat.wrap = Repeat;
				default: "Unsupported sampler wrapS!";
			}
		}
	}

	function getTexture( index : Int ) : h3d.mat.Texture {
		var node = root.textures[index];
		var img = images[node.source]; // Pre-loaded image array

		#if debug_gltf
		trace("GLTF.getTexture: node="+node+" src:"+node.source);
		#end 

		// var format = h3d.mat.TextureFormat.RGBA;
		var format = h3d.mat.Texture.nativeFormat;
		var tex = new h3d.mat.Texture(img.width, img.height, [NoAlloc], format);

		tex.setName(node.name==null ? "texture-"+index : node.name);
		
		tex.alloc();

		// if ( Reflect.hasField(node, "sampler") ) 
		applySampler(node.sampler, tex);

		if (tex.mipMap!=None) tex.flags.set(MipMapped);


		#if debug_gltf
		@:privateAccess trace("GLTF.applySampler: mipmap:"+tex.mipMap+" filter:"+tex.filter+" wrap:"+tex.wrap+" fmt=0x"+StringTools.hex(cast(img.data, lime.graphics.Image).format));
		#end 

		tex.uploadBitmap( img );
		// openfl.display.HeapsContainer.addBmd(img); // Debugging

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

	public function loadMesh( index : Int, transform : h3d.Matrix, parent:h3d.scene.Object, nodeName:String = null ) : h3d.scene.Object {
		var meshNode = root.meshes[ index ];
		if (meshNode == null) {trace("meshNode returned NULL for idx:"+index); return null; }

		var meshName = (meshNode.name != null) ? meshNode.name : (nodeName != null ? nodeName : "Mesh_"+StringTools.hex(Std.random(0x7FFFFFFF), 8));
		
		var mesh = new h3d.scene.Object( parent );
		mesh.name = meshName;
		mesh.setTransform( transform );
		meshes.push( mesh );
		#if debug_gltf
		trace("Create Mesh(Container):"+mesh.name+" parent:"+(parent.name == null ? Type.getClassName(Type.getClass(parent)) : parent.name)+" transform:"+transform);
		#end

		// Create collection of primitives for this mesh
		if (!primitives.exists(mesh)) primitives[mesh] = [];

		var primCounter = 0;
		for ( prim in meshNode.primitives ) {
			if ( prim.mode == null ) prim.mode = Triangles;

			// TODO: Modes other than triangles?
			if ( prim.mode != Triangles ) throw "Only triangles mode allowed in mesh primitive!";

			var primName = meshName+"_"+primCounter++;

			var meshPrim = new GltfModel( new Geometry(this, prim, hasDracoExt, requiresDracoExt ), this );
			meshPrim.name = primName;

			var mat = materials[ prim.material ];
			mat.hasTangentBuffer = meshPrim.geom.hasTangentBuffer;

			var primMesh = new h3d.scene.Mesh( meshPrim, mat, mesh );
			primMesh.name = primName;
			primitives[mesh].push( primMesh );
			
			#if debug_gltf
			trace("LoadMesh:meshPrim:"+meshPrim.name+" TriCount="+meshPrim.triCount());	
			trace(" - got material: hasTangentBuffer="+mat.hasTangentBuffer);
			trace(" - mesh primitive:"+primMesh.name);
			#end

			// var b = meshPrim.getBounds().clone();
			// var mat = primMesh.getAbsPos();
			// b.transform( mat );
			// trace("GLTFBounds:"+primName+" B:"+b);

			#if debug_gltf_normals
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

	//TODO: Implement glTF animations
	// function getAnimation( name : String ) {
	// 	for ( a in root.animations )
	// 		if ( a.name == name )
	// 			return a;
	// 	return null;
	// }

	// public function loadAnimation( name : String ) : h3d.anim.Animation {
	// 	var anim = getAnimation(name);
	// 	// var a = new h3d.anim.Animation(name, );

	// 	return null;
	// }

	// public function getAnimationNames() : Array<String> {
	// 	return [for ( a in root.animations ) a.name];
	// }
}