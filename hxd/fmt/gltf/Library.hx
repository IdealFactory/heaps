package hxd.fmt.gltf;

import haxe.io.Bytes;
import hxd.fmt.gltf.Data;

class Library extends BaseLibrary {

    var gltfFileProcessed:Void->Void;

    public function load( ?fileName:String = "gltffile", ?bytes:Bytes, gltfFileProcessed ) {	

        this.gltfFileProcessed = gltfFileProcessed;

		reset();

        this.fileName = fileName;
        
        if (fileName.indexOf("http://")>-1 || fileName.indexOf("https://")>-1)
            baseURL = fileName.substr(0, fileName.lastIndexOf("/")+1);

        #if debug_gltf
        trace("GLTF Loading scene:"+fileName+" BaseURL:"+baseURL);
        #end

        var gltfBytes:Bytes;
        if (bytes != null) {
            parseglTF( bytes );
        } 
        #if openfl
        else if (fileName.indexOf("http://")>-1 || fileName.indexOf("https://")>-1) {
            totalBytesToLoad = 0;
            requestURL( fileName, onComplete );
        } 
        #end
        else {
            var gltfFile = hxd.Res.load( fileName );
            gltfBytes = gltfFile.entry.getBytes();
            parseglTF( gltfBytes );
        }
    }

    #if openfl
    function onComplete(event:openfl.events.Event) {
        trace("onComplete:"+event);
        var gltfBytes = #if !flash cast( event.target, openfl.net.URLLoader).data #else Bytes.ofData( cast (event.target, openfl.net.URLLoader).data) #end;
        parseglTF( gltfBytes );
    }
    #end
    
    public function parseglTF( glTFBytes ) {
        hxd.fmt.gltf.Parser.parse( glTFBytes, loadBuffer, parseComplete);
    }

    function parseComplete( gltfContainer:GltfContainer ) {
        this.root = gltfContainer.header;
		this.buffers = gltfContainer.buffers;

        reset();

        preLoadImages( processglTF );
    }

	function preLoadImages( imageLoadingCompleted ) {

        // Setup images
        var loadedCount = 0;
        var idx = 0;
        if (root.images != null) {
            for (image in root.images)
                loadImage( image, idx++, function() {
                    loadedCount++; 
                    if (loadedCount == root.images.length) imageLoadingCompleted();
                } );
            }
        else
            imageLoadingCompleted();
    }

	function processglTF() {

        // Setup cameras
        if (root.cameras != null)
            for (camera in root.cameras) {
                var c = createCamera( camera );
                cameras.push( c );
            }

        // Setup materials
        if (root.materials != null)
            for (material in root.materials) materials.push( createMaterial( material ) );

        // Default scene
        var defaultSceneId = (root.scene == null) ? 0 : root.scene;
        
        #if debug_gltf
        trace("DefaultSceneId:"+defaultSceneId);
        #end

        // Scenes
        if (root.scenes != null)
            for ( scene in root.scenes ) {
                var sceneContainer = new h3d.scene.Object();
                sceneContainer.name = "SceneContainer";
                sceneContainer.rotate( Math.PI/2, 0, 0 );
                scenes.push( sceneContainer );
                if (scene.nodes != null)
                    for ( node in scene.nodes )
                        traverseNodes(node, sceneContainer );
            }

        // Setup animations
        if (root.animations != null)
            for (animation in root.animations) createAnimations( animation );


        for ( scene in scenes ) {
            s3d.addChild(scene);
        }
        
        #if openfl
        dispatchEvent(new openfl.events.Event(openfl.events.Event.COMPLETE));
        #end

        gltfFileProcessed();
   }

	function traverseNodes( nodeId : Int, parent:h3d.scene.Object ) {

        var node = root.nodes[ nodeId ];

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
        var mesh:h3d.scene.Object = null;
        if (node.mesh != null) {
            mesh = loadMesh( node.mesh, transform, parent, node.name );
            nodeObjects[ nodeId ] = mesh;
        } 

        if (node.children != null) {
            if (mesh==null) {
                mesh = new h3d.scene.Object( parent );
                mesh.name = "Container";
                mesh.setTransform( transform );
                nodeObjects[ nodeId ] = mesh;
            }
            for ( child in node.children ) {
                traverseNodes(child, mesh);
            }
        }
    }
}