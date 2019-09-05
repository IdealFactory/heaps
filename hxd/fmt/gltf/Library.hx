package hxd.fmt.gltf;

import hxd.fmt.gltf.Data;

class Library extends BaseLibrary {

    public function new( fileName:String, s3d:h3d.scene.Scene ) {
        
        buffers = [];
        
        this.s3d = s3d;

        #if debug_gltf
        trace("GLTF Loading scene:"+fileName);
        #end
        
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
            for (camera in root.cameras) {
                var c = createCamera( camera );
                cameras.push( c );
            }

        // Setup images
        if (root.images != null)
            for (image in root.images) {
                #if debug_gltf
                trace("Loading image:"+image);
                #end
                images.push( loadImage( image ) );
            }

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
        
        #if debug_gltf
        trace("DefaultSceneId:"+defaultSceneId);
        #end

        // Scenes
        for ( scene in root.scenes ) {
            var s = s3d;
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
        // Get matrix transform
        var transform = new h3d.Matrix();
        transform.identity();
        if (node.matrix != null) transform.loadValues( node.matrix );
        if (node.translation != null) transform.translate( node.translation[0], node.translation[1], node.translation[2] );
        if (node.rotation != null) {
            var q = new h3d.Quat( node.rotation[0], node.rotation[1], node.rotation[2], node.rotation[3] );
            transform.multiply( transform, q.toMatrix() );
        }
        if (node.scale != null) transform.scale( node.scale[0], node.scale[1], node.scale[2] );

        if (node.camera != null) {
            var c = cameras[ node.camera ];
            //TODO: Set camera position/rotation/scale from Matrix
            //Kind of inverse of Camera.makeCameraMatrix();
        }

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