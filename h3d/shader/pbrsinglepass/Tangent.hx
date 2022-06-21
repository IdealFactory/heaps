package h3d.shader.pbrsinglepass;

class Tangent extends PBRSinglePassLib {

	static var SRC = {
        
		@input var input : {
            var normal : Vec3;                                        // attribute vec4 tangent;    
            var tangent : Vec4;                                        // attribute vec4 tangent;    
        }

        @keep @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;
        @param var uBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;

        @keep @keepv @var var vTBN : Mat3;
        @keep var vBumpInfos : Vec3;
        
        var finalWorld:Mat4;
        var normalUpdated:Vec3;
        var normalW:Vec3;
        var TBN:Mat3;
        @keepv var tangentUpdated:Vec4; 
        
        function vertex() {
            glslsource("// Tangent vertex-test");
            tangentUpdated = vec4(input.tangent.x * -1.0, input.tangent.z, input.tangent.y, input.tangent.w * -1.0);
            glslsource("// Tangent vertex
    vec3 tbnNormal = normalize(normalUpdated);
    vec3 tbnTangent = normalize(tangentUpdated.xyz);
    vec3 tbnBitangent = cross(tbnNormal, tbnTangent)*tangentUpdated.w;
    vTBN = mat3(finalWorld)*mat3(tbnTangent, tbnBitangent, tbnNormal);
");
        }

        function __init__fragment() {
            glslsource("// Tangent __init__fragment");

            vBumpInfos = uBumpInfos;
		}

        fragfunction("tangentDefine",
"#define vBumpUV vMainUV1");

        fragfunction("perturbNormal",
"vec3 perturbNormalBase(mat3 cotangentFrame, vec3 normal, float scale) {
    normal = normalize(normal*vec3(scale, scale, 1.0));
    return normalize(cotangentFrame*normal);
}
vec3 perturbNormal(mat3 cotangentFrame, vec3 textureSample, float scale) {
    return perturbNormalBase(cotangentFrame, textureSample*2.0-1.0, scale);
}
");

        function fragment() {
            glslsource("
    // Tangent fragment
    float normalScale = 1.0;
    mat3 TBN = vTBN;
    normalW = perturbNormal(TBN, texture(bumpSampler, vBumpUV+uvOffset).xyz, vBumpInfos.y);
");
        }
    };

	public function new() {
        super();

        this.uBumpInfos.set( 0, 1, 0.0500 );
    }
}