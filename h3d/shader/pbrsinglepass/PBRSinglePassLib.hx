package h3d.shader.pbrsinglepass;

class PBRSinglePassLib extends hxsl.Shader  {

	static var SRC = {

        @const var rgbdDecodeBRDF: Bool;
        @const var rgbdDecodeEnv : Bool;
        
        @keep @global var environmentBrdfSampler : Sampler2D;
        @keep @global var reflectionSampler : SamplerCube;
        
        // @keep @param var clearCoatSampler : SamplerCube;

        @param var uAlbedoColor : Vec4;                                 // uniform vec4 vAlbedoColor;
        @param var uAlbedoInfos : Vec2;                                 // uniform vec2 vAlbedoInfos;
        @param var uAmbientInfos : Vec4;                                // uniform vec4 vAmbientInfos;

        @param var uReflectionColor : Vec3;
        @param var uReflectionMicrosurfaceInfos : Vec3;
        @param var uReflectionInfos : Vec2;
        @param var uReflectionMatrix : Mat4;

        // @param var uReflectivityColor : Vec4;
        // @param var uMetallicReflectanceFactors : Vec4;

        @param var vSphL00 : Vec3;                                // uniform vec3 vSphL00;
        @param var vSphL1_1 : Vec3;                                     // uniform vec3 vSphL1_1;
        @param var vSphL10 : Vec3;                                      // uniform vec3 vSphL10;
        @param var vSphL11 : Vec3;                                      // uniform vec3 vSphL11;
        @param var vSphL2_2 : Vec3;                                     // uniform vec3 vSphL2_2;
        @param var vSphL2_1 : Vec3;                                     // uniform vec3 vSphL2_1;
        @param var vSphL20 : Vec3;                                      // uniform vec3 vSphL20;
        @param var vSphL21 : Vec3;                                      // uniform vec3 vSphL21;
        @param var vSphL22 : Vec3;                                      // uniform vec3 vSphericalL22;

        @keep @var var vPositionW : Vec3;                                     // varying vec3 vPositionW;
        @keep @var var vNormalW : Vec3;                                       // varying vec3 vNormalW;
        @keep @var var vEyePosition : Vec3;

        @keep @var var vMainUV1 : Vec2; 

        @keep @keepv @var var vEnvironmentIrradiance : Vec3;

        // var PI : Float;                         // = 3.1415926535897932384626433832795;
        // var MINIMUMVARIANCE : Float;
        // var LinearEncodePowerApprox : Float;    // = 2.2;
        // var GammaEncodePowerApprox : Float;     // = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        // var LuminanceEncodeApprox : Vec3;       // = vec3(0.2126,0.7152,0.0722);
        // var LuminanceEncodeApproxX : Float;     // = 0.2126;
        // var LuminanceEncodeApproxY: Float;      // = 0.7152;
        // var LuminanceEncodeApproxZ : Float;     // = 0.0722
        // var Epsilon : Float;                    // = 0.0000001;
        // var rgbdMaxRange : Float;               // = 255.0;

        @keep var reflectionMatrix : Mat4;
        @keep @keepv var vSphericalL00 : Vec3; 
        @keep @keepv var vSphericalL1_1 : Vec3;
        @keep @keepv var vSphericalL10 : Vec3; 
        @keep @keepv var vSphericalL11 : Vec3; 
        @keep @keepv var vSphericalL2_2 : Vec3;
        @keep @keepv var vSphericalL2_1 : Vec3;
        @keep @keepv var vSphericalL20 : Vec3; 
        @keep @keepv var vSphericalL21 : Vec3; 
        @keep @keepv var vSphericalL22 : Vec3; 

        @keep var vAlbedoColor : Vec4;
        @keep var vAlbedoInfos : Vec2;
        @keep var vAmbientInfos : Vec4;

        @keep var vReflectionColor : Vec3;
        @keep var vReflectionMicrosurfaceInfos : Vec3;
        @keep var vReflectionInfos : Vec2;
        @keep var vReflectionMatrix : Mat4;

        @keep var vReflectivityColor : Vec4;
        @keep var vMetallicReflectanceFactors : Vec4;
        @keep var vReflectivityInfos : Vec3;


        // @keep var environmentBrdfSamp : Vec4;

        @keep var debugVar:Vec4;

        // function saturate(x:Float):Float { 
        //     return clamp(x,0.0,1.0);
        // }

        // function saturate_V3(x:Vec3):Vec3 { 
        //     return clamp(x,0.0,1.0);
        // }

        // function absEps(x:Float):Float {
        //     return abs(x)+Epsilon;
        // }

        // function maxEps(x:Float):Float {
        //     return max(x,Epsilon);
        // }

        // function saturateEps(x:Float):Float { 
        //     return clamp(x,Epsilon,1.0);
        // }

        // function toLinearSpace(color:Float):Float {
        //     return pow(color, LinearEncodePowerApprox);
        // }

        // function toLinearSpace_V3(color:Vec3):Vec3 {
        //     return pow(color, vec3(LinearEncodePowerApprox));
        // }

        // function toLinearSpace4(color:Vec4):Vec4 {
        //     return vec4(pow(color.rgb, vec3(LinearEncodePowerApprox)), color.a);
        // }

        // function toGammaSpace(color:Float):Float {
        //     return pow(color, GammaEncodePowerApprox);
        // }

        // function toGammaSpace_V3(color:Vec3):Vec3 {
        //     return pow(color, vec3(GammaEncodePowerApprox));
        // }

        // function toGammaSpace_V4(color:Vec4):Vec4 {
        //     return vec4(pow(color.rgb, vec3(GammaEncodePowerApprox)), color.a);
        // }

        // function square(value:Float):Float {
        //     return value * value;
        // }

		// function pow5(value:Float):Float {
        //     var sq = value * value;
        //     return sq * sq * value;
        // }

        // function getLuminance(color:Vec3):Float {
        //     return clamp(dot(color, LuminanceEncodeApprox),0.,1.);
        // }
        
        // function toRGBD(color:Vec3):Vec4 {
        //     var maxRGB = maxEps(max(color.r, max(color.g, color.b))); //float
        //     var D = max(rgbdMaxRange / maxRGB, 1.); //float
        //     D = clamp(floor(D) / 255.0, 0., 1.);
        //     var rgb = color.rgb * vec3(D); //vec3
        //     rgb = toGammaSpace3(rgb);
        //     return vec4(clamp(rgb, 0., 1.), D);
        // }

        // function fromRGBD(rgbd:Vec4):Vec3 {
        //     rgbd.rgb = toLinearSpace3(rgbd.bgr);
        //     return rgbd.rgb / vec3(rgbd.a);
        // }
        
        // function fromRGBD_BGR(rgbd:Vec4):Vec3 {
        //     rgbd.rgb = toLinearSpace(rgbd.bgr);
        //     return rgbd.rgb / vec3(rgbd.a);
        // }

		// function fresnelGrazingReflectance(reflectance0:Float):Float {
        //     var reflectance90 = saturate(reflectance0 * 25.0); //float
        //     return reflectance90;
        // }

        // function convertRoughnessToAverageSlope( roughness:Float ):Float {
        //     return square(roughness)+MINIMUMVARIANCE;
        // }
        
        // function getAARoughnessFactors(normalVector:Vec3):Vec2 {
        //     var nDfdx:Vec3 = dFdx(normalVector.xyz);
        //     var nDfdy:Vec3 = dFdy(normalVector.xyz);
        //     var slopeSquare:Float = max(dot(nDfdx, nDfdx), dot(nDfdy, nDfdy));
        //     var geometricRoughnessFactor:Float = pow(saturate(slopeSquare), 0.333);
        //     var geometricAlphaGFactor:Float = sqrt(slopeSquare);
        //     geometricAlphaGFactor *= 0.75;
        //     return vec2(geometricRoughnessFactor, geometricAlphaGFactor);
        // }

        // function computeEnvironmentIrradiance( normal:Vec3 ):Vec3 {
        //     // return vSphericalL00 +
        //     //     vSphericalL1_1 * (normal.y) +
        //     //     vSphericalL10 * (normal.z) +
        //     //     vSphericalL11 * (normal.x) +
        //     //     vSphericalL2_2 * (normal.y * normal.x) +
        //     //     vSphericalL2_1 * (normal.y * normal.z) +
        //     //     vSphericalL20 * ((3.0 * normal.z * normal.z) - 1.0) +
        //     //     vSphericalL21 * (normal.z * normal.x) +
        //     //     vSphericalL22 * (normal.x * normal.x - (normal.y * normal.y));
        //     var envIrrandiance:Vec3 = vSphericalL00;
        //     envIrrandiance += vSphericalL1_1 * (normal.y);
        //     envIrrandiance += vSphericalL10 * (normal.z);
        //     envIrrandiance += vSphericalL11 * (normal.x);
        //     envIrrandiance += vSphericalL2_2 * (normal.y * normal.x);
        //     envIrrandiance += vSphericalL2_1 * (normal.y * normal.z);
        //     envIrrandiance += vSphericalL20 * ((3.0 * normal.z * normal.z) - 1.0);
        //     envIrrandiance += vSphericalL21 * (normal.z * normal.x);
        //     envIrrandiance += vSphericalL22 * (normal.x * normal.x - (normal.y * normal.y));
        //     return envIrrandiance;
        // }

        // function getEnergyConservationFactor( specularEnvironmentR0:Vec3, environmentBrdf:Vec3):Vec3 {
        //     return 1.0 + specularEnvironmentR0 * (1.0 / environmentBrdf.y - 1.0);
        // }

        // function getBRDFLookup(NdotV:Float, perceptualRoughness:Float):Vec3 {
        //     var UV = vec2(NdotV, perceptualRoughness); //vec2
        //     var brdfLookup = environmentBrdfSampler.get(UV); //vec4
        //     if (rgbdDecodeBRDF) {
        //         brdfLookup.rgb = fromRGBD_BGR(brdfLookup.rgba);
        //     }
        //     return brdfLookup.rgb;
        // }

        // function getReflectanceFromBRDFLookup(specularEnvironmentR0:Vec3, specularEnvironmentR90:Vec3, environmentBrdf:Vec3):Vec3 {
		// 	var reflectance = (specularEnvironmentR90 - specularEnvironmentR0) * vec3(environmentBrdf.x) + specularEnvironmentR0 * vec3(environmentBrdf.y);
		// 	return reflectance;
		// }

        // function getReflectanceFromBRDFLookup2(specularEnvironmentR0:Vec3, environmentBrdf:Vec3):Vec3 {
		// 	var reflectance = mix(environmentBrdf.xxx, environmentBrdf.yyy, specularEnvironmentR0);
		// 	return reflectance;
		// }
		
        // function getLodFromAlphaG(cubeMapDimensionPixels:Float, microsurfaceAverageSlope:Float):Float {
        //     var microsurfaceAverageSlopeTexels = cubeMapDimensionPixels * microsurfaceAverageSlope; //float
        //     var lod = log2(microsurfaceAverageSlopeTexels); //float
        //     return lod;
        // }

        // function environmentRadianceOcclusion(ambientOcclusion:Float, NdotVUnclamped:Float):Float {
        //     var temp = NdotVUnclamped + ambientOcclusion; //float
        //     return saturate(square(temp) - 1.0 + ambientOcclusion);
        // }

        // function environmentHorizonOcclusion(view:Vec3, normal:Vec3, geometricNormal:Vec3):Float {
        //     var reflection = reflect(view, normal); //vec3
        //     var temp = saturate(1.0 + 1.1 * dot(reflection, geometricNormal)); //float
        //     return square(temp);
        // }

        // function computeCubicCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
        //     var viewDir = normalize(worldPos.xyz - eyePosition); //vec3
        //     var coords = reflect(viewDir, worldNormal); //vec3
        //     coords = (reflectionMatrix * vec4(coords, 0)).xyz; //coords = vec3(reflectionMatrix * vec4(coords, 0));
        //     return coords;
        // }

        // function computeReflectionCoords(worldPos:Vec4, worldNormal:Vec3):Vec3 {
        //     return computeCubicCoords(worldPos, worldNormal, vEyePosition.xyz, reflectionMatrix);
        // }

        
        // function getSheenReflectanceFromBRDFLookup( reflectance0:Vec3, environmentBrdf:Vec3):Vec3 {
        //     var sheenEnvironmentReflectance:Vec3 = reflectance0 * environmentBrdf.b;
        //     return sheenEnvironmentReflectance;
        // }

        // function normalDistributionFunction_CharlieSheen( NdotH:Float, alphaG:Float):Float {
        //     var invR:Float = 1. / alphaG;
        //     var cos2h:Float = NdotH * NdotH;
        //     var sin2h:Float = 1. - cos2h;
        //     return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
        // }

        // function visibility_Ashikhmin( NdotL:Float, NdotV:Float):Float {
        //     return 1. / (4. * (NdotL + NdotV - NdotL * NdotV));
        // }

        // function getR0RemappedForClearCoat(f0:Vec3):Vec3 {
        //     // IF MOBILE DEF: return saturate3( f0 * (f0 * 0.526868 + 0.529324) - 0.0482256);
        //     return saturate(f0 * (f0 * (0.941892 - 0.263008 * f0) + 0.346479) - 0.0285998);
        // }
        
        // function cotangent_frameWithTS(normal:Vec3, p:Vec3, uv:Vec2, tangentSpaceParams:Vec2):Mat3 {
        //     uv = uv;// gl_FrontFacing ? uv : -uv;
        //     var dp1:Vec3 = dFdx(p); //vec3
        //     var dp2:Vec3 = dFdy(p); //vec3
        //     var duv1:Vec2 = dFdx(uv); //vec2
        //     var duv2:Vec2 = dFdy(uv); //vec2
        //     var dp2perp:Vec3 = cross(dp2, normal); //vec3 cross( dFdy(vPositionW), vNormal )
        //     var dp1perp:Vec3 = cross(normal, dp1); //vec3
        //     var tangent:Vec3 = dp2perp * vec3(duv1.x) + dp1perp * vec3(duv2.x); //vec3
        //     var bitangent:Vec3 = dp2perp * vec3(duv1.y) + dp1perp * vec3(duv2.y); //vec3
        //     tangent *= vec3(tangentSpaceParams.x);
        //     bitangent *= vec3(tangentSpaceParams.y);
        //     var invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent))); //float
        //     return mat3(tangent * invmax, bitangent * invmax, normal);
        // }

        // function perturbNormal(cotangentFrame:Mat3, textureSample:Vec3, scale:Float):Vec3 {
        //     textureSample = textureSample * 2.0 - 1.0;
        //     textureSample = normalize(vec3(textureSample.x, textureSample.y, textureSample.z) * vec3(scale, scale, 1.0));
        //     return normalize( cotangentFrame * textureSample ); 
        // }

        // function fresnelSchlickGGX(VdotH:Float, reflectance0:Float, reflectance90:Float):Float {
        //     return reflectance0 + (reflectance90 - reflectance0) * pow5(1.0 - VdotH);
        // }

		// function fresnelSchlickGGX_V3(VdotH:Float, reflectance0:Vec3, reflectance90:Vec3):Vec3 {
        //     return reflectance0 + (reflectance90 - reflectance0) * pow5(1.0 - VdotH);
        // }

        // function normalDistributionFunction_TrowbridgeReitzGGX(NdotH:Float, alphaG:Float):Float {
        //     var a2 = square(alphaG); //float
        //     var d = NdotH * NdotH * (a2 - 1.0) + 1.0; //float
        //     return a2 / (PI * d * d);
        // }

        // function smithVisibility_GGXCorrelated(NdotL:Float, NdotV:Float, alphaG:Float):Float {
        //     var a2 = alphaG * alphaG; //float
        //     var GGXV = NdotL * sqrt(NdotV * (NdotV - a2 * NdotV) + a2); //float
        //     var GGXL = NdotV * sqrt(NdotL * (NdotL - a2 * NdotL) + a2); //float
        //     return 0.5 / (GGXV + GGXL);
        // }

		// function computeHemisphericDiffuseLighting(infoNdotL:Float, lightColor:Vec3, groundColor:Vec3):Vec3 {
        //     return mix(groundColor, lightColor, infoNdotL);
        // }
 
		// function computeSpecularLighting(infoH:Vec3, infoRoughness:Float, infoVdotH:Float, infoNdotL:Float, infoNdotV:Float, infoAttenuation:Float, N:Vec3, reflectance0:Vec3, reflectance90:Vec3, geometricRoughnessFactor:Float, lightColor:Vec3):Vec3 {
		// 	var NdotH = saturateEps(dot(N, infoH)); //float
		// 	var roughness = max(infoRoughness, geometricRoughnessFactor);  //float
		// 	var alphaG = convertRoughnessToAverageSlope(roughness); //float
		// 	var fresnel = fresnelSchlickGGX_V3(infoVdotH, reflectance0, reflectance90); //vec3
		// 	var distribution = normalDistributionFunction_TrowbridgeReitzGGX(NdotH, alphaG);  //float
		// 	var smithVisibility = smithVisibility_GGXCorrelated(infoNdotL, infoNdotV, alphaG); //float
		// 	var specTerm = fresnel * distribution * smithVisibility; //vec3
		// 	return specTerm * infoAttenuation * infoNdotL * lightColor;
        // }
        
        // function __init__() {

        //     debugVar = vec4(0,0,0,1);

        //     PI = 3.1415926535897932384626433832795;
        //     // MINIMUMVARIANCE = 0.0005;

        //     vSphericalL00 = vSphL00;
        //     vSphericalL10 = vSphL10;
        //     vSphericalL11 = vSphL11;
        //     vSphericalL20 = vSphL20;
        //     vSphericalL21 = vSphL21;
        //     vSphericalL22 = vSphL22;
        //     vSphericalL1_1 = vSphL1_1;
        //     vSphericalL2_1 = vSphL2_1;
        //     vSphericalL2_2 = vSphL2_2;
                       
        //     // LinearEncodePowerApprox  = 2.2;
        //     // GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        //     // LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
        //     LuminanceEncodeApproxX  = 0.2126;
        //     LuminanceEncodeApproxY = 0.7152;
        //     LuminanceEncodeApproxZ  = 0.0722;
        //     // Epsilon = 0.0000001;

        //     // rgbdMaxRange = 255.0;

        //     // environmentBrdfSamp = environmentBrdfSampler.get(UV);
        // }

        // function __init__frgament() {

        //     debugVar = vec4(0,0,0,1);

        //     PI = 3.1415926535897932384626433832795;
        //     // MINIMUMVARIANCE = 0.0005;

        //     // LinearEncodePowerApprox  = 2.2;
        //     // GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        //     // LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
        //     LuminanceEncodeApproxX  = 0.2126;
        //     LuminanceEncodeApproxY = 0.7152;
        //     LuminanceEncodeApproxZ  = 0.0722;
        //     // Epsilon = 0.0000001;

        //     // rgbdMaxRange = 255.0;
        // }

//         fragfunction("extensions",
// "
// #extension GL_OES_standard_derivatives : enable
// #extension GL_EXT_shader_texture_lod : enable
// "); 

        vertfunction("defines",
"
#define RECIPROCAL_PI2 0.15915494
#define RECIPROCAL_PI 0.31830988618
#define MINIMUMVARIANCE 0.0005

#define FRESNEL_MAXIMUM_ON_ROUGH 0.25

#define CLEARCOATREFLECTANCE90 1.0

const float PI = 3.1415926535897932384626433832795;
const float HALF_MIN = 5.96046448e-08;
const float LinearEncodePowerApprox = 2.2;
const float GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
const vec3 LuminanceEncodeApprox = vec3(0.2126, 0.7152, 0.0722);
const float Epsilon = 0.0000001;

#define saturate(x) clamp(x, 0.0, 1.0)
#define absEps(x) abs(x)+Epsilon
#define maxEps(x) max(x, Epsilon)
#define saturateEps(x) clamp(x, Epsilon, 1.0)
//#define sampleReflectionLod(s, c, l) textureLod(s, c, l)
#define sampleReflectionLod(s, c, l) textureLod(s, vec3(c.x * -1.0, c.y, c.z), l)

");
    
        vertfunction("computeEnvironmentIrradiance",
"vec3 computeEnvironmentIrradiance(vec3 normal) {
    return vSphericalL00
    + vSphericalL1_1*(normal.y)
    + vSphericalL10*(normal.z)
    + vSphericalL11*(normal.x)
    + vSphericalL2_2*(normal.y*normal.x)
    + vSphericalL2_1*(normal.y*normal.z)
    + vSphericalL20*((3.0*normal.z*normal.z)-1.0)
    + vSphericalL21*(normal.z*normal.x)
    + vSphericalL22*(normal.x*normal.x-(normal.y*normal.y));
}");
        
        fragfunction("defines",
"
#define RECIPROCAL_PI2 0.15915494
#define RECIPROCAL_PI 0.31830988618
#define MINIMUMVARIANCE 0.0005

#define FRESNEL_MAXIMUM_ON_ROUGH 0.25

#define CLEARCOATREFLECTANCE90 1.0

const float PI = 3.1415926535897932384626433832795;
const float HALF_MIN = 5.96046448e-08;
const float LinearEncodePowerApprox = 2.2;
const float GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
const vec3 LuminanceEncodeApprox = vec3(0.2126, 0.7152, 0.0722);
const float Epsilon = 0.0000001;

#define saturate(x) clamp(x, 0.0, 1.0)
#define absEps(x) abs(x)+Epsilon
#define maxEps(x) max(x, Epsilon)
#define saturateEps(x) clamp(x, Epsilon, 1.0)
//#define sampleReflectionLod(s, c, l) textureLod(s, c, l)
#define sampleReflectionLod(s, c, l) textureLod(s, vec3(c.x * -1.0, c.y, c.z), l)

");

        fragfunction("toLinearSpace", 
"float toLinearSpace(float color) { 
    return pow(color, LinearEncodePowerApprox);
}
vec3 toLinearSpace(vec3 color) {
    return pow(color, vec3(LinearEncodePowerApprox));
}
vec4 toLinearSpace(vec4 color) {
    return vec4(pow(color.rgb, vec3(LinearEncodePowerApprox)), color.a);
}");

        fragfunction("toGammaSpace",
"vec3 toGammaSpace(vec3 color) {
    return pow(color, vec3(GammaEncodePowerApprox));
}
vec4 toGammaSpace(vec4 color) {
    return vec4(pow(color.rgb, vec3(GammaEncodePowerApprox)), color.a);
}
float toGammaSpace(float color) {
    return pow(color, GammaEncodePowerApprox);
}");

        fragfunction("square",
"float square(float value) {
    return value*value;
}
vec3 square(vec3 value) {
    return value*value;
}
");

        fragfunction("pow5",
"float pow5(float value) {
    float sq = value*value;
    return sq*sq*value;
}");

        fragfunction("getLuminance",
"float getLuminance(vec3 color) {
    return clamp(dot(color, LuminanceEncodeApprox), 0., 1.);
}");

        fragfunction("getRand",
"float getRand(vec2 seed) {
    return fract(sin(dot(seed.xy, vec2(12.9898, 78.233)))*43758.5453);
}");

        fragfunction("dither",
"float dither(vec2 seed, float varianceAmount) {
    float rand = getRand(seed);
    float dither = mix(-varianceAmount/255.0, varianceAmount/255.0, rand);
    return dither;
}");

        fragfunction("toRGBD",
"const float rgbdMaxRange = 255.0;
vec4 toRGBD(vec3 color) {
    float maxRGB = maxEps(max(color.r, max(color.g, color.b)));
    float D = max(rgbdMaxRange/maxRGB, 1.);
    D = clamp(floor(D)/255.0, 0., 1.);
    vec3 rgb = color.rgb*D;
    rgb = toGammaSpace(rgb);
    return vec4(clamp(rgb, 0., 1.), D);
}");

        fragfunction("fromRGBD",
"vec3 fromRGBD(vec4 rgbd) {
    rgbd.rgb = toLinearSpace(rgbd.rgb);
    return rgbd.rgb/rgbd.a;
}");
                            
        fragfunction("parallaxCorrectNormal",
"vec3 parallaxCorrectNormal( vec3 vertexPos, vec3 origVec, vec3 cubeSize, vec3 cubePos ) {
    vec3 invOrigVec = vec3(1.0, 1.0, 1.0)/origVec;
    vec3 halfSize = cubeSize*0.5;
    vec3 intersecAtMaxPlane = (cubePos+halfSize-vertexPos)*invOrigVec;
    vec3 intersecAtMinPlane = (cubePos-halfSize-vertexPos)*invOrigVec;
    vec3 largestIntersec = max(intersecAtMaxPlane, intersecAtMinPlane);
    float distance = min(min(largestIntersec.x, largestIntersec.y), largestIntersec.z);
    vec3 intersectPositionWS = vertexPos+origVec*distance;
    return intersectPositionWS-cubePos;
}");
                                
        fragfunction("testLightingForSSS",
"bool testLightingForSSS(float diffusionProfile) {
    return diffusionProfile<1.;
}");
                                    
        fragfunction("hemisphereCosSample",
"vec3 hemisphereCosSample(vec2 u) {
    float phi = 2.*PI*u.x;
    float cosTheta2 = 1.-u.y;
    float cosTheta = sqrt(cosTheta2);
    float sinTheta = sqrt(1.-cosTheta2);
    return vec3(sinTheta*cos(phi), sinTheta*sin(phi), cosTheta);
}");

        fragfunction("hemisphereImportanceSampleDggx",
"vec3 hemisphereImportanceSampleDggx(vec2 u, float a) {
    float phi = 2.*PI*u.x;
    float cosTheta2 = (1.-u.y)/(1.+(a+1.)*((a-1.)*u.y));
    float cosTheta = sqrt(cosTheta2);
    float sinTheta = sqrt(1.-cosTheta2);
    return vec3(sinTheta*cos(phi), sinTheta*sin(phi), cosTheta);
}");

        fragfunction("hemisphereImportanceSampleDCharlie",
"vec3 hemisphereImportanceSampleDCharlie(vec2 u, float a) {
    float phi = 2.*PI*u.x;
    float sinTheta = pow(u.y, a/(2.*a+1.));
    float cosTheta = sqrt(1.-sinTheta*sinTheta);
    return vec3(sinTheta*cos(phi), sinTheta*sin(phi), cosTheta);
}");
                            
        fragfunction("convertRoughnessToAverageSlope",
"float convertRoughnessToAverageSlope(float roughness) {
    return square(roughness)+MINIMUMVARIANCE;
}");
                                
        fragfunction("fresnelGrazingReflectance",
"float fresnelGrazingReflectance(float reflectance0) {
    float reflectance90 = saturate(reflectance0*25.0);
    return reflectance90;
}");
                                    
        fragfunction("getAARoughnessFactors",
"vec2 getAARoughnessFactors(vec3 normalVector) {
    vec3 nDfdx = dFdx(normalVector.xyz);
    vec3 nDfdy = dFdy(normalVector.xyz);
    float slopeSquare = max(dot(nDfdx, nDfdx), dot(nDfdy, nDfdy));
    float geometricRoughnessFactor = pow(saturate(slopeSquare), 0.333);
    float geometricAlphaGFactor = sqrt(slopeSquare);
    geometricAlphaGFactor *= 0.75;
    return vec2(geometricRoughnessFactor, geometricAlphaGFactor);
}");
                                           
        fragfunction("applyImageProcessing",
"vec4 applyImageProcessing(vec4 result) {
    result.rgb = toGammaSpace(result.rgb);
    result.rgb = saturate(result.rgb);
    return result;
}");

        fragfunction("computeEnvironmentIrradiance",
"vec3 computeEnvironmentIrradiance(vec3 normal) {
    return vSphericalL00
    + vSphericalL1_1*(normal.y)
    + vSphericalL10*(normal.z)
    + vSphericalL11*(normal.x)
    + vSphericalL2_2*(normal.y*normal.x)
    + vSphericalL2_1*(normal.y*normal.z)
    + vSphericalL20*((3.0*normal.z*normal.z)-1.0)
    + vSphericalL21*(normal.z*normal.x)
    + vSphericalL22*(normal.x*normal.x-(normal.y*normal.y));
}");

        fragfunction("preLightingInfo",
"struct preLightingInfo {
    vec3 lightOffset;
    float lightDistanceSquared;
    float lightDistance;
    float attenuation;
    vec3 L;
    vec3 H;
    float NdotV;
    float NdotLUnclamped;
    float NdotL;
    float VdotH;
    float roughness;
};");
                                
        fragfunction("computePointAndSpotPreLightingInfo",
"preLightingInfo computePointAndSpotPreLightingInfo(vec4 lightData, vec3 V, vec3 N) {
    preLightingInfo result;
    result.lightOffset = lightData.xyz-vPositionW;
    result.lightDistanceSquared = dot(result.lightOffset, result.lightOffset);
    result.lightDistance = sqrt(result.lightDistanceSquared);
    result.L = normalize(result.lightOffset);
    result.H = normalize(V+result.L);
    result.VdotH = saturate(dot(V, result.H));
    result.NdotLUnclamped = dot(N, result.L);
    result.NdotL = saturateEps(result.NdotLUnclamped);
    return result;
}");
                                    
        fragfunction("computeDirectionalPreLightingInfo",
"preLightingInfo computeDirectionalPreLightingInfo(vec4 lightData, vec3 V, vec3 N) {
    preLightingInfo result;
    result.lightDistance = length(-lightData.xyz);
    result.L = normalize(-lightData.xyz);
    result.H = normalize(V+result.L);
    result.VdotH = saturate(dot(V, result.H));
    result.NdotLUnclamped = dot(N, result.L);
    result.NdotL = saturateEps(result.NdotLUnclamped);
    return result;
}");

        fragfunction("computeHemisphericPreLightingInfo",
"preLightingInfo computeHemisphericPreLightingInfo(vec4 lightData, vec3 V, vec3 N) {
    preLightingInfo result;
    result.NdotL = dot(N, lightData.xyz)*0.5+0.5;
    result.NdotL = saturateEps(result.NdotL);
    result.NdotLUnclamped = result.NdotL;
    return result;
}");

        fragfunction("computeDistanceLightFalloff_Standard",
"float computeDistanceLightFalloff_Standard(vec3 lightOffset, float range) {
    return max(0., 1.0-length(lightOffset)/range);
}");
                            
        fragfunction("computeDistanceLightFalloff_Physical",
"float computeDistanceLightFalloff_Physical(float lightDistanceSquared) {
    return 1.0/maxEps(lightDistanceSquared);
}");
                                
        fragfunction("computeDistanceLightFalloff_GLTF",
"float computeDistanceLightFalloff_GLTF(float lightDistanceSquared, float inverseSquaredRange) {
    float lightDistanceFalloff = 1.0/maxEps(lightDistanceSquared);
    float factor = lightDistanceSquared*inverseSquaredRange;
    float attenuation = saturate(1.0-factor*factor);
    attenuation *= attenuation;
    lightDistanceFalloff *= attenuation;
    return lightDistanceFalloff;
}");
                                    
        fragfunction("computeDistanceLightFalloff",
"float computeDistanceLightFalloff(vec3 lightOffset, float lightDistanceSquared, float range, float inverseSquaredRange) {
    return computeDistanceLightFalloff_Physical(lightDistanceSquared);
}");

        fragfunction("computeDirectionalLightFalloff_Standard",
"float computeDirectionalLightFalloff_Standard(vec3 lightDirection, vec3 directionToLightCenterW, float cosHalfAngle, float exponent) {
    float falloff = 0.0;
    float cosAngle = maxEps(dot(-lightDirection, directionToLightCenterW));
    if (cosAngle >= cosHalfAngle) {
        falloff = max(0., pow(cosAngle, exponent));
    }
    return falloff;
}");

        fragfunction("computeDirectionalLightFalloff_Physical",
"float computeDirectionalLightFalloff_Physical(vec3 lightDirection, vec3 directionToLightCenterW, float cosHalfAngle) {
    const float kMinusLog2ConeAngleIntensityRatio = 6.64385618977;
    float concentrationKappa = kMinusLog2ConeAngleIntensityRatio/(1.0-cosHalfAngle);
    vec4 lightDirectionSpreadSG = vec4(-lightDirection*concentrationKappa, -concentrationKappa);
    float falloff = exp2(dot(vec4(directionToLightCenterW, 1.0), lightDirectionSpreadSG));
    return falloff;
}");
                            
        fragfunction("computeDirectionalLightFalloff_GLTF",
"float computeDirectionalLightFalloff_GLTF(vec3 lightDirection, vec3 directionToLightCenterW, float lightAngleScale, float lightAngleOffset) {
    float cd = dot(-lightDirection, directionToLightCenterW);
    float falloff = saturate(cd*lightAngleScale+lightAngleOffset);
    falloff *= falloff;
    return falloff;
}");
                                
        fragfunction("computeDirectionalLightFalloff",
"float computeDirectionalLightFalloff(vec3 lightDirection, vec3 directionToLightCenterW, float cosHalfAngle, float exponent, float lightAngleScale, float lightAngleOffset) {
    return computeDirectionalLightFalloff_Physical(lightDirection, directionToLightCenterW, cosHalfAngle);
}");
                                    
        fragfunction("getEnergyConservationFactor",
"vec3 getEnergyConservationFactor(const vec3 specularEnvironmentR0, const vec3 environmentBrdf) {
    return 1.0+specularEnvironmentR0*(1.0/environmentBrdf.y-1.0);
}");

        fragfunction("getBRDFLookup",
"vec3 getBRDFLookup(float NdotV, float perceptualRoughness) {
    vec2 UV = vec2(NdotV, perceptualRoughness);
    vec4 brdfLookup = texture(environmentBrdfSampler, UV);
    return brdfLookup.rgb;
}");

        fragfunction("getReflectanceFromBRDFLookup",
"vec3 getReflectanceFromBRDFLookup(const vec3 specularEnvironmentR0, const vec3 specularEnvironmentR90, const vec3 environmentBrdf) {
    vec3 reflectance = (specularEnvironmentR90-specularEnvironmentR0)*environmentBrdf.x+specularEnvironmentR0*environmentBrdf.y;
    return reflectance;
}
vec3 getReflectanceFromBRDFLookup(const vec3 specularEnvironmentR0, const vec3 environmentBrdf) {
    vec3 reflectance = mix(environmentBrdf.xxx, environmentBrdf.yyy, specularEnvironmentR0);
    return reflectance;
}");
                            
        fragfunction("fresnelSchlickGGX",
"vec3 fresnelSchlickGGX(float VdotH, vec3 reflectance0, vec3 reflectance90) {
    return reflectance0+(reflectance90-reflectance0)*pow5(1.0-VdotH);
}
float fresnelSchlickGGX(float VdotH, float reflectance0, float reflectance90) {
    return reflectance0+(reflectance90-reflectance0)*pow5(1.0-VdotH);
}");
                                
        fragfunction("normalDistributionFunction_TrowbridgeReitzGGX",
"float normalDistributionFunction_TrowbridgeReitzGGX(float NdotH, float alphaG) {
    float a2 = square(alphaG);
    float d = NdotH*NdotH*(a2-1.0)+1.0;
    return a2/(PI*d*d);
}");
                                    
        fragfunction("smithVisibility_GGXCorrelated",
"float smithVisibility_GGXCorrelated(float NdotL, float NdotV, float alphaG) {
    float a2 = alphaG*alphaG;
    float GGXV = NdotL*sqrt(NdotV*(NdotV-a2*NdotV)+a2);
    float GGXL = NdotV*sqrt(NdotL*(NdotL-a2*NdotL)+a2);
    return 0.5/(GGXV+GGXL);
}");

        fragfunction("diffuseBRDF_Burley",
"float diffuseBRDF_Burley(float NdotL, float NdotV, float VdotH, float roughness) {
    float diffuseFresnelNV = pow5(saturateEps(1.0-NdotL));
    float diffuseFresnelNL = pow5(saturateEps(1.0-NdotV));
    float diffuseFresnel90 = 0.5+2.0*VdotH*VdotH*roughness;
    float fresnel = (1.0+(diffuseFresnel90-1.0)*diffuseFresnelNL) *
    (1.0+(diffuseFresnel90-1.0)*diffuseFresnelNV);
    return fresnel/PI;
}");
                                
        fragfunction("lightingInfo",
"struct lightingInfo {
    vec3 diffuse;
};");
                                    
        fragfunction("adjustRoughnessFromLightProperties",
"float adjustRoughnessFromLightProperties(float roughness, float lightRadius, float lightDistance) {
    float lightRoughness = lightRadius/lightDistance;
    float totalRoughness = saturate(lightRoughness+roughness);
    return totalRoughness;
}");

        fragfunction("computeHemisphericDiffuseLighting",
"vec3 computeHemisphericDiffuseLighting(preLightingInfo info, vec3 lightColor, vec3 groundColor) {
    return mix(groundColor, lightColor, info.NdotL);
}");

        fragfunction("computeDiffuseLighting",
"vec3 computeDiffuseLighting(preLightingInfo info, vec3 lightColor) {
    float diffuseTerm = diffuseBRDF_Burley(info.NdotL, info.NdotV, info.VdotH, info.roughness);
    return diffuseTerm*info.attenuation*info.NdotL*lightColor;
}");
                            
        fragfunction("computeProjectionTextureDiffuseLighting",
"vec3 computeProjectionTextureDiffuseLighting(sampler2D projectionLightSampler, mat4 textureProjectionMatrix) {
    vec4 strq = textureProjectionMatrix*vec4(vPositionW, 1.0);
    strq /= strq.w;
    vec3 textureColor = texture(projectionLightSampler, strq.xy).rgb;
    return toLinearSpace(textureColor);
}");
                                
        fragfunction("getLodFromAlphaG",
"float getLodFromAlphaG(float cubeMapDimensionPixels, float microsurfaceAverageSlope) {
    float microsurfaceAverageSlopeTexels = cubeMapDimensionPixels*microsurfaceAverageSlope;
    float lod = log2(microsurfaceAverageSlopeTexels);
    return lod;
}");
                                    
        fragfunction("getLinearLodFromRoughness",
"float getLinearLodFromRoughness(float cubeMapDimensionPixels, float roughness) {
    float lod = log2(cubeMapDimensionPixels)*roughness;
    return lod;
}");

        fragfunction("environmentRadianceOcclusion",
"float environmentRadianceOcclusion(float ambientOcclusion, float NdotVUnclamped) {
    float temp = NdotVUnclamped+ambientOcclusion;
    return saturate(square(temp)-1.0+ambientOcclusion);
}");

        fragfunction("environmentHorizonOcclusion",
"float environmentHorizonOcclusion(vec3 view, vec3 normal, vec3 geometricNormal) {
    vec3 reflection = reflect(view, normal);
    float temp = saturate(1.0+1.1*dot(reflection, geometricNormal));
    return square(temp);
}");
                            
        fragfunction("computeFixedEquirectangularCoords",
"vec3 computeFixedEquirectangularCoords(vec4 worldPos, vec3 worldNormal, vec3 direction) {
    float lon = atan(direction.z, direction.x);
    float lat = acos(direction.y);
    vec2 sphereCoords = vec2(lon, lat)*RECIPROCAL_PI2*2.0;
    float s = sphereCoords.x*0.5+0.5;
    float t = sphereCoords.y;
    return vec3(s, t, 0);
}");
                                
        fragfunction("computeMirroredFixedEquirectangularCoords",
"vec3 computeMirroredFixedEquirectangularCoords(vec4 worldPos, vec3 worldNormal, vec3 direction) {
    float lon = atan(direction.z, direction.x);
    float lat = acos(direction.y);
    vec2 sphereCoords = vec2(lon, lat)*RECIPROCAL_PI2*2.0;
    float s = sphereCoords.x*0.5+0.5;
    float t = sphereCoords.y;
    return vec3(1.0-s, t, 0);
}");
                                    
        fragfunction("computeEquirectangularCoords",
"vec3 computeEquirectangularCoords(vec4 worldPos, vec3 worldNormal, vec3 eyePosition, mat4 reflectionMatrix) {
    vec3 cameraToVertex = normalize(worldPos.xyz-eyePosition);
    vec3 r = normalize(reflect(cameraToVertex, worldNormal));
    r = vec3(reflectionMatrix*vec4(r, 0));
    float lon = atan(r.z, r.x);
    float lat = acos(r.y);
    vec2 sphereCoords = vec2(lon, lat)*RECIPROCAL_PI2*2.0;
    float s = sphereCoords.x*0.5+0.5;
    float t = sphereCoords.y;
    return vec3(s, t, 0);
}");

        fragfunction("computeSphericalCoords",
"vec3 computeSphericalCoords(vec4 worldPos, vec3 worldNormal, mat4 view, mat4 reflectionMatrix) {
    vec3 viewDir = normalize(vec3(view*worldPos));
    vec3 viewNormal = normalize(vec3(view*vec4(worldNormal, 0.0)));
    vec3 r = reflect(viewDir, viewNormal);
    r = vec3(reflectionMatrix*vec4(r, 0));
    r.z = r.z-1.0;
    float m = 2.0*length(r);
    return vec3(r.x/m+0.5, 1.0-r.y/m-0.5, 0);
}");
                                
        fragfunction("computePlanarCoords",
"vec3 computePlanarCoords(vec4 worldPos, vec3 worldNormal, vec3 eyePosition, mat4 reflectionMatrix) {
    vec3 viewDir = worldPos.xyz-eyePosition;
    vec3 coords = normalize(reflect(viewDir, worldNormal));
    return vec3(reflectionMatrix*vec4(coords, 1));
}");
                                    
        fragfunction("computeCubicCoords",
"vec3 computeCubicCoords(vec4 worldPos, vec3 worldNormal, vec3 eyePosition, mat4 reflectionMatrix) {
    vec3 viewDir = normalize(worldPos.xyz-eyePosition);
    vec3 coords = reflect(viewDir, worldNormal);
    coords = vec3(reflectionMatrix*vec4(coords, 0));
    return coords;
}");

        fragfunction("computeCubicLocalCoords",
"vec3 computeCubicLocalCoords(vec4 worldPos, vec3 worldNormal, vec3 eyePosition, mat4 reflectionMatrix, vec3 reflectionSize, vec3 reflectionPosition) {
    vec3 viewDir = normalize(worldPos.xyz-eyePosition);
    vec3 coords = reflect(viewDir, worldNormal);
    coords = parallaxCorrectNormal(worldPos.xyz, coords, reflectionSize, reflectionPosition);
    coords = vec3(reflectionMatrix*vec4(coords, 0));
    return coords;
}");

        fragfunction("computeProjectionCoords",
"vec3 computeProjectionCoords(vec4 worldPos, mat4 view, mat4 reflectionMatrix) {
    return vec3(reflectionMatrix*(view*worldPos));
}");
                            
        fragfunction("computeSkyBoxCoords",
"vec3 computeSkyBoxCoords(vec3 positionW, mat4 reflectionMatrix) {
    return vec3(reflectionMatrix*vec4(positionW, 1.));
}");
                                
        fragfunction("computeReflectionCoords",
"vec3 computeReflectionCoords(vec4 worldPos, vec3 worldNormal) {
    return computeCubicCoords(worldPos, worldNormal, vEyePosition.xyz, reflectionMatrix);
}");
                                    
//         fragfunction("albedoOpacityOutParams",
// "struct albedoOpacityOutParams {
//     vec3 surfaceAlbedo;
//     float alpha;
// };");

// //         fragfunction("albedoOpacityBlock",
// // "void albedoOpacityBlock(
// //     in vec4 vAlbedoColor, out albedoOpacityOutParams outParams
// //     ) {
// //         vec3 surfaceAlbedo = vAlbedoColor.rgb;
// //         float alpha = vAlbedoColor.a;
// //         #define CUSTOM_FRAGMENT_UPDATE_ALBEDO
// //         outParams.surfaceAlbedo = surfaceAlbedo;
// //         outParams.alpha = alpha;
// //     }");

//         fragfunction("albedoOpacityBlock",
// "void albedoOpacityBlock(
// in vec4 vAlbedoColor, in vec4 albedoTexture, in vec2 albedoInfos, out albedoOpacityOutParams outParams
// ) {
//     vec3 surfaceAlbedo = vAlbedoColor.rgb;
//     float alpha = vAlbedoColor.a;
//     surfaceAlbedo *= toLinearSpace(albedoTexture.rgb);
//     surfaceAlbedo *= albedoInfos.y;    
//     #define CUSTOM_FRAGMENT_UPDATE_ALBEDO
//     outParams.surfaceAlbedo = surfaceAlbedo;
//     outParams.alpha = alpha;
// }");
    

//         fragfunction("reflectivityOutParams",
// "struct reflectivityOutParams {
//     float microSurface;
//     float roughness;
//     vec3 surfaceReflectivityColor;
//     vec3 surfaceAlbedo;
// };");
                            
//         fragfunction("reflectivityBlock",
// "void reflectivityBlock(
// in vec4 vReflectivityColor, in vec3 surfaceAlbedo, in vec4 metallicReflectanceFactors, out reflectivityOutParams outParams
// ) {
//     float microSurface = vReflectivityColor.a;
//     vec3 surfaceReflectivityColor = vReflectivityColor.rgb;
//     vec2 metallicRoughness = surfaceReflectivityColor.rg;
//     #define CUSTOM_FRAGMENT_UPDATE_METALLICROUGHNESS
//     microSurface = 1.0-metallicRoughness.g;
//     vec3 baseColor = surfaceAlbedo;
//     vec3 metallicF0 = metallicReflectanceFactors.rgb;
//     outParams.surfaceAlbedo = mix(baseColor.rgb*(1.0-metallicF0), vec3(0., 0., 0.), metallicRoughness.r);
//     surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
//     microSurface = saturate(microSurface);
//     float roughness = 1.-microSurface;
//     outParams.microSurface = microSurface;
//     outParams.roughness = roughness;
//     outParams.surfaceReflectivityColor = surfaceReflectivityColor;
// }");
                                
//         fragfunction("ambientOcclusionOutParams",
// "struct ambientOcclusionOutParams {
//     vec3 ambientOcclusionColor;
// };");
                                    
//         fragfunction("ambientOcclusionBlock",
// "void ambientOcclusionBlock(
// out ambientOcclusionOutParams outParams
// ) {
//     vec3 ambientOcclusionColor = vec3(1., 1., 1.);
//     outParams.ambientOcclusionColor = ambientOcclusionColor;
// }");
    
//         fragfunction("reflectionOutParams",
// "struct reflectionOutParams {
//     vec4 environmentRadiance;
//     vec3 environmentIrradiance;
//     vec3 reflectionCoords;
// };");

//         fragfunction("createReflectionCoords",
// "void createReflectionCoords(
// in vec3 vPositionW, in vec3 normalW, out vec3 reflectionCoords
// ) {
//     vec3 reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW);
//     reflectionCoords = reflectionVector;
// }");
                                
//         fragfunction("sampleReflectionTexture",
// "void sampleReflectionTexture(
// in float alphaG, in vec3 vReflectionMicrosurfaceInfos, in vec2 vReflectionInfos, in vec3 vReflectionColor, in samplerCube reflectionSampler, const vec3 reflectionCoords, out vec4 environmentRadiance
// ) {
//     float reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG);
//     reflectionLOD = reflectionLOD*vReflectionMicrosurfaceInfos.y+vReflectionMicrosurfaceInfos.z;
//     float requestedReflectionLOD = reflectionLOD;
//     environmentRadiance = sampleReflectionLod(reflectionSampler, reflectionCoords, reflectionLOD);
//     environmentRadiance.rgb = fromRGBD(environmentRadiance);
//     environmentRadiance.rgb *= vReflectionInfos.x;
//     environmentRadiance.rgb *= vReflectionColor.rgb;
// }");
                                    
//         fragfunction("reflectionBlock",
// "void reflectionBlock(
// in vec3 vPositionW, in vec3 normalW, in float alphaG, in vec3 vReflectionMicrosurfaceInfos, in vec2 vReflectionInfos, in vec3 vReflectionColor, in samplerCube reflectionSampler, in vec3 vEnvironmentIrradiance, out reflectionOutParams outParams
// ) {
//     vec4 environmentRadiance = vec4(0., 0., 0., 0.);
//     vec3 reflectionCoords = vec3(0.);
//     createReflectionCoords(
//     vPositionW, normalW, reflectionCoords
//     );
//     sampleReflectionTexture(
//     alphaG, vReflectionMicrosurfaceInfos, vReflectionInfos, vReflectionColor, reflectionSampler, reflectionCoords, environmentRadiance
//     );
//     vec3 environmentIrradiance = vec3(0., 0., 0.);
//     environmentIrradiance = vEnvironmentIrradiance;
//     environmentIrradiance *= vReflectionColor.rgb;
//     outParams.environmentRadiance = environmentRadiance;
//     outParams.environmentIrradiance = environmentIrradiance;
//     outParams.reflectionCoords = reflectionCoords;
// }");

        fragfunction("clearcoatOutParams",
"struct clearcoatOutParams {
    vec3 specularEnvironmentR0;
    float conservationFactor;
    vec3 clearCoatNormalW;
    vec2 clearCoatAARoughnessFactors;
    float clearCoatIntensity;
    float clearCoatRoughness;
    vec3 finalClearCoatRadianceScaled;
    vec3 energyConservationFactorClearCoat;
};");

        fragfunction("iridescenceOutParams",
"struct iridescenceOutParams {
    float iridescenceIntensity;
    float iridescenceIOR;
    float iridescenceThickness;
    vec3 specularEnvironmentR0;
};");
                            
        fragfunction("subSurfaceOutParams",
"struct subSurfaceOutParams {
    vec3 specularEnvironmentReflectance;
};");
                                
    }

    public function new() {
        super();
        
        this.rgbdDecodeBRDF =!hxd.fmt.gltf.Data.supportsHalfFloatTargetTextures;
        this.rgbdDecodeEnv = !hxd.fmt.gltf.Data.supportsHalfFloatTargetTextures;

        this.uAlbedoColor.set( 1, 1, 1, 1 );
        this.uAlbedoInfos.set( 0, 1 );
        this.uAmbientInfos.set( 0, 1, 1, 0 );

        this.vSphL00.set( 0.5444, 0.4836, 0.6262 );
        this.vSphL10.set( 0.0979, 0.0495, 0.0295 );
        this.vSphL20.set( 0.0062, -0.0018, -0.0101 );
        this.vSphL11.set( 0.0867, 0.1087, 0.1688 );
        this.vSphL21.set( 0.0408, 0.0495, 0.0935 );
        this.vSphL22.set( 0.0093, -0.0337, -0.1483 );
        this.vSphL1_1.set( 0.3098, 0.3471, 0.6107 );
        this.vSphL2_1.set( 0.0442, 0.0330, 0.0402 );
        this.vSphL2_2.set( 0.0154, 0.0403, 0.1151 );

        this.uReflectionInfos.set( 1, 0 );
        this.uReflectionColor.set( 1, 1, 1 );
        this.uReflectionMicrosurfaceInfos.set( 256, 0.8000, 0 );

        this.uReflectionMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
    }
}