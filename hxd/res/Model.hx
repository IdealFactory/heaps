package hxd.res;

interface IModelLibrary {
	/**
		Original library format. Can be one of: `hmd`, `fbx` or `gltf`.
	**/
	var format : String;
	
	

	function loadAnimation( ?name : String ) : h3d.anim.Animation;
	function loadModel( loadTexture : String -> h3d.mat.Texture ) : h3d.scene.Object;
	// function loadMaterial
	// function loadMesh

}

class Model extends Resource {

	public function toHmd() : hxd.fmt.hmd.Library {
		var hmd = new hxd.fmt.hmd.Reader(new hxd.fs.FileInput(entry)).readHeader();
		return new hxd.fmt.hmd.Library(this, hmd);
	}

}