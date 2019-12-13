package hxd.fmt.gltf;

import haxe.io.Bytes;
import hxd.fmt.gltf.Data;

class Library extends BaseLibrary {

    var gltfFileProcessed:Void->Void;
    var containerCtr = 0;
    var jointCtr = 0;
    var allJointNodes:Array<Int>;

    public function load( ?fileName:String = "gltffile", ?bytes:Bytes, gltfFileProcessed ) {	

        this.gltfFileProcessed = gltfFileProcessed;

        #if debug_gltf
        trace("GLTF Loading scene:"+fileName);
        #end

		reset();

		this.fileName = fileName;
       
        var gltfBytes:Bytes;
        if (bytes != null) {
            parseglTF( bytes );
        } 
        #if openfl
        else if (fileName.indexOf("http://")>-1 || fileName.indexOf("https://")>-1) {
            totalBytesToLoad = 0;
            baseURL = fileName.substr(0, fileName.lastIndexOf("/")+1);
            dependencyInfo = new Map<openfl.net.URLLoader,BaseLibrary.LoadInfo>();
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

        // Get all joints for all skins to set object names correctly
        allJointNodes = [];
        if (root.skins!=null)
            for (s in root.skins) {
                if (s.joints!=null)
                    for (j in s.joints) {
                        if (allJointNodes.indexOf( j )==-1) allJointNodes.push( j );
                    }
            }

        // Setup cameras
        if (root.cameras != null)
            for (camera in root.cameras) {
                var c = createCamera( camera );
                cameras.push( c );
            }

        // Setup materials
        if (root.materials != null)
            for (material in root.materials) materials.push( createMaterial( material ) );

        // // Setup skins
        // if (root.skins != null)
        //     for (skin in root.skins) skins.push( loadSkin( skin ) );

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
            sceneContainer.name = "gltf-root";
		    sceneContainer.rotate( Math.PI/2, 0, 0 );
            scenes.push( sceneContainer );
			for ( node in scene.nodes ) {
				traverseNodes(node, sceneContainer );
			}
		}

        // // Create skin meshes
        buildSkinMeshes();

        // Setup animations
        if (root.animations != null)
            for (animation in root.animations) createAnimations( animation );

        #if openfl
        dispatchEvent(new openfl.events.Event(openfl.events.Event.COMPLETE));
        #end

        gltfFileProcessed();
    }

    function traverseNodes( nodeId : Int, parent:h3d.scene.Object ) {

        var node = root.nodes[ nodeId ];

        // Get matrix transform
        var transform = getDefaultTransform( nodeId );

        if (node.camera != null) {
            var c = cameras[ node.camera ];
            //TODO: Set camera position/rotation/scale from Matrix
            //Kind of inverse of Camera.makeCameraMatrix();
        }

        // Add meshes
        var mesh:h3d.scene.Object = null;
        if (node.mesh != null) {
            if (node.skin != null) {
                mesh = createSkinMesh( node.mesh, transform, parent, node.name, node.skin );
                trace("createSkinMesh:"+Type.getClassName(Type.getClass(mesh)));
                skinMeshes.push( { nodeId:node.mesh, skinId:node.skin, skinMesh:mesh } );
            } else
                mesh = createMesh( node.mesh, transform, parent, node.name );
            trace("MeshTransform:"+mesh.name+" m:"+mtos(transform));
            nodeObjects[ nodeId ] = mesh;
        } 

        if (node.children != null) {
            if (mesh==null) {
                // mesh = new h3d.scene.Mesh(debugPrim, parent);
                // cast(mesh, h3d.scene.Mesh).material.color.setColor( 0xff009000 );
                mesh = new h3d.scene.Object( parent );
                mesh.name = getName( nodeId );
                mesh.setTransform( transform );
                trace("MeshTransform:"+mesh.name+" m:"+mtos(transform));
                nodeObjects[ nodeId ] = mesh;
            }
            for ( child in node.children ) {
                traverseNodes(child, mesh);
            }
        }

        if (node.mesh==null && node.children==null) {
            // var o = new h3d.scene.Mesh(debugPrim, parent);
            // o.material.color.setColor( 0xffff0000 );
            var o = new h3d.scene.Object( parent );
            o.name = getName( nodeId );
            o.setTransform( transform );
            trace("MeshTransform:"+o.name+" m:"+mtos(transform));
            nodeObjects[ nodeId ] = o;
        }
    }

    function getName( id:Int ) {
        var n = root.nodes[ id ];
        if (n.name!=null) return n.name;

        if (allJointNodes.indexOf( id )>-1) return "Joint_"+jointCtr++;

        return "Container_"+containerCtr++;
    }

    function mtos(m:h3d.Matrix) {
		if (m==null) return "--NULL--";
		return r(m._11)+","+r(m._12)+","+r(m._13)+","+r(m._14)+","+r(m._21)+","+r(m._22)+","+r(m._23)+","+r(m._24)+","+r(m._31)+","+r(m._32)+","+r(m._33)+","+r(m._34)+","+r(m._41)+","+r(m._42)+","+r(m._43)+","+r(m._44);
	}
	function r(v:Float) {
		return Std.int((v * 10000) + 0.5) / 10000; 
	}

}

