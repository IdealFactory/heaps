package hxd.fmt.gltf;

import haxe.io.Bytes;
//import h3d.anim.Animation;
import h3d.prim.GltfModel;
import h3d.scene.Mesh;
import h3d.scene.Object;
import h3d.Matrix;
import hxd.Pixels;
import hxd.fmt.gltf.Data;

#if openfl
typedef LoadInfo = {
	var type:String;
	var totalBytes:Int;
	var bytesLoaded:Int;
}
#end

typedef SkinMeshLink = {
	var nodeId:Int;
	var skinId:Int;
	var skinMesh:h3d.scene.Skin;
}

class BaseLibrary #if openfl extends openfl.events.EventDispatcher #end {
	
	public var fileName:String;
	public var root:Gltf;
	public var buffers:Array<Bytes>;
    public var scenes:Array<h3d.scene.Object>;
    public var cameras:Array<h3d.Camera>;
    public var images:Array<hxd.res.Image>;
    public var materials:Array<h3d.mat.Material>;
    public var textures:Array<h3d.mat.Texture>;
	public var primitives:Map<h3d.scene.Object, Array<h3d.scene.Mesh>>;
	public var meshes:Array<h3d.scene.Object>;
	public var animations:Array<h3d.anim.Animation>;
	public var meshJoints:Map<h3d.scene.Object, Array<Int>>;
	public var jointMesh:Array<h3d.scene.Skin>;
	public var currentScene:h3d.scene.Scene;
	public var nodeObjects:Array<h3d.scene.Object>;
	public var animator:TimelineAnimator = new TimelineAnimator();

	var anims = new Map<Int, h3d.anim.TimelineLinearAnimation>();
	var animId = 0;
	var s3d : h3d.scene.Scene;
	var baseURL:String = "";
	var skinMeshes:Array<SkinMeshLink>;

	var debugPrim:h3d.prim.Sphere;
	var defaultMaterial:h3d.mat.Material;

	#if openfl
	var dependencyInfo:Map<openfl.net.URLLoader,LoadInfo>;
	var totalBytesToLoad = 0;
	#end

	public function new( s3d ) {
		#if openfl super(); #end
		this.s3d = s3d;

        // DEBUGGING PRIMITIVE TO HIGHLIGHT JOINT LOCATIONS
        if (debugPrim == null) {
            debugPrim = new h3d.prim.Sphere();
            debugPrim.scale( 0.05 );
            debugPrim.addUVs();
            debugPrim.addNormals();
        }

		// Create default material for objects that do not have one
		if (defaultMaterial == null)
			defaultMaterial = h3d.mat.Material.create(h3d.mat.Texture.fromColor(0xFF888888));

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
		meshJoints = [];
		jointMesh = [];
		nodeObjects = [];

		anims = [];
		skinMeshes = [];
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

	function loadImage( imageNode, imgIdx, imageLoaded ) {
		var entry;
		if (imageNode.uri != null) {
			var uri = imageNode.uri;
			if ( StringTools.startsWith(uri, "data:") ) {
				// Data URI for image bytes
				var mimeType = uri.split(";")[0].substr(5);
				var data = uri.substr( uri.indexOf(",")+1 );
				#if debug_gltf
				trace("LoadImage: Data URI:"+mimeType+"\ndat="+data.substr(0, 100)+"...");
				#end
				images[ imgIdx ] = new hxd.res.Image( new DataURIEntry( "no-name-image-"+images.length, uri, haxe.crypto.Base64.decode( data ) ) );
				imageLoaded();
			#if openfl
			} else if (baseURL != "" || StringTools.startsWith(uri, "http://") || StringTools.startsWith(uri, "https://")) {
				// Remote URL request for image bytes (OpenFL only)
				if (baseURL != "" && !StringTools.startsWith(uri, "http")) uri = baseURL + uri;
				#if debug_gltf
				trace("LoadImage: Remote URI:"+uri);
				#end
				requestURL( uri, function(e) {
					var bytes = #if !flash cast( e.target, openfl.net.URLLoader).data #else Bytes.ofData( cast (e.target, openfl.net.URLLoader).data) #end;
					images[ imgIdx ] = new hxd.res.Image( new DataURIEntry( uri.substr(uri.lastIndexOf("/")+1), uri, bytes ) );
					imageLoaded();
				} );
			#end
			} else {
				// Local Heaps Resource image
				#if debug_gltf
				trace("LoadImage: Loading URI:"+uri);
				#end
				images[ imgIdx ] = cast hxd.Res.load( uri ).toImage();
				imageLoaded();
			}
		} else {
			// Binary buffer for image
			var buf = GltfTools.getBufferBytes( this, imageNode.bufferView );
			#if debug_gltf
			trace("LoadImage: from buffer view:"+imageNode.bufferView);
			#end
			entry = new DataURIEntry( "no-name-image-"+images.length, "no-uri", buf ); 
			images[ imgIdx ] = new hxd.res.Image( entry );
			imageLoaded();
		}
	}

 	#if openfl
    function requestURL( url:String, onComplete:openfl.events.Event->Void ) {
        var request = new openfl.net.URLRequest( url );
        var loader = new openfl.net.URLLoader();
        loader.dataFormat = openfl.net.URLLoaderDataFormat.BINARY;
		var ext = url.substr( url.lastIndexOf(".")+1 );
		dependencyInfo[ loader ] = { type:ext, totalBytes: -1, bytesLoaded: 0};

        loader.addEventListener( openfl.events.Event.COMPLETE, onComplete );
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
		if ( info.totalBytes==-1 ) {
			info.totalBytes = Std.int(pe.bytesTotal);
			totalBytesToLoad = 0; 
			for (i in dependencyInfo) {
				totalBytesToLoad += i.totalBytes;
			}
		}

		info.bytesLoaded = Std.int(pe.bytesLoaded);

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
		if (materialNode == null) return h3d.mat.Material.create(h3d.mat.Texture.fromColor(0xFF808080));

		var material:h3d.mat.Material = null;
		var pbrValues:h3d.shader.pbr.PropsValues = null;
		var pbrTexture:h3d.shader.pbr.PropsTexture = null;

		if ( materialNode.pbrMetallicRoughness != null ) {
			var pbrmr = materialNode.pbrMetallicRoughness;
			if ( pbrmr.baseColorTexture != null ) {
				var tex = getTexture(pbrmr.baseColorTexture.index);
				material = h3d.mat.Material.create( tex );
			}

			var a:Float, r:Float, g:Float, b:Float;
			a = r = g = b = 1;
			if ( pbrmr.baseColorFactor != null ) {
				a = pbrmr.baseColorFactor[3];
				r = pbrmr.baseColorFactor[0];
				g = pbrmr.baseColorFactor[1];
				b = pbrmr.baseColorFactor[2];
			}
			var col = ( Std.int(a * 0xFF) << 24) | (Std.int(r * 0xFF) << 16) | (Std.int(g * 0xFF) << 8) | Std.int(b * 0xFF);
			if (material == null) material = h3d.mat.Material.create(h3d.mat.Texture.fromColor( col ));
			var color = new h3d.Vector(r, g, b);
			material.color.load(color);

			pbrValues = material.mainPass.getShader(h3d.shader.pbr.PropsValues);

			#if debug_gltf
			trace("BaseColor:0x"+StringTools.hex(col, 8));
			#end

			if (pbrmr.metallicRoughnessTexture != null) {

				if (pbrTexture == null) {
					pbrTexture = new h3d.shader.pbr.PropsTexture( true );
					material.mainPass.addShader( pbrTexture );
				}
				pbrTexture.texture = getTexture(pbrmr.metallicRoughnessTexture.index);
			}
			pbrValues.metalness = Reflect.hasField(pbrmr, "metallicFactor") ? pbrmr.metallicFactor : 1;
			pbrValues.roughness = Reflect.hasField(pbrmr, "roughnessFactor") ? pbrmr.roughnessFactor : 0;
			
		}

		if (material != null) {

			if ( materialNode.normalTexture != null )
				material.normalMap = getTexture( materialNode.normalTexture.index, true );

			var emit = new h3d.Vector();
			if ( materialNode.emissiveFactor != null ) {
				emit.r = materialNode.emissiveFactor[0];
				emit.g = materialNode.emissiveFactor[1];
				emit.b = materialNode.emissiveFactor[2];
			} 
			pbrValues.emissive.set( emit.r, emit.g, emit.b );

			if ( materialNode.emissiveTexture != null ) {
				pbrTexture.hasEmissiveMap = true;
				pbrTexture.emissiveMap = getTexture( materialNode.emissiveTexture.index );
				pbrTexture.emissive.set( emit.r, emit.g, emit.b );
			}

			if ( materialNode.occlusionTexture != null ) {
				pbrTexture.hasOcclusionMap = true;
				pbrTexture.occlusionMap = getTexture( materialNode.occlusionTexture.index );
			} else {
				if (pbrTexture != null) {
					pbrTexture.hasOcclusionMap = true;
					pbrTexture.occlusionMap = h3d.mat.Texture.fromColor( 0xFFFFFF );
				}
			}

			if ( materialNode.name != null ) material.name = materialNode.name;
			if ( Reflect.hasField(materialNode, "doubleSided" )) material.mainPass.culling = materialNode.doubleSided ? None : Back;

			#if debug_gltf
			trace("Material:"+material.name+" m="+pbrValues.metalness+" r="+pbrValues.roughness+" o="+pbrValues.occlusion+" e="+pbrValues.emissive);
			#end
		} else
			material = h3d.mat.Material.create(h3d.mat.Texture.fromColor(0xFFFF0000));

		return material;
	} 

	function createAnimations( animationNode:Animation ) {
		
		if (animationNode.channels == null || animationNode.samplers == null) return null;
		
		for (channel in animationNode.channels) {
			var o:Object = null;
			var jointTarget:Object = null;
			var targetNodeId = channel.target.node;
			var isJoint = false;
			for (m in meshJoints.keys()) {
				if (meshJoints[m].indexOf(targetNodeId)>-1 ) {
					jointTarget = nodeObjects[ targetNodeId ];
					targetNodeId = nodeObjects.indexOf( m );
					o = m.getObjectByName(m.name+"_0");
					isJoint = true;
				}
			}
			if (!isJoint) 
				o = nodeObjects[ targetNodeId ];

			var prims = primitives[ o ];
			var path = channel.target.path;
			var sampler =  animationNode.samplers[ channel.sampler ];
			#if debug_gltf
			trace("Creating anim for channel ---------------------------------------");
			trace("Animation.channel: target:"+targetNodeId+" o:"+(o!=null ? o.name : "null")+" path:"+path);
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
			var anim:h3d.anim.TimelineLinearAnimation;
			if (anims.exists(targetNodeId)) 
				anim = anims[targetNodeId] 
			else {
				anim = anims[targetNodeId] = new h3d.anim.TimelineLinearAnimation(o.name, frameCount, keyFrames[keyFrames.length - 1], cast sampler.interpolation);
				// if (isJoint) 
				// 	anim.addCurve( o.name, new haxe.ds.Vector<h3d.anim.TimelineLinearAnimation.TimelineLinearFrame>(0), false, false, false, false);
			}

			trace("Anim: node="+targetNodeId+" o.name="+o.name);
			
			@:privateAccess if (keyFrames[keyFrames.length - 1] > anim.totalDuration) anim.totalDuration = keyFrames[keyFrames.length - 1];
			@:privateAccess trace("Anim["+targetNodeId+"].totalDuration="+anim.totalDuration);

			var frames = new haxe.ds.Vector<h3d.anim.TimelineLinearAnimation.TimelineLinearFrame>(frameCount);
			var wIdx = 0;
			for( i in 0...frameCount ) {
				var f = new h3d.anim.TimelineLinearAnimation.TimelineLinearFrame();
				f.keyTime = keyFrames[i];
				var cI = i*3;
				if( translationData!=null ) {
					if (sampler.interpolation==CubicSpline) {
						f.t0x = translationData[cI][0];
						f.t0y = translationData[cI][1];
						f.t0z = translationData[cI++][2];
						f.tx = translationData[cI][0];
						f.ty = translationData[cI][1];
						f.tz = translationData[cI++][2];
						f.t1x = translationData[cI][0];
						f.t1y = translationData[cI][1];
						f.t1z = translationData[cI][2];
					} else {
						f.tx = translationData[i][0];
						f.ty = translationData[i][1];
						f.tz = translationData[i][2];
					}
				} else {
					f.tx = 0;
					f.ty = 0;
					f.tz = 0;
				}
				if( rotationData!=null ) {
					if (sampler.interpolation==CubicSpline) {
						f.t0x = rotationData[cI][0];
						f.t0y = rotationData[cI][1];
						f.t0z = rotationData[cI][2];
						f.t0w = rotationData[cI++][3];
						f.qx = rotationData[cI][0];
						f.qy = rotationData[cI][1];
						f.qz = rotationData[cI][2];
						f.qw = rotationData[cI++][3];
						f.t1x = rotationData[cI][0];
						f.t1y = rotationData[cI][1];
						f.t1z = rotationData[cI][2];
						f.t1w = rotationData[cI][3];
					} else {
						f.qx = rotationData[i][0];
						f.qy = rotationData[i][1];
						f.qz = rotationData[i][2];
						f.qw = rotationData[i][3];
					}
				} else {
					f.qx = 0;
					f.qy = 0;
					f.qz = 0;
					f.qw = 1;
				}
				if( scaleData!=null ) {
					if (sampler.interpolation==CubicSpline) {
						f.t0x = scaleData[cI][0];
						f.t0y = scaleData[cI][1];
						f.t0z = scaleData[cI++][2];
						f.sx = scaleData[cI][0];
						f.sy = scaleData[cI][1];
						f.sz = scaleData[cI++][2];
						f.t1x = scaleData[cI][0];
						f.t1y = scaleData[cI][1];
						f.t1z = scaleData[cI][2];
					} else {
						f.sx = scaleData[i][0];
						f.sy = scaleData[i][1];
						f.sz = scaleData[i][2];
					}
				} else {
					f.sx = 1;
					f.sy = 1;
					f.sz = 1;
				}
			
				if (prims!=null) 
					for (p in prims) {
						var animTargets = cast(p.primitive, h3d.prim.GltfModel).geom.root.targets;
						var numTargets = animTargets==null ? 0 : animTargets.length;
						for (t in 0...numTargets) {
							if ( weightsData!=null )
								f.w[t] = ( weightsData!=null ) ? weightsData[wIdx++] : 0;
						}
					}
				frames[i] = f;
			}

			// ******************************

			// Need to some how add all the curves to the animation.
			// And add the SkinMesh to the as an animation object with a targetObject as the scene.Skin.
			// The Joints all need to reference the scene.Skin as the targetSkin


			// Merge frames to existing curves if possible
			anim.mergeOrAddCurve(isJoint ? jointTarget.name : o.name, frames, translationData!=null, rotationData!=null, scaleData!=null, weightsData!=null);

			if (animations.indexOf( anim )==-1) {
				animations.push( anim );

				animator.addAnimation( o, anim );
			}
		}
			

		return null;//animation;
	}

	function applySampler( index : Int, mat : h3d.mat.Texture ) {
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

		if (remapNormals) pixels.flipChannel( Channel.R );

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

	public function createMesh( index : Int, transform : h3d.Matrix, parent:h3d.scene.Object, nodeName:String = null ) : h3d.scene.Object {
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

			var meshPrim = new GltfModel( new Geometry(this, prim), this );
			meshPrim.name = primName;	
			var mat = materials[ prim.material ] != null ? materials[ prim.material ] : defaultMaterial;
			if (prim.targets!=null) {
				trace("Adding morph target shaders");
				var idx = 0;
				for (t in prim.targets) {
					var targetShader = idx==0 ? new h3d.shader.GlTFMorphTarget() : new h3d.shader.GlTFMorphTarget2();
					mat.mainPass.addShader(targetShader);
					idx++;
				}
			}

			var primMesh = new h3d.scene.Mesh( meshPrim, mat, mesh );
			primMesh.name = primName;

			primitives[mesh].push( primMesh );
			
			#if debug_gltf
			trace(" - mesh primitive:"+primMesh.name);
			#end

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

	public function createSkinMesh( index : Int, transform : h3d.Matrix, parent:h3d.scene.Object, nodeName:String = null, skinIndex : Int ) : h3d.scene.Object {
		var meshNode = root.meshes[ index ];
		var skinNode = root.skins[ skinIndex ];
		if (meshNode == null) { trace("meshNode returned NULL for idx:"+index); return null; }
		if (skinNode == null) { trace("skinNode returned NULL for idx:"+skinIndex); return null; }
		
		var meshName = (meshNode.name != null) ? meshNode.name : (nodeName != null ? nodeName : "Skin_"+StringTools.hex(Std.random(0x7FFFFFFF), 8));
		
		var mesh = new h3d.scene.Object( parent );
		mesh.name = meshName;
		mesh.setTransform( transform );
		meshes.push( mesh );
		#if debug_gltf
		trace("Create SkinMesh(Container):"+mesh.name+" parent:"+(parent.name == null ? Type.getClassName(Type.getClass(parent)) : parent.name)+" transform:"+transform);
		#end

		// // Create collection of joints and primitives for this mesh
		// if (!meshJoints.exists( mesh )) meshJoints[mesh] = [];
		// if (!primitives.exists( mesh )) primitives[mesh] = [];

		// var jointLookup = new Map<Object, h3d.anim.Skin.Joint>();
		// var primCounter = 0;
		// for ( prim in meshNode.primitives ) {
		// 	if ( prim.mode == null ) prim.mode = Triangles;

		// 	// TODO: Modes other than triangles?
		// 	if ( prim.mode != Triangles ) throw "Only triangles mode allowed in mesh primitive!";

		// 	var primName = meshName+"_"+primCounter++;

		// 	var meshPrim = new GltfModel( new Geometry(this, prim), this );
		// 	meshPrim.name = primName;	
		// 	var mat = materials[ prim.material ] != null ? materials[ prim.material ] : defaultMaterial;
		// 	//mat.blendMode = AlphaMultiply;
		
		// 	var skinName = (skinNode.name != null) ? skinNode.name : "Skin_"+StringTools.hex(Std.random(0x7FFFFFFF), 8);
		// 	var inverseBindMatrices:Array<Matrix> = GltfTools.getMatrixArrayBufferByAccessor( this, skinNode.inverseBindMatrices );
		// 	var skeletonRoot = skinNode.skeleton!= null ? nodeObjects[ skinNode.skeleton ] : nodeObjects[ skinNode.joints[0] ];
		// 	var joints:Array<h3d.anim.Skin.Joint> = [];

		// 	var bonesPerVertex = 4;//inverseBindMatrices.length;
		// 	var skinData = new h3d.anim.Skin(null, meshPrim.vertexCount(), bonesPerVertex);
		// 	var verts = meshPrim.geom.getVertices();
		// 	var jointData = meshPrim.geom.getJoints().getBytes();
		// 	var weights = meshPrim.geom.getWeights();
		// 	var vertCount = meshPrim.vertexCount();

		// 	trace("VertexCount:"+vertCount);
		// 	trace("JointCount:"+jointData.length);
		// 	trace("WeightCount:"+weights.length);

		// 	var allJointIds = skinNode.joints.copy();
		// 	function collectJoints(jId:Int) {
		// 		// collect subs first (allow easy removal of terminal unskinned joints)
		// 		if (allJointIds.indexOf(jId)==-1) 
		// 			allJointIds.push(jId);

		// 		var jN = root.nodes[ jId ];
		// 		if (jN.children!=null) {
		// 			for (jCId in jN.children) 
		// 				collectJoints( jCId );
		// 		}
		// 	}
		// 	for (jCId in allJointIds)
		// 		collectJoints(jCId);

		// 	var jCtr = 0;
		// 	for (jId in allJointIds) {
		// 		meshJoints[mesh].push( jId );

		// 		var jNode = nodeObjects[ jId ];
		// 		var j = new h3d.anim.Skin.Joint();
		// 		// getDefaultMatrixes( mesh ); // store for later usage in animation
		// 		j.index = jCtr;
		// 		j.name = jNode!=null ? jNode.name : "Joint_"+jCtr;
		// 		j.defMat = jNode!=null ? getDefaultTransform( jId ) : Matrix.I();
		// 		j.transPos = inverseBindMatrices[ jCtr ];
		// 		// j.transPos = new Matrix();
		// 		// j.transPos.multiply( j.defMat, inverseBindMatrices[ jCtr ] );
		// 		//rightHandToLeft(j.transPos);

		// 		// trace("Joint-"+jId+":");
		// 		// for (i in 0...vertCount) {
		// 			// var w = weights[i + (jCtr*vertCount)];
		// 			// if( w < 0.01 )
		// 			// 	continue;
		// 			// trace(" - v="+i+" idx="+(i + (jCtr*vertCount)));
		// 			// skinData.addInfluence(i, j, w);
		// 		// }

		// 		trace("New Skin.Joint: jId="+jId+" jNode:"+(jNode!=null ? jNode.name : "null")+" joint:"+j.name+" idx="+(joints.length));
		// 		trace("Default"+j.defMat);
		// 		var q = new h3d.Quat();
		// 		q.initRotateMatrix( j.defMat );
		// 		trace("p="+j.defMat.getPosition()+" q:"+q+" s="+j.defMat.getScale()+" r="+j.defMat.getEulerAngles());
		// 		trace("TransPos"+j.transPos);
		// 		jointLookup[jNode] = j;
		// 		joints.push( j );
		// 		jCtr++;
		// 	}

		// 	var idx = 0;
		// 	var w:Float = 0;
		// 	for (i in 0...vertCount) {
		// 		for (bpv in 0...bonesPerVertex) {
		// 			w = weights[ idx ];
		// 			if( w > 0.01)
		// 				skinData.addInfluence(i, joints[jointData.get(idx)], w);
		// 			idx++;
		// 		}
		// 	}

		// 	// for (bpv in 0...bonesPerVertex) {
		// 	// for (i in 0...jointData.length) {
		// 	// 	var vert = i % vertCount;
		// 	// 	var w = weights[ i ];
		// 	// 	if( w < 0.01 )
		// 	// 		continue;
		// 	// 	skinData.addInfluence(vert, joints[jointData.get(i)], w);
		// 	// }
		// 	// }

		// 	jCtr = 0;
		// 	for (jId in allJointIds) {
		// 		var jNode = nodeObjects[ jId ]; // - Joint container objects
		// 		trace("jNode: jId="+jId+" idx="+jCtr+" name="+jNode.name+" children="+jNode.numChildren);
		// 		var j = joints[jCtr];

		// 		// Add child joints
		// 		j.subs = [];
		// 		for (c in 0...jNode.numChildren) {
		// 			var o = jNode.getChildAt(c);
		// 			j.subs.push( jointLookup[o] );
		// 		}
		// 		// Set the parents of those children to the current joint
		// 		for (jC in 0...j.subs.length) {
		// 			var childJoint = j.subs[jC];
		// 			childJoint.parent = j;
		// 			var chJNId = allJointIds[childJoint.index];
		// 			// nodeObjects[ chJNId ].follow = jNode;
		// 			// trace("Following: "+nodeObjects[ chJNId ].name+"("+chJNId+") follows "+jNode.name+"("+jId+")");
		// 			// childJoint.defMat.multiply( childJoint.defMat, im );
		// 			// childJoint.transPos.multiply( childJoint.transPos, im );
		// 		}
		// 		jCtr++;
		// 	}

		// 	var rootJoints = [ joints[0] ];

		// 	// joints.reverse();
		// 	// for( i in 0...joints.length )
		// 	// 	joints[i].index = i;
		// 	skinData.setJoints( joints, rootJoints );
		// 	skinData.initWeights();
		// 	meshPrim.setSkin(skinData);


		// 	trace("Tree: root="+skeletonRoot+"("+skinNode.skeleton+")");
		// 	var r = jointLookup[skeletonRoot];
		// 	function traceJoint( j:h3d.anim.Skin.Joint, i:Int=0 ) {
		// 		var ind = "";
		// 		for (iTab in 0...i) ind+="- ";
		// 		trace(ind+"Joint:"+j.name+"("+j.index+") numChildren="+j.subs.length+" parent="+(j.parent == null ? "null" : ""+j.parent.index));
		// 		trace(j.defMat);
		// 		for (jc in 0...j.subs.length) {
		// 			traceJoint(j.subs[jc], i++);
		// 		}
		// 	}
		// 	traceJoint( r );

		// 	trace("InversBindMatrices:");
		// 	for (m in inverseBindMatrices) trace(" - :"+m);
		// 	trace("SkeletonRoot:"+skeletonRoot.name);
		// 	trace("Joints:");
		// 	var out = " - :";
		// 	for (i in joints) out+=i+", ";
		// 	trace(out);

		// 	var primSkin = new h3d.scene.Skin( skinData, [mat], mesh );
		// 	primSkin.showJoints = true;
		// 	primSkin.name = primName;

		// 	// primSkin.follow = nodeObjects[ skinNode.joints[0] ];

		// 	for ( jId in allJointIds ) 
		// 		jointMesh[jId] = primSkin;

		// 	primitives[mesh].push( primSkin );
			
		// 	#if debug_gltf
		// 	trace(" - skin primitive:"+primSkin.name);
		// 	#end
		// }
		
		return mesh;
	}

	public function buildSkinMeshes( ) {

		for (skinMeshLink in skinMeshes) {

			var meshNode = root.meshes[ skinMeshLink.nodeId ];
			var skinNode = root.skins[ skinMeshLink.skinId ];
			var mesh = skinMeshLink.skinMesh;

			// Create collection of joints and primitives for this mesh
			if (!meshJoints.exists( mesh )) meshJoints[mesh] = [];
			if (!primitives.exists( mesh )) primitives[mesh] = [];

			#if debug_gltf
			trace("Builduig SkinMesh-Primitives:"+mesh.name+" id="+skinMeshLink.nodeId+" skinid="+skinMeshLink.skinId);
			#end

			var jointLookup = new Map<Int, h3d.anim.Skin.Joint>();
			var primCounter = 0;
			for ( prim in meshNode.primitives ) {
				if ( prim.mode == null ) prim.mode = Triangles;

				// TODO: Modes other than triangles?
				if ( prim.mode != Triangles ) throw "Only triangles mode allowed in mesh primitive!";

				var primName = mesh.name+"_"+primCounter++;

				var meshPrim = new GltfModel( new Geometry(this, prim), this );
				meshPrim.name = primName;	
				var mat = materials[ prim.material ] != null ? materials[ prim.material ] : defaultMaterial;
				//mat.blendMode = AlphaMultiply;
			
				var skinName = (skinNode.name != null) ? skinNode.name : "Skin_"+StringTools.hex(Std.random(0x7FFFFFFF), 8);
				var inverseBindMatrices:Array<Matrix> = GltfTools.getMatrixArrayBufferByAccessor( this, skinNode.inverseBindMatrices );
				if (skinNode.skeleton == null) skinNode.skeleton = skinNode.joints[0];
				var skeletonRoot = skinNode.skeleton!= null ? nodeObjects[ skinNode.skeleton ] : nodeObjects[ skinNode.joints[0] ];
				var joints:Array<h3d.anim.Skin.Joint> = [];

				var bonesPerVertex = 4;//inverseBindMatrices.length;
				var skinData = new h3d.anim.Skin(null, meshPrim.vertexCount(), bonesPerVertex);
				var verts = meshPrim.geom.getVertices();
				var jointData = meshPrim.geom.getJoints().getBytes();
				var weights = meshPrim.geom.getWeights();
				var vertCount = meshPrim.vertexCount();

				trace("VertexCount:"+vertCount);
				trace("JointCount:"+jointData.length);
				trace("WeightCount:"+weights.length);

				var allJointIds = skinNode.joints.copy();
				function collectJoints(jId:Int) {
					// collect subs first (allow easy removal of terminal unskinned joints)
					if (allJointIds.indexOf(jId)==-1) 
						allJointIds.push(jId);

					var jN = root.nodes[ jId ];
					if (jN.children!=null) {
						for (jCId in jN.children) 
							collectJoints( jCId );
					}
				}
				for (jCId in allJointIds)
					collectJoints(jCId);

				var jCtr = 0;
				for (jId in allJointIds) {
					meshJoints[mesh].push( jId );

					var jNode = nodeObjects[ jId ];
					var j = new h3d.anim.Skin.Joint();
					// getDefaultMatrixes( mesh ); // store for later usage in animation
					j.index = jCtr;
					j.name = jNode!=null ? jNode.name : "Joint_"+jCtr;
					// var jObj = mesh.getScene().getObjectByName(j.name);
					// var jM = new Matrix();
					//  jObj.scaleY, jObj.scaleZ );
					// j.defMat = jM;jM.initTranslation( jObj.x, jObj.y, jObj.z );
					// var qM = jObj.getRotationQuat().toMatrix();
					// jM.multiply( jM, qM);
					// jM.scale( jObj.scaleX,

					var m = new Matrix();
					// var jObj = mesh.getScene().getObjectByName(j.name);
					// m.load( mesh.getInvPos() );
					// m.multiply(m, getDefaultTransform( jId ));
					// m.multiply(m, inverseBindMatrices[ jCtr ]);
					j.defMat = jNode!=null ? getDefaultTransform( jId ) : Matrix.I();
					j.transPos = inverseBindMatrices[ jCtr ];
					// trace("buildSkinMeshes: jId="+jId+" jCtr="+jCtr);
					
					
					// j.transPos = new Matrix();
					// j.transPos.multiply( j.defMat, inverseBindMatrices[ jCtr ] );
					//rightHandToLeft(j.transPos);

					// trace("Joint-"+jId+":");
					// for (i in 0...vertCount) {
						// var w = weights[i + (jCtr*vertCount)];
						// if( w < 0.01 )
						// 	continue;
						// trace(" - v="+i+" idx="+(i + (jCtr*vertCount)));
						// skinData.addInfluence(i, j, w);
					// }

					trace(" B-"+jCtr+": id:"+j.name+"("+jId+")");
					// trace("Def:"+OpenFLMain.mtos(getDefaultTransform( jId )));
					trace("Def:"+OpenFLMain.mtos(j.defMat));
					trace("Inv:"+OpenFLMain.mtos(j.transPos));
					jointLookup[jId] = j;
					joints.push( j );
					jCtr++;
				}

				// for (i in 0...joints.length) {
				// 	var jw = joints[i];
				// 	for (v in 0...vertCount) {
				// 		var w = weights[ i ];
				// 		if( w < 0.01 )
				// 			continue;
				// 		skinData.addInfluence(inde, jw, w);
				// 	}
				// }

/// from fbx
// if( weights.length > 0 ) {
// 	var weights = weights[0].getFloats();
// 	var vertex = subDef.get("Indexes").getInts();
// 	for( i in 0...vertex.length ) {
// 		var w = weights[i];
// 		if( w < 0.01 )
// 			continue;
// 		skin.addInfluence(vertex[i], j, w);
// 	}
// }

				var idx = 0;
				var w:Float = 0;
				var sortedJoints = skinNode.joints.copy();
				sortedJoints.sort(function(x, y) {
					return x==y ? 0 : (x<y ? -1 : 1);
				});
				
				for (i in 0...vertCount) {
					for (bpv in 0...bonesPerVertex) {
						w = weights[ idx ];
						if( w > 0.01) {
							var jointIndex = jointData.get(idx);
							skinData.addInfluence(i, joints[jointIndex], w);
							// var jI = sortedJoints[jointIndex];
							// skinData.addInfluence(i, jointLookup[jI], w);
						}
						idx++;
					}
				}

				// // for (bpv in 0...bonesPerVertex) {
				// for (i in 0...jointData.length) {
				// 	var vert = i % vertCount;
				// 	var w = weights[ i ];
				// 	if( w < 0.01 )
				// 		continue;
				// 	skinData.addInfluence(vert, joints[jointData.get(i)], w);
				// }
				// // }


				function buildTree( jId ) {
					var jNode = root.nodes[ jId ]; // - Joint container objects
					var j = jointLookup[ jId ];

					// Add child joints
					j.subs = [];

					if (jNode.children==null) return;

					trace("jNode-Name:"+jNode.name+" jId="+jId+" j.name="+j.name+"("+j.index+") children="+jNode.children);

					for (c in jNode.children) {
						var jC = jointLookup[c];
						j.subs.push( jC );
						jC.parent = j;

						buildTree( c );
					}
				} 

				buildTree( allJointIds[0] );

				function traceJoint( j:h3d.anim.Skin.Joint, i:Int=0 ) {
					var ind = "";
					for (iTab in 0...i) ind+="- ";
					trace(ind+"Joint:"+j.name+"("+j.index+") numChildren="+j.subs.length+" par="+(j.parent!=null ? j.parent.name+"("+j.parent.index+")" : "--null--"));
					for (jc in 0...j.subs.length) {
						traceJoint(j.subs[jc], i+1);
					}
				}
				trace("Tree-1: root="+skeletonRoot+"("+skinNode.skeleton+")");
				var r = jointLookup[skinNode.skeleton];
				traceJoint( r, 1 );

				// jCtr = 0;
				// for (jId in allJointIds) {
				// 	var jNode = root.nodes[ jId ]; // - Joint container objects
				// 	var j = joints[jCtr];

				// 	// Add child joints
				// 	j.subs = [];

				// 	if (jNode.children==null) continue;

				// 	trace("jNode: jId="+jId+" idx="+jCtr+" name="+jNode.name+" children="+jNode.children);

				// 	for (c in jNode.children) {
				// 		var jC = jointLookup[c];
				// 		j.subs.push( jC );
				// 		jC.parent = j;
				// 	}
				// 	// // Set the parents of those children to the current joint
				// 	// for (jC in 0...j.subs.length) {
				// 	// 	var childJoint = j.subs[jC];
				// 	// 	childJoint.parent = j;
				// 	// 	// var chJNId = allJointIds[childJoint.index];
				// 	// 	// nodeObjects[ chJNId ].follow = jNode;
				// 	// 	// trace("Following: "+nodeObjects[ chJNId ].name+"("+chJNId+") follows "+jNode.name+"("+jId+")");
				// 	// 	// childJoint.defMat.multiply( j.transPos, childJoint.defMat );
				// 	// 	// childJoint.transPos.multiply( j.transPos, childJoint.transPos );
				// 	// }
				// 	jCtr++;
				// }

				var rootJoints = [ jointLookup[skinNode.skeleton] ];

				// joints.reverse();
				// for( i in 0...joints.length )
				// 	joints[i].index = i;
				skinData.setJoints( joints, rootJoints );
				skinData.initWeights();
				meshPrim.setSkin(skinData);

				trace("Tree-1: root="+skeletonRoot+"("+skinNode.skeleton+")");
				r = jointLookup[skinNode.skeleton];
				traceJoint( r, 1 );


				trace("InversBindMatrices:");
				for (m in inverseBindMatrices) trace(" - :"+m);
				trace("SkeletonRoot:"+skeletonRoot.name);
				trace("Joints:");
				var out = " - :";
				for (i in joints) out+=i+", ";
				trace(out);

				var primSkin = new h3d.scene.Skin( skinData, [mat], mesh );
				// mesh.addChildAt(primSkin, 0 );
				primSkin.showJoints = false;
				primSkin.name = primName;

				// primSkin.follow = nodeObjects[ skinNode.joints[0] ];

				for ( jId in allJointIds ) 
					jointMesh[jId] = primSkin;

				primitives[mesh].push( primSkin );
				
				#if debug_gltf
				trace(" - skin primitive created:"+primSkin.name);
				#end

			}
		}
	}

	public function getDefaultTransform( nodeId:Int ) {
		var node = root.nodes[ nodeId ];

		var m = Matrix.I();
        if (node.matrix != null) m.loadValues( node.matrix );
        if (node.scale != null) m.scale( node.scale[0], node.scale[1], node.scale[2] );
        if (node.rotation != null) {
            var q = new h3d.Quat( node.rotation[0], node.rotation[1], node.rotation[2], node.rotation[3] );
            m.multiply( m, q.toMatrix() );
        }
        if (node.translation != null) m.translate( node.translation[0], node.translation[1], node.translation[2] );
		
		return m;
	}

	public function createSkinData( skinMesh:Skin, meshPrim, skinNode ) {

		#if debug_gltf
		trace("Create SkinData("+skinMesh.name+"):");
		#end


	}

	public static inline function rightHandToLeft( m : h3d.Matrix ) {
		// if [x,y,z] is our original point and M the matrix
		// in right hand we have [x,y,z] * M = [x',y',z']
		// we need to ensure that left hand matrix convey the x axis flip,
		// in order to have [-x,y,z] * M = [-x',y',z']
		m._12 = -m._12;
		m._13 = -m._13;
		m._21 = -m._21;
		m._31 = -m._31;
		m._41 = -m._41;
	}

	// function createSkin( hskins : Map<Int,h3d.anim.Skin>, hgeom : Map<Int,{function vertexCount():Int;function setSkin(s:h3d.anim.Skin):Void;}>, rootJoints : Array<h3d.anim.Skin.Joint>, bonesPerVertex ) {
	// 	var allJoints = [];
	// 	function collectJoints(j:h3d.anim.Skin.Joint) {
	// 		// collect subs first (allow easy removal of terminal unskinned joints)
	// 		for( j in j.subs )
	// 			collectJoints(cast j);
	// 		allJoints.push(j);
	// 	}
	// 	for( j in rootJoints )
	// 		collectJoints(j);
	// 	var skin = null;
	// 	var geomTrans = null;
	// 	var iterJoints = allJoints.copy();
	// 	for( j in iterJoints ) {
	// 		var jModel = ids.get(j.index);
	// 		var subDef = getParent(jModel, "Deformer", true);
	// 		var defMat = defaultModelMatrixes.get(jModel.getName());
	// 		j.defMat = defMat.toMatrix(leftHand);

	// 		if( subDef == null ) {
	// 			// if we have skinned subs, we need to keep in joint hierarchy
	// 			if( j.subs.length > 0 || keepJoint(j) )
	// 				continue;
	// 			// otherwise we're an ending bone, we can safely be removed
	// 			if( j.parent == null )
	// 				rootJoints.remove(j);
	// 			else
	// 				j.parent.subs.remove(j);
	// 			allJoints.remove(j);
	// 			// ignore key frames for this joint
	// 			defMat.wasRemoved = -1;
	// 			continue;
	// 		}
	// 		// create skin
	// 		if( skin == null ) {
	// 			var def = getParent(subDef, "Deformer");
	// 			skin = hskins.get(def.getId());
	// 			// shared skin between same instances
	// 			if( skin != null )
	// 				return skin;
	// 			var geom = hgeom.get(getParent(def, "Geometry").getId());
	// 			skin = new h3d.anim.Skin(null, geom.vertexCount(), bonesPerVertex);
	// 			geom.setSkin(skin);
	// 			hskins.set(def.getId(), skin);
	// 		}
	// 		j.transPos = defMat.transPos;

	// 		var weights = subDef.getAll("Weights");
	// 		if( weights.length > 0 ) {
	// 			var weights = weights[0].getFloats();
	// 			var vertex = subDef.get("Indexes").getInts();
	// 			for( i in 0...vertex.length ) {
	// 				var w = weights[i];
	// 				if( w < 0.01 )
	// 					continue;
	// 				skin.addInfluence(vertex[i], j, w);
	// 			}
	// 		}
	// 	}
	// 	if( skin == null )
	// 		throw "No joint is skinned ("+[for( j in iterJoints ) j.name].join(",")+")";
	// 	allJoints.reverse();
	// 	for( i in 0...allJoints.length )
	// 		allJoints[i].index = i;
	// 	skin.setJoints(allJoints, rootJoints);
	// 	skin.initWeights();
	// 	return skin;
	// }


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