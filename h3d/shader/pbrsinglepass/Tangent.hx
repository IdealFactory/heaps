package h3d.shader.pbrsinglepass;

class Tangent extends hxsl.Shader {

	static var SRC = {
        
		@global var global : {
			@perObject var modelView : Mat4;
		};

		@input var input : {
            var normal : Vec3;                                        // attribute vec4 tangent;    
            var tangent : Vec4;                                        // attribute vec4 tangent;    
        }

        @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;
        @param var vBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;

        @var var vMainUV1 : Vec2;                                       // varying vec2 vMainUV1;
        @var var vTBN : Mat3;
        
        var finalWorld:Mat4;
        var normalUpdated:Vec3;
        var normalW:Vec3;
        var gmv:Mat4;
        var TBN:Mat3;
        var testvar:Vec4;

        function perturbNormal(cotangentFrame:Mat3, textureSample:Vec3, scale:Float):Vec3 {
            textureSample = textureSample * 2.0 - 1.0;
            textureSample = normalize(vec3(textureSample.x, textureSample.y, textureSample.z) * vec3(scale, scale, 1.0));
            return normalize( cotangentFrame * textureSample ); 
        }

        function vertex() {
            var tangentUpdated = input.tangent;
            var tbnNormal = normalize(normalUpdated);
            var tbnTangent = normalize(tangentUpdated.xyz);
            var tbnBitangent = cross(tbnNormal, tbnTangent) * tangentUpdated.w;
            vTBN = finalWorld.mat3() * mat3(tbnTangent, tbnBitangent, tbnNormal);
        }

        function fragment() {
            TBN = vTBN;
            var pt = perturbNormal(TBN, bumpSampler.get(vMainUV1).xyz, vBumpInfos.y);
            normalW = vec3(pt.x, -pt.z, -pt.y);
        }
    };

	public function new() {
        super();

        this.vBumpInfos.set( 0, 1, 0.0500 );
    }
}