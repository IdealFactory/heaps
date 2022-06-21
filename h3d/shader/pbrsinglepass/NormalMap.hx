package h3d.shader.pbrsinglepass;

class NormalMap extends PBRSinglePassLib {

	static var SRC = {
        
        @keep @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;
        @param var uBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;
        @param var uTangentSpaceParams : Vec2;                                   // uniform vec2 uTangentSpaceParams;

        @keep @keepv @var var vTBN : Vec3;
        @keep var vBumpInfos : Vec3;
        @keep var vTangentSpaceParams : Vec2;

        var normalW:Vec3;
        var positionW:Vec3;
        var viewDirectionW:Vec3;

        var NdotVUnclamped:Float;
        var NdotV:Float;
        var AARoughnessFactors:Vec2;

        function __init__fragment() {
            glslsource("// NormalMap __init__fragment");

            vBumpInfos = uBumpInfos;
            vTangentSpaceParams = uTangentSpaceParams;
		}

        fragfunction("normalMapDefine",
"#define vBumpUV vMainUV1");

//         function vertex() {
//             glslsource("
//     // NormalMap vertex
//     vec3 tbnNormal = normalize(normalUpdated);
//     vec3 tbnTangent = normalize(tangentUpdated.xyz);
//     vec3 tbnBitangent = cross(tbnNormal, tbnTangent)*tangentUpdated.w;
//     vTBN = mat3(finalWorld)*mat3(tbnTangent, tbnBitangent, tbnNormal);
// ");
//         }
        fragfunction("perturbNormal",
"vec3 perturbNormalBase(mat3 cotangentFrame, vec3 normal, float scale) {
    normal = normalize(normal*vec3(scale, scale, 1.0));
    return normalize(cotangentFrame*normal);
}
vec3 perturbNormal(mat3 cotangentFrame, vec3 textureSample, float scale) {
    return perturbNormalBase(cotangentFrame, textureSample*2.0-1.0, scale);
}
");
        fragfunction("cotangent_frame",
"mat3 cotangent_frame(vec3 normal, vec3 p, vec2 uv, vec2 tangentSpaceParams) {
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);
    vec3 dp2perp = cross(dp2, normal);
    vec3 dp1perp = cross(normal, dp1);
    vec3 tangent = dp2perp*duv1.x+dp1perp*duv2.x;
    vec3 bitangent = dp2perp*duv1.y+dp1perp*duv2.y;
    tangent *= tangentSpaceParams.x;
    bitangent *= tangentSpaceParams.y;
    float invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
    return mat3(tangent*invmax, bitangent*invmax, normal);
}
");

 		function fragment() {
            // var TBN = cotangent_frameWithTS(normalW, positionW, vMainUV1, vec2(1.,-1.)); //mat3 // vBumpUV -> vMainUV1
            // var bmp = bumpSampler.get(vMainUV1);
            // var pt = perturbNormal(TBN, bmp.xyz, vBumpInfos.y);
            // normalW = vec3(pt.x, pt.y, pt.z);

            // NdotVUnclamped = dot(normalW, viewDirectionW);
            // NdotV = absEps(NdotVUnclamped);
            // AARoughnessFactors = getAARoughnessFactors(normalW.xyz);

            glslsource("
    // NormalMap fragment
    float normalScale = 1.0;
    vec2 TBNUV = gl_FrontFacing ? vBumpUV : -vBumpUV;
    mat3 TBN = cotangent_frame(normalW*normalScale, vPositionW, TBNUV, vTangentSpaceParams);
    normalW = perturbNormal(TBN, texture(bumpSampler, vBumpUV+uvOffset).xyz, vBumpInfos.y);
    normalW = gl_FrontFacing ? -normalW : normalW;
            ");
        }
    };

	public function new() {
        super();

        this.uBumpInfos.set( 0, 1, 0.0500 );
        this.uTangentSpaceParams.set( -1, 1 );
    }
}