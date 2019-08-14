package hxd.fmt.gltf;

import hxd.fmt.hmd.Data;

class HMDOut extends BaseLibrary {
	
	var d : Data;
	var dataOut : haxe.io.BytesOutput;
	var filePath : String;
	var tmp = haxe.io.Bytes.alloc(4);
	public var absoluteTexturePath : Bool;

	function addModels( includeGeometry : Bool ) {

		var objects = [];
		function traverseNodes( node : gltf.types.Node ) {
			for ( child in node.children ) {
				traverseNodes(child);
			}
		}
		// var s = root.scenes[root.defaultScene];
		// for ( scene in root.scenes ) {
		// 	for ( node in scene.nodes ) {
		// 		traverseNodes(node);
		// 	}
		// }

	}

	public function toHMD( filePath : String, includeGeometry : Bool ) : Data {
		
		// if we have only animation data, make sure to export all joints positions
		// because they might be applied to a different model at runtime
		// if( !includeGeometry )
		// 	optimizeSkin = false;

		// leftHandConvert();
		// autoMerge();

		if( filePath != null ) {
			filePath = filePath.split("\\").join("/").toLowerCase();
			if( !StringTools.endsWith(filePath, "/") )
				filePath += "/";
		}
		this.filePath = filePath;

		d = new Data();
		#if hmd_version
		d.version = Std.parseInt(#if macro haxe.macro.Context.definedValue("hmd_version") #else haxe.macro.Compiler.getDefine("hmd_version") #end);
		#else
		d.version = Data.CURRENT_VERSION;
		#end
		d.geometries = [];
		d.materials = [];
		d.models = [];
		d.animations = [];

		dataOut = new haxe.io.BytesOutput();

		addModels(includeGeometry);
		
		
		// for (m in root.meshes) {
		// 	m.primitives[0].
		// }

		// var names = getAnimationNames();
		// for ( animName in names ) {
		// 	var anim = loadAnimation(animName);
		// 	if(anim != null)
		// 		d.animations.push(makeAnimation(anim));
		// }

		for ( mat in root.materials ) {
			var hmdMat = new Material();
			hmdMat.name = mat.name;
		// 	if ( mat.normalTexture != null ) {
		// 		var tex = root.textures[mat.normalTexture.index];
		// 		var texImg = root.images[tex.source];
		// 		// TODO: Validate that it's an external image
		// 		mat.normalTexture = texImg.uri;
		// 	}
		// 	mat.alphaMode
		// 	if ( mat.alphaMode)
		// 	root.textures
		// 	// hmdMat.blendMode
		// 	// hmdMat.diffuseTexture
		// 	// hmdMat.specularTexture
		// 	// hmdMat.normalMap
		// 	// hmdMat.props
		}

		d.data = dataOut.getBytes();
		return d;
	}

}