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

        function perturbNormal(cotangentFrame:Mat3, textureSample:Vec3, scale:Float):Vec3 {
            textureSample = textureSample * 2.0 - 1.0;
            textureSample = normalize(vec3(textureSample.x, textureSample.y, textureSample.z) * vec3(scale, scale, 1.0));
            return normalize( cotangentFrame * textureSample ); 
        }

        function vertex() {
            var tangentUpdated = vec4(input.tangent.x, input.tangent.y, input.tangent.z, input.tangent.w);
            var tbnNormal = normalize(input.normal * gmv.mat3());
            var tbnTangent = normalize(tangentUpdated.xyz * vec3(1, -1, 1));
            var tbnBitangent = cross(tbnNormal, tbnTangent) * tangentUpdated.w;
            // vTBN = mat3( vec3(1, 0 , 0),vec3(0, -1, 0), vec3(0, 0 , 1) ) * finalWorld.mat3() * mat3(tbnTangent, tbnBitangent, tbnNormal);
            vTBN = finalWorld.mat3() * mat3(tbnTangent, tbnBitangent, tbnNormal);
        }

        function fragment() {
            TBN = vTBN;
            var b = bumpSampler.get(vMainUV1);
            var pt = perturbNormal(TBN, b.xyz, vBumpInfos.y);
            normalW = pt.xyz;//vec3( pt.x, pt.y, pt.z);
        }
    };

	public function new() {
        super();

        this.vBumpInfos.set( 0, 1, 0.0500 );
    }
}