package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;

class Geometry {
	
	public var l (default, null) : BaseLibrary;
	public var root (default, null) : Mesh;

	public function new ( l : BaseLibrary, root : Mesh ) {
		this.l = l;
		this.root = root;
	}

	public function getPositions() {
		
	}

}