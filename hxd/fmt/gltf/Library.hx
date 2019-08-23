package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;

class Library extends BaseLibrary {

    public function new( fileName:String, s3d:h3d.scene.Scene ) {
        
        buffers = [];
        
        this.s3d = s3d;

        trace("GLTF Loading scene:"+fileName);
        var gltfFile = hxd.Res.load( fileName );
        var gltfBytes = gltfFile.entry.getBytes();

        var gltfContainer = hxd.fmt.gltf.Parser.parse( gltfBytes, loadBuffer );

        super( fileName, gltfContainer.header, gltfContainer.buffers, s3d );

    }

    public function loadGlTF( fileName:String ) {
        dispose();

        buffers = [];
        
        var gltfFile = hxd.Res.load( fileName );
        var gltfBytes = gltfFile.entry.getBytes();

        var gltfContainer = hxd.fmt.gltf.Parser.parse( gltfBytes, loadBuffer );

        load( fileName, gltfContainer.header, gltfContainer.buffers );
    }

	public function buildScenes() {
        reset();

        // Setup cameras
        if (root.cameras != null)
            for (camera in root.cameras) cameras.push( createCamera( camera ) );

        // Setup images
        if (root.images != null)
            for (image in root.images) {
                trace("Loading image:"+image);
                images.push( loadImage( image ) );
            }

        // Textures & Samplers can be done directly as they are indexes or properties

        // Setup materials
        if (root.materials != null)
            for (material in root.materials) materials.push( createMaterial( material ) );

        // // Setup skins
        // if (root.skins != null)
        //     for (skin in root.skins) skins.push( loadSkin( skin ) );

        // // Setup animations
        // if (root.animations != null)
        //     for (animation in root.animations) animations.push( loadAnimation( image ) );

        // Default scene
        var defaultSceneId = (root.scene == null) ? 0 : root.scene;
        trace("DefaultSceneId:"+defaultSceneId);

        // Scenes
        for ( scene in root.scenes ) {
            var s = s3d; //new h3d.scene.Scene();
            currentScene = s;
            var sceneContainer = new h3d.scene.Object( s3d);
		    sceneContainer.rotate( Math.PI/2, 0, 0 );
            scenes.push( sceneContainer );
			for ( node in scene.nodes ) {
				traverseNodes(root.nodes[ node ], sceneContainer );
			}
		}
    }

	function traverseNodes( node : Node, parent:h3d.scene.Object ) {
        var hasCam = (node.camera != null);
        var hasMesh = (node.mesh != null);
        var nodeType = (hasMesh ? "MeshNode ("+ root.meshes[node.mesh].name+ ")" : (hasCam ? "CameraNode" : "Node"));
        trace("TraversingNodes:"+nodeType+" hasChildNodes:"+(node.children != null));

        // Add meshes
        var transform = new h3d.Matrix();
        transform.identity();
        if (node.matrix != null) transform.loadValues( node.matrix );
        if (node.translation != null) transform.translate( node.translation[0], node.translation[1], node.translation[2] );
        if (node.rotation != null) {
            var q = new h3d.Quat( node.rotation[0], node.rotation[1], node.rotation[2], node.rotation[3] );
            transform.multiply( transform, q.toMatrix() );
        }
        if (node.scale != null) transform.scale( node.scale[0], node.scale[1], node.scale[2] );

        // Add meshes
        if (node.mesh != null) {
            parent = loadMesh( node.mesh, transform, parent );
        }

        if (node.children != null) {
            var mesh = new h3d.scene.Object( parent );
		    mesh.setTransform( transform );
            for ( child in node.children ) {
                traverseNodes(root.nodes[ child ], mesh);
            }
        }
    }
}