package h3d.shader.pbrsinglepass;

class PBRSinglePassLib extends hxsl.Shader  {

	static var SRC = {

        @const var rgbdDecodeBRDF: Bool;
        @const var rgbdDecodeEnv : Bool;
        
        @global var environmentBrdfSampler : Sampler2D;
        @global var reflectionSampler : SamplerCube;
        
        @param var clearCoatSampler : SamplerCube;

        @param var vAlbedoColor : Vec4;                                 // uniform vec4 vAlbedoColor;
        @param var vAlbedoInfos : Vec2;                                 // uniform vec2 vAlbedoInfos;
        @param var vAmbientInfos : Vec4;                                // uniform vec4 vAmbientInfos;

        @param var vReflectionColor : Vec3;
        @param var vReflectionMicrosurfaceInfos : Vec3;
        @param var vReflectionInfos : Vec2;
        @param var vReflectionMatrix : Mat4;

        @param var vSphericalL00 : Vec3;                                // uniform vec3 vSphericalL00;
        @param var vSphericalL1_1 : Vec3;                               // uniform vec3 vSphericalL1_1;
        @param var vSphericalL10 : Vec3;                                // uniform vec3 vSphericalL10;
        @param var vSphericalL11 : Vec3;                                // uniform vec3 vSphericalL11;
        @param var vSphericalL2_2 : Vec3;                               // uniform vec3 vSphericalL2_2;
        @param var vSphericalL2_1 : Vec3;                               // uniform vec3 vSphericalL2_1;
        @param var vSphericalL20 : Vec3;                                // uniform vec3 vSphericalL20;
        @param var vSphericalL21 : Vec3;                                // uniform vec3 vSphericalL21;
        @param var vSphericalL22 : Vec3;                                // uniform vec3 vSphericalL22;

        @var var vPositionW : Vec3;                                     // varying vec3 vPositionW;
        @var var vNormalW : Vec3;                                       // varying vec3 vNormalW;
        @var var vEyePosition : Vec3;

        @var var vMainUV1 : Vec2; 

        @var var vEnvironmentIrradiance : Vec3;

        var PI : Float;                         // = 3.1415926535897932384626433832795;
        var MINIMUMVARIANCE : Float;
        var LinearEncodePowerApprox : Float;    // = 2.2;
        var GammaEncodePowerApprox : Float;     // = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        var LuminanceEncodeApprox : Vec3;       // = vec3(0.2126,0.7152,0.0722);
        var LuminanceEncodeApproxX : Float;     // = 0.2126;
        var LuminanceEncodeApproxY: Float;      // = 0.7152;
        var LuminanceEncodeApproxZ : Float;     // = 0.0722
        var Epsilon : Float;                    // = 0.0000001;
        var rgbdMaxRange : Float;               // = 255.0;

        var reflectionMatrix : Mat4;

        var debugVar:Vec4;

        function saturate(x:Float):Float { 
            return clamp(x,0.0,1.0);
        }

        function saturate_V3(x:Vec3):Vec3 { 
            return clamp(x,0.0,1.0);
        }

        function absEps(x:Float):Float {
            return abs(x)+Epsilon;
        }

        function maxEps(x:Float):Float {
            return max(x,Epsilon);
        }

        function saturateEps(x:Float):Float { 
            return clamp(x,Epsilon,1.0);
        }

        function toLinearSpace(color:Float):Float {
            return pow(color, LinearEncodePowerApprox);
        }

        function toLinearSpace_V3(color:Vec3):Vec3 {
            return pow(color, vec3(LinearEncodePowerApprox));
        }

        function toLinearSpace4(color:Vec4):Vec4 {
            return vec4(pow(color.rgb, vec3(LinearEncodePowerApprox)), color.a);
        }

        function toGammaSpace(color:Float):Float {
            return pow(color, GammaEncodePowerApprox);
        }

        function toGammaSpace_V3(color:Vec3):Vec3 {
            return pow(color, vec3(GammaEncodePowerApprox));
        }

        function toGammaSpace_V4(color:Vec4):Vec4 {
            return vec4(pow(color.rgb, vec3(GammaEncodePowerApprox)), color.a);
        }

        function square(value:Float):Float {
            return value * value;
        }

		function pow5(value:Float):Float {
            var sq = value * value;
            return sq * sq * value;
        }

        function getLuminance(color:Vec3):Float {
            return clamp(dot(color, LuminanceEncodeApprox),0.,1.);
        }
        
        function toRGBD(color:Vec3):Vec4 {
            var maxRGB = maxEps(max(color.r, max(color.g, color.b))); //float
            var D = max(rgbdMaxRange / maxRGB, 1.); //float
            D = clamp(floor(D) / 255.0, 0., 1.);
            var rgb = color.rgb * vec3(D); //vec3
            rgb = toGammaSpace_V3(rgb);
            return vec4(rgb, D);
        }

        function fromRGBD(rgbd:Vec4):Vec3 {
            rgbd.rgb = toLinearSpace_V3(rgbd.rgb); //toLinearSpace(rgbd.bgr);
            return rgbd.rgb / vec3(rgbd.a);
        }
        
        function fromRGBD_BGR(rgbd:Vec4):Vec3 {
            rgbd.rgb = toLinearSpace_V3(rgbd.bgr); //toLinearSpace(rgbd.bgr);
            return rgbd.rgb / vec3(rgbd.a);
        }
        
		function fresnelGrazingReflectance(reflectance0:Float):Float {
            var reflectance90 = saturate(reflectance0 * 25.0); //float
            return reflectance90;
        }

        function getAARoughnessFactors(normalVector:Vec3):Vec2 {
            var nDfdx:Vec3 = dFdx(normalVector.xyz);
            var nDfdy:Vec3 = dFdy(normalVector.xyz);
            var slopeSquare:Float = max(dot(nDfdx, nDfdx), dot(nDfdy, nDfdy));
            var geometricRoughnessFactor:Float = pow(saturate(slopeSquare), 0.333);
            var geometricAlphaGFactor:Float = sqrt(slopeSquare);
            geometricAlphaGFactor *= 0.75;
            return vec2(geometricRoughnessFactor, geometricAlphaGFactor);
        }

        function computeEnvironmentIrradiance( normal:Vec3 ):Vec3 {
            // return vSphericalL00 +
            //     vSphericalL1_1 * (normal.y) +
            //     vSphericalL10 * (normal.z) +
            //     vSphericalL11 * (normal.x) +
            //     vSphericalL2_2 * (normal.y * normal.x) +
            //     vSphericalL2_1 * (normal.y * normal.z) +
            //     vSphericalL20 * ((3.0 * normal.z * normal.z) - 1.0) +
            //     vSphericalL21 * (normal.z * normal.x) +
            //     vSphericalL22 * (normal.x * normal.x - (normal.y * normal.y));
            var envIrrandiance:Vec3 = vSphericalL00;
            envIrrandiance += vSphericalL1_1 * (normal.y);
            envIrrandiance += vSphericalL10 * (normal.z);
            envIrrandiance += vSphericalL11 * (normal.x);
            envIrrandiance += vSphericalL2_2 * (normal.y * normal.x);
            envIrrandiance += vSphericalL2_1 * (normal.y * normal.z);
            envIrrandiance += vSphericalL20 * ((3.0 * normal.z * normal.z) - 1.0);
            envIrrandiance += vSphericalL21 * (normal.z * normal.x);
            envIrrandiance += vSphericalL22 * (normal.x * normal.x - (normal.y * normal.y));
            return envIrrandiance;
        }

        function getEnergyConservationFactor( specularEnvironmentR0:Vec3, environmentBrdf:Vec3):Vec3 {
            return 1.0 + specularEnvironmentR0 * (1.0 / environmentBrdf.y - 1.0);
        }

        function getBRDFLookup(NdotV:Float, perceptualRoughness:Float):Vec3 {
            var UV = vec2(NdotV, perceptualRoughness); //vec2
            var brdfLookup = environmentBrdfSampler.get(UV); //vec4
            if (rgbdDecodeBRDF) {
                brdfLookup.rgb = fromRGBD_BGR(brdfLookup.rgba);
            }
            return brdfLookup.rgb;
        }

        function getReflectanceFromBRDFLookup(specularEnvironmentR0:Vec3, specularEnvironmentR90:Vec3, environmentBrdf:Vec3):Vec3 {
			var reflectance = (specularEnvironmentR90 - specularEnvironmentR0) * vec3(environmentBrdf.x) + specularEnvironmentR0 * vec3(environmentBrdf.y);
			return reflectance;
		}

        function getReflectanceFromBRDFLookup2(specularEnvironmentR0:Vec3, environmentBrdf:Vec3):Vec3 {
			var reflectance = mix(environmentBrdf.xxx, environmentBrdf.yyy, specularEnvironmentR0);
			return reflectance;
		}
		
        function convertRoughnessToAverageSlope(roughness:Float):Float {
            return square(roughness) + MINIMUMVARIANCE;
        }
        
        function getLodFromAlphaG(cubeMapDimensionPixels:Float, microsurfaceAverageSlope:Float):Float {
            var microsurfaceAverageSlopeTexels = cubeMapDimensionPixels * microsurfaceAverageSlope; //float
            var lod = log2(microsurfaceAverageSlopeTexels); //float
            return lod;
        }

        function environmentRadianceOcclusion(ambientOcclusion:Float, NdotVUnclamped:Float):Float {
            var temp = NdotVUnclamped + ambientOcclusion; //float
            return saturate(square(temp) - 1.0 + ambientOcclusion);
        }

        function environmentHorizonOcclusion(view:Vec3, normal:Vec3, geometricNormal:Vec3):Float {
            var reflection = reflect(view, normal); //vec3
            var temp = saturate(1.0 + 1.1 * dot(reflection, geometricNormal)); //float
            return square(temp);
        }

        function computeCubicCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
            var viewDir = normalize(worldPos.xyz - eyePosition); //vec3
            var coords = reflect(viewDir, worldNormal); //vec3
            coords = (reflectionMatrix * vec4(coords, 0)).xyz; //coords = vec3(reflectionMatrix * vec4(coords, 0));
            return coords;
        }

        function computeReflectionCoords(worldPos:Vec4, worldNormal:Vec3):Vec3 {
            return computeCubicCoords(worldPos, worldNormal, vEyePosition.xyz, reflectionMatrix);
        }

        
        
        
        function getSheenReflectanceFromBRDFLookup( reflectance0:Vec3, environmentBrdf:Vec3):Vec3 {
            var sheenEnvironmentReflectance:Vec3 = reflectance0 * environmentBrdf.b;
            return sheenEnvironmentReflectance;
        }

        function normalDistributionFunction_CharlieSheen( NdotH:Float, alphaG:Float):Float {
            var invR:Float = 1. / alphaG;
            var cos2h:Float = NdotH * NdotH;
            var sin2h:Float = 1. - cos2h;
            return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
        }

        function visibility_Ashikhmin( NdotL:Float, NdotV:Float):Float {
            return 1. / (4. * (NdotL + NdotV - NdotL * NdotV));
        }

        function getR0RemappedForClearCoat(f0:Vec3):Vec3 {
            // IF MOBILE DEF: return saturate3( f0 * (f0 * 0.526868 + 0.529324) - 0.0482256);
            return saturate_V3(f0 * (f0 * (0.941892 - 0.263008 * f0) + 0.346479) - 0.0285998);
        }
        
        function cotangent_frameWithTS(normal:Vec3, p:Vec3, uv:Vec2, tangentSpaceParams:Vec2):Mat3 {
            uv = uv;// gl_FrontFacing ? uv : -uv;
            var dp1:Vec3 = dFdx(p); //vec3
            var dp2:Vec3 = dFdy(p); //vec3
            var duv1:Vec2 = dFdx(uv); //vec2
            var duv2:Vec2 = dFdy(uv); //vec2
            var dp2perp:Vec3 = cross(dp2, normal); //vec3 cross( dFdy(vPositionW), vNormal )
            var dp1perp:Vec3 = cross(normal, dp1); //vec3
            var tangent:Vec3 = dp2perp * vec3(duv1.x) + dp1perp * vec3(duv2.x); //vec3
            var bitangent:Vec3 = dp2perp * vec3(duv1.y) + dp1perp * vec3(duv2.y); //vec3
            tangent *= vec3(tangentSpaceParams.x);
            bitangent *= vec3(tangentSpaceParams.y);
            var invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent))); //float
            return mat3(tangent * invmax, bitangent * invmax, normal);
        }

        function perturbNormal(cotangentFrame:Mat3, textureSample:Vec3, scale:Float):Vec3 {
            textureSample = textureSample * 2.0 - 1.0;
            textureSample = normalize(vec3(textureSample.x, textureSample.y, textureSample.z) * vec3(scale, scale, 1.0));
            return normalize( cotangentFrame * textureSample ); 
        }

        function fresnelSchlickGGX(VdotH:Float, reflectance0:Float, reflectance90:Float):Float {
            return reflectance0 + (reflectance90 - reflectance0) * pow5(1.0 - VdotH);
        }

		function fresnelSchlickGGX_V3(VdotH:Float, reflectance0:Vec3, reflectance90:Vec3):Vec3 {
            return reflectance0 + (reflectance90 - reflectance0) * pow5(1.0 - VdotH);
        }

        function normalDistributionFunction_TrowbridgeReitzGGX(NdotH:Float, alphaG:Float):Float {
            var a2 = square(alphaG); //float
            var d = NdotH * NdotH * (a2 - 1.0) + 1.0; //float
            return a2 / (PI * d * d);
        }

        function smithVisibility_GGXCorrelated(NdotL:Float, NdotV:Float, alphaG:Float):Float {
            var a2 = alphaG * alphaG; //float
            var GGXV = NdotL * sqrt(NdotV * (NdotV - a2 * NdotV) + a2); //float
            var GGXL = NdotV * sqrt(NdotL * (NdotL - a2 * NdotL) + a2); //float
            return 0.5 / (GGXV + GGXL);
        }

		function computeHemisphericDiffuseLighting(infoNdotL:Float, lightColor:Vec3, groundColor:Vec3):Vec3 {
            return mix(groundColor, lightColor, infoNdotL);
        }
 
		function computeSpecularLighting(infoH:Vec3, infoRoughness:Float, infoVdotH:Float, infoNdotL:Float, infoNdotV:Float, infoAttenuation:Float, N:Vec3, reflectance0:Vec3, reflectance90:Vec3, geometricRoughnessFactor:Float, lightColor:Vec3):Vec3 {
			var NdotH = saturateEps(dot(N, infoH)); //float
			var roughness = max(infoRoughness, geometricRoughnessFactor);  //float
			var alphaG = convertRoughnessToAverageSlope(roughness); //float
			var fresnel = fresnelSchlickGGX_V3(infoVdotH, reflectance0, reflectance90); //vec3
			var distribution = normalDistributionFunction_TrowbridgeReitzGGX(NdotH, alphaG);  //float
			var smithVisibility = smithVisibility_GGXCorrelated(infoNdotL, infoNdotV, alphaG); //float
			var specTerm = fresnel * distribution * smithVisibility; //vec3
			return specTerm * infoAttenuation * infoNdotL * lightColor;
        }
        
        function __init__() {

            debugVar = vec4(0,0,0,1);

            PI = 3.1415926535897932384626433832795;
            MINIMUMVARIANCE = 0.0005;

            LinearEncodePowerApprox  = 2.2;
            GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            LuminanceEncodeApproxX  = 0.2126;
            LuminanceEncodeApproxY = 0.7152;
            LuminanceEncodeApproxZ  = 0.0722;
            Epsilon = 0.0000001;

            rgbdMaxRange = 255.0;
        }

        function __init__frgament() {

            debugVar = vec4(0,0,0,1);

            PI = 3.1415926535897932384626433832795;
            MINIMUMVARIANCE = 0.0005;

            LinearEncodePowerApprox  = 2.2;
            GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            LuminanceEncodeApproxX  = 0.2126;
            LuminanceEncodeApproxY = 0.7152;
            LuminanceEncodeApproxZ  = 0.0722;
            Epsilon = 0.0000001;

            rgbdMaxRange = 255.0;
        }
    }

    public function new() {
        super();
        
        this.rgbdDecodeBRDF =!hxd.fmt.gltf.Data.supportsHalfFloatTargetTextures;
        this.rgbdDecodeEnv = !hxd.fmt.gltf.Data.supportsHalfFloatTargetTextures;

        this.vAlbedoColor.set( 1, 1, 1, 1 );
        this.vAlbedoInfos.set( 0, 1 );
        this.vAmbientInfos.set( 0, 1, 1, 0 );

        this.vSphericalL00.set( 0.5444, 0.4836, 0.6262 );
        this.vSphericalL10.set( 0.0979, 0.0495, 0.0295 );
        this.vSphericalL20.set( 0.0062, -0.0018, -0.0101 );
        this.vSphericalL11.set( 0.0867, 0.1087, 0.1688 );
        this.vSphericalL21.set( 0.0408, 0.0495, 0.0935 );
        this.vSphericalL22.set( 0.0093, -0.0337, -0.1483 );
        this.vSphericalL1_1.set( 0.3098, 0.3471, 0.6107 );
        this.vSphericalL2_1.set( 0.0442, 0.0330, 0.0402 );
        this.vSphericalL2_2.set( 0.0154, 0.0403, 0.1151 );

        this.vReflectionInfos.set( 1, 0 );
        this.vReflectionColor.set( 1, 1, 1 );
        this.vReflectionMicrosurfaceInfos.set( 256, 0.8000, 0 );

        this.vReflectionMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
    }
}