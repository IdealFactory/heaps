package hxd.fmt.env;

/* 
    https://github.com/BabylonJS/Babylon.js  src/Materials/Textures/Loaders/envTextureLoader.ts
    https://github.com/BabylonJS/Babylon.js/blob/master/license.md
*/

import hxd.fmt.env.Data;
import h3d.mat.Data;
import h3d.Vector;
import haxe.Json;

class Reader {

    static var LOG2E = 1.4426950408889634;
    static var _MagicBytes:Array<Int> = [0x86, 0x16, 0x87, 0x96, 0xf6, 0xd6, 0x96, 0x36];

    var i:haxe.io.BytesInput;
    var info:EnvironmentTextureInfo;
    
    var version : Int;
    var images:Array<Array<hxd.BitmapData>>;
    var mipmapsCount:Int;
    var imagesReady:Bool = false;
    var order = [0, 1, 3, 2, 4, 5];

    static var envCount = 0;
    
    public var texture(get, null):h3d.mat.Texture; 
    public var sphericalPolynomial:SphericalPolynomial;
    
    public function new(i) {
        this.i = i;
    }
    
    public function read() {
        info = getEnvInfo();

        texture = null;
        if (info != null) {
            mipmapsCount = Math.round( std.Math.log(info.width) * LOG2E) + 1;

            uploadEnvSpherical();
            uploadEnvLevelsAsync();
        }
    }

    function getEnvInfo() : EnvironmentTextureInfo {

        var pos = 0;

        for (mb in 0..._MagicBytes.length) {
            if (i.readByte() != _MagicBytes[mb]) {
                throw 'Not a babylon environment map';
                return null;
            }
        }

        var manifestString = i.readUntil(0x00);
        pos += manifestString.length + 9; // Manifest length + magic string length + manifest terminator char

        var manifest:EnvironmentTextureInfo = Json.parse(manifestString);
        if (manifest.specular != null) {
            // Extend the header with the position of the payload.
            manifest.specular.specularDataPosition = pos;
            // Fallback to 0.8 exactly if lodGenerationScale is not defined for backward compatibility.
            manifest.specular.lodGenerationScale = (manifest.specular.lodGenerationScale != null ? manifest.specular.lodGenerationScale : 0.8);
        }

        return manifest;
    }

    function uploadEnvSpherical() {
        if (info.irradiance == null) {
            return;
        }

        var sp = new SphericalPolynomial();
        sp.x = Vector.fromArray(info.irradiance.x);
        sp.y = Vector.fromArray(info.irradiance.y);
        sp.z = Vector.fromArray(info.irradiance.z);
        sp.xx = Vector.fromArray(info.irradiance.xx);
        sp.yy = Vector.fromArray(info.irradiance.yy);
        sp.zz = Vector.fromArray(info.irradiance.zz);
        sp.yz = Vector.fromArray(info.irradiance.yz);
        sp.zx = Vector.fromArray(info.irradiance.zx);
        sp.xy = Vector.fromArray(info.irradiance.xy);
        sphericalPolynomial = sp;
    }

    function uploadEnvLevelsAsync() {
        if (info.version != 1)
            throw "Unsupported babylon environment map version "+ info.version;
    
        if (info.specular == null) return;

        //TODO: Potentially
        // texture._lodGenerationScale = specularInfo.lodGenerationScale;

        var imageData = createImageDataArrayBufferViews();
        loadTextures(texture, imageData);
    }

    function createImageDataArrayBufferViews(): Array<Array<haxe.io.Bytes>> {
        // Double checks the enclosed info
        if (info.specular.mipmaps.length != 6 * mipmapsCount) {
            throw "Unsupported specular mipmaps number "+info.specular.mipmaps.length;
        }

        var imageData = new Array<Array<haxe.io.Bytes>>();
        images = [];
        for (im in 0...mipmapsCount) {
            imageData[im] = new Array<haxe.io.Bytes>();
            images[im] = [];
            for (face in 0...6) {
                images[im][order[face]] = null;
                var imageInfo = info.specular.mipmaps[im * 6 + face];
                i.position = (info.specular.specularDataPosition!=null ? info.specular.specularDataPosition : 0) + imageInfo.position;
                var imgBytes = i.read(imageInfo.length);
                imageData[im][order[face]] = imgBytes;
            }
        }

        return imageData;
    }

    function loadTextures(texture:h3d.mat.Texture, imageData: Array<Array<haxe.io.Bytes>>) {
        for (im in 0...mipmapsCount) {
            for (face in 0...6) {
                var bytes = imageData[im][face];

                var entry = new hxd.fmt.gltf.DataURIEntry( "env"+(envCount++)+".env", "no-uri", bytes ); 
                var img = new hxd.res.Image( entry );
                var size = img.getSize();
                var bmp = new hxd.BitmapData(size.width, size.height);
		        var pixels = img.getPixels( hxd.PixelFormat.RGBA);
		        bmp.setPixels(pixels);
		        pixels.dispose();
                // images[im][face] = new hxd.res.Image( entry ).toBitmap();
                images[im][face] = bmp;
            }
        }
        imagesReady = true;
    }

    function get_texture() {
        if (!imagesReady) return null;
        if (texture != null) return texture;

        #if (openfl && (js))
        @:privateAccess openfl.Lib.current.stage.context3D.gl.pixelStorei(lime.graphics.opengl.GL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 0);
        #end

        if (hxd.fmt.gltf.Data.supportsFrameBufferMipMap) {

            var sourceTexture = new h3d.mat.Texture(info.width, info.width, [NoAlloc], h3d.mat.Data.TextureFormat.RGBA);
            sourceTexture.setName("sourceTex");
            sourceTexture.wrap = h3d.mat.Data.Wrap.Repeat;
            
            var shader = new h3d.shader.pbrsinglepass.RGBDDecode();
            var screen = new h3d.pass.ScreenFx( shader );
            var engine = h3d.Engine.getCurrent();
            
            texture = new h3d.mat.Texture(info.width, info.width, [Target,Cube,MipMapped,ManualMipMapGen], h3d.mat.Data.TextureFormat.RGBA16F);//h3d.mat.Texture.nativeFormat);
            texture.preventAutoDispose();
            texture.mipMap = Linear;
            texture.filter = Linear;

            // Use shader to generate RGBDDecoded environment map
            var size:Int = info.width;
            for (im in 0...mipmapsCount) {
                for (face in 0...6) {
                    #if debug_gltf
                    trace("RGBDDecoding env:IM="+im+" face="+face);
                    #end
                    sourceTexture.resize( size, size );
                    sourceTexture.uploadBitmap(images[im][face]);
                    
                    // Render the RGBDDecode shader to create the HDR half-float mip-mapped environment cube-map faces
                    shader.textureSampler = sourceTexture;
                    engine.pushTarget( texture, face, im );
                    screen.render();
                    engine.popTarget();
                    @:privateAccess engine.flushTarget();  
                }
                size = size >> 1;
            }

            screen.dispose();
 
        } else {

            texture = new h3d.mat.Texture(info.width, info.width, [Target,Cube,MipMapped,ManualMipMapGen], h3d.mat.Texture.nativeFormat ); 
            texture.preventAutoDispose();
            texture.mipMap = Linear;
            texture.filter = Linear;

            // Upload textures as normal and RGBDDecode within the main shader
            var size:Int = info.width;
            for (im in 0...mipmapsCount) {
                for (face in 0...6) {
                    #if debug_gltf
                    trace("Environemnt texture upload env:IM="+im+" face="+face);
                    #end
                    texture.uploadBitmap(images[im][face], im, face);
                }
                size = size >> 1;
            }    
        }
       
        #if (openfl && (js))
        @:privateAccess openfl.Lib.current.stage.context3D.gl.pixelStorei(lime.graphics.opengl.GL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);
        #end

        return texture;
    }

    public static inline function parse(bytes : haxe.io.Bytes ) {
        var reader = new Reader(new haxe.io.BytesInput(bytes));
        reader.read();
		return reader;
	}
}
