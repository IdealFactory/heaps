package hxd.fmt.env;

/* 
    https://github.com/BabylonJS/Babylon.js  /src/Misc/environmentTextureTools.ts
    https://github.com/BabylonJS/Babylon.js/blob/master/license.md
*/

/**
 * Raw texture data and descriptor sufficient for WebGL texture upload
 */
 typedef EnvironmentTextureInfo = {
    /**
     * Version of the environment map
     */
    var version: Int;

    /**
     * Width of image
     */
    var width: Int;

    /**
     * Irradiance information stored in the file.
     */
    var irradiance: EnvironmentTextureIrradianceInfoV1;

    /**
     * Specular information stored in the file.
     */
     var specular: EnvironmentTextureSpecularInfoV1;
}

/**
 * Defines One Image in the file. It requires only the position in the file
 * as well as the length.
 */
 typedef BufferImageData = {
    /**
     * Length of the image data.
     */
    var length: Int;
    /**
     * Position of the data from the null terminator delimiting the end of the JSON.
     */
    var position: Int;
}

/**
 * Defines the specular data enclosed in the file.
 * This corresponds to the version 1 of the data.
 */
 typedef EnvironmentTextureSpecularInfoV1 = {
    /**
     * Defines where the specular Payload is located. It is a runtime value only not stored in the file.
     */
     @:optional var specularDataPosition: Int;
    /**
     * This contains all the images data needed to reconstruct the cubemap.
     */
    var mipmaps: Array<BufferImageData>;
    /**
     * Defines the scale applied to environment texture. This manages the range of LOD level used for IBL according to the roughness.
     */
     @:optional var lodGenerationScale: Float;
}

/**
 * Defines the required storage to save the environment irradiance information.
 */
typedef EnvironmentTextureIrradianceInfoV1 = {
    var x: Array<Float>;
    var y: Array<Float>;
    var z: Array<Float>;

    var xx: Array<Float>;
    var yy: Array<Float>;
    var zz: Array<Float>;

    var yz: Array<Float>;
    var zx: Array<Float>;
    var xy: Array<Float>;
}

typedef Env = {
    var info : EnvironmentTextureInfo;
}