package h3d.shader;        

class PBRSinglePass extends hxsl.Shader {

	static var SRC = {

        // Can't have @const Floats

        // @const var PI : Float = 3.1415926535897932384626433832795;
        // @const var LinearEncodePowerApprox : Float = 2.2;
        // @const var GammaEncodePowerApprox : Float = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        // // @const var LuminanceEncodeApprox : Vec3 = vec3(0.2126,0.7152,0.0722);
        // @const var LuminanceEncodeApproxX : Float = 0.2126;
        // @const var LuminanceEncodeApproxY: Float = 0.7152;
        // @const var LuminanceEncodeApproxZ : Float = 0.0722;
        // @const var Epsilon : Float = 0.0000001;

        // @const var rgbdMaxRange : Float = 255.0;

        // @const var RECIPROCAL_PI2 : Float = 0.15915494;
        // @const var RECIPROCAL_PI : Float = 0.31830988618;
        // @const var MINIMUMVARIANCE : Float = 0.0005;

        
        @global var camera : {
			var view : Mat4;
			var proj : Mat4;
			var position : Vec3;
			var projFlip : Float;
			var projDiag : Vec3;
			var viewProj : Mat4;
			var inverseViewProj : Mat4;
			var zNear : Float;
			var zFar : Float;
			@var var dir : Vec3;
		};

		@global var global : {
			var time : Float;
			var pixelSize : Vec2;
			@perObject var modelView : Mat4;
			@perObject var modelViewInverse : Mat4;
		};

        // @global var PreLightingInfo : {
        //     var lightOffset:Vec3;
        //     var lightDistanceSquared:Float;
        //     var lightDistance:Float;
        //     var attenuation:Float;
        //     var L:Vec3;
        //     var H:Vec3;
        //     var NdotV:Float;
        //     var NdotLUnclamped:Float;
        //     var NdotL:Float;
        //     var VdotH:Float;
        //     var roughness:Float;
        // };
        
        // @global var LightingInfo : {
        //     var diffuse:Vec3;
        // };
        
    
        // VERTEX 
		@input var input : {
			var position : Vec3;                                        // attribute vec3 position;    
			var normal : Vec3;                                          // attribute vec3 normal;
			var uv : Vec2;                                              // attribute vec2 uv;
		};

        @param var albedoSampler : Sampler2D;                           // uniform sampler2D albedoSampler;
        @param var ambientSampler : Sampler2D;                          // uniform sampler2D ambientSampler;
        @param var emissiveSampler : Sampler2D;                         // uniform sampler2D emissiveSampler;
        @param var reflectivitySampler : Sampler2D;                     // uniform sampler2D reflectivitySampler;
        @param var reflectionSampler : SamplerCube;                     // uniform samplerCube reflectionSampler;
        @param var environmentBrdfSampler : Sampler2D;                  // uniform sampler2D environmentBrdfSampler;
        @param var bumpSampler : Sampler2D;                             // uniform sampler2D bumpSampler;

        //@param var view : Mat4;                                         // uniform mat4 view;
        //@param var viewProjection : Mat4;                               // uniform mat4 viewProjection;
        @param var albedoMatrix : Mat4;                                 // uniform mat4 albedoMatrix;
        @param var vAlbedoInfos : Vec2;                                 // uniform vec2 vAlbedoInfos;
        @param var ambientMatrix : Mat4;                                // uniform mat4 ambientMatrix;
        @param var vAmbientInfos : Vec4;                                // uniform vec4 vAmbientInfos;
        @param var vEmissiveInfos : Vec2;                               // uniform vec2 vEmissiveInfos;
        @param var emissiveMatrix : Mat4;                               // uniform mat4 emissiveMatrix;
        @param var vReflectivityInfos : Vec3;                           // uniform vec3 vReflectivityInfos;
        @param var reflectivityMatrix : Mat4;                           // uniform mat4 reflectivityMatrix;
        @param var vBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;
        @param var bumpMatrix : Mat4;                                   // uniform mat4 bumpMatrix;
        @param var vReflectionInfos : Vec2;                             // uniform vec2 vReflectionInfos;
        @param var reflectionMatrix : Mat4;                             // uniform mat4 reflectionMatrix;

        @param var world : Mat4;                                        // uniform mat4 world;

        @var var vMainUV1 : Vec2;                                       // varying vec2 vMainUV1;
        @var var vPositionW : Vec3;                                     // varying vec3 vPositionW;
        @var var vNormalW : Vec3;                                       // varying vec3 vNormalW;
        @var var vEyePosition : Vec3;

        // FRAGMENT

        //DUPLICATE @var var vPositionW : Vec2;                                     // varying vec3 vPositionW;
        //DUPLICATE @var var vMainUV1 : Vec2;                                       // varying vec2 vMainUV1;
        //DUPLICATE @var var vNormalW : Vec2;                                       // varying vec3 vNormalW;

        @param var vReflectionColor : Vec3;                             // uniform vec3 vReflectionColor;
        @param var vAlbedoColor : Vec4;                                 // uniform vec4 vAlbedoColor;
        @param var vLightingIntensity : Vec4;                           // uniform vec4 vLightingIntensity;
        @param var vReflectivityColor : Vec4;                           // uniform vec4 vReflectivityColor;
        @param var vEmissiveColor : Vec3;                               // uniform vec3 vEmissiveColor;
        @param var visibility : Float;                                  // uniform float visibility;
        //DUPLICATE @param var vAlbedoInfos : Vec2;                                 // uniform vec2 vAlbedoInfos;
        //DUPLICATE @param var vAmbientInfos : Vec4;                                // uniform vec4 vAmbientInfos;
        //DUPLICATE @param var vBumpInfos : Vec3;                                   // uniform vec3 vBumpInfos;
        @param var vTangentSpaceParams : Vec2;                          // uniform vec2 vTangentSpaceParams;
        //DUPLICATE @param var vEmissiveInfos : Vec2;                               // uniform vec2 vEmissiveInfos;
        //DUPLICATE @param var vReflectivityInfos : Vec3;                           // uniform vec3 vReflectivityInfos;
        //DUPLICATE @param var vReflectionInfos : Vec2;                             // uniform vec2 vReflectionInfos;
        //DUPLICATE @param var reflectionMatrix : Mat4;                             // uniform mat4 reflectionMatrix;
        @param var vReflectionMicrosurfaceInfos : Vec3;                 // uniform vec3 vReflectionMicrosurfaceInfos;
        //@param var vEyePosition : Vec4;                                 // uniform vec4 vEyePosition;
        @param var vAmbientColor : Vec3;                                // uniform vec3 vAmbientColor;
        @param var vCameraInfos : Vec4;                                 // uniform vec4 vCameraInfos;

        @param var vSphericalL00 : Vec3;                                // uniform vec3 vSphericalL00;
        @param var vSphericalL1_1 : Vec3;                               // uniform vec3 vSphericalL1_1;
        @param var vSphericalL10 : Vec3;                                // uniform vec3 vSphericalL10;
        @param var vSphericalL11 : Vec3;                                // uniform vec3 vSphericalL11;
        @param var vSphericalL2_2 : Vec3;                               // uniform vec3 vSphericalL2_2;
        @param var vSphericalL2_1 : Vec3;                               // uniform vec3 vSphericalL2_1;
        @param var vSphericalL20 : Vec3;                                // uniform vec3 vSphericalL20;
        @param var vSphericalL21 : Vec3;                                // uniform vec3 vSphericalL21;
        @param var vSphericalL22 : Vec3;                                // uniform vec3 vSphericalL22;

        var output : {
			var position : Vec4;
			var color : Vec4;
			var depth : Float;
			var normal : Vec3;
			var worldDist : Float;
		};

		var relativePosition : Vec3;
		var transformedPosition : Vec3;
		var pixelTransformedPosition : Vec3;
		var transformedNormal : Vec3;
		var projectedPosition : Vec4;
		var pixelColor : Vec4;
		var depth : Float;
		var screenUV : Vec2;
		var specPower : Float;
		var specColor : Vec3;
		var worldDist : Float;

		@param var color : Vec4;
		@range(0,100) @param var specularPower : Float;
		@range(0,10) @param var specularAmount : Float;
        @param var specularColor : Vec3;

        var PI : Float;// = 3.1415926535897932384626433832795;
        var LinearEncodePowerApprox : Float;// = 2.2;
        var GammaEncodePowerApprox : Float;// = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
        var LuminanceEncodeApprox : Vec3;// = vec3(0.2126,0.7152,0.0722);
        var LuminanceEncodeApproxX : Float;// = 0.2126;
        var LuminanceEncodeApproxY: Float;// = 0.7152;
        var LuminanceEncodeApproxZ : Float;// = 0.0722;
        var Epsilon : Float;// = 0.0000001;

        var rgbdMaxRange : Float;// = 255.0;

        var RECIPROCAL_PI2 : Float;// = 0.15915494;
        var RECIPROCAL_PI : Float;// = 0.31830988618;
        var MINIMUMVARIANCE : Float;// = 0.0005;

        

        function saturate(x:Float):Float { 
            return clamp(x,0.0,1.0);
        }
        function saturateVec3(x:Vec3):Vec3 { 
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

        // function transposeMat3( inMatrix:Mat3) : Mat3 {
        //     var i0=inMatrix[0]; //vec3
        //     var i1=inMatrix[1]; //vec3
        //     var i2=inMatrix[2]; //vec3
        //     var outMatrix=mat3( //mat3
        //         vec3(i0.x,i1.x,i2.x),
        //         vec3(i0.y,i1.y,i2.y),
        //         vec3(i0.z,i1.z,i2.z)
        //     );
        //     return outMatrix;
        // }

        // function inverseMat3( inMatrix:Mat3) : Mat3 {
        //     var a00=inMatrix[0][0],a01=inMatrix[0][1],a02=inMatrix[0][2]; //float
        //     var a10=inMatrix[1][0],a11=inMatrix[1][1],a12=inMatrix[1][2]; //float
        //     var a20=inMatrix[2][0],a21=inMatrix[2][1],a22=inMatrix[2][2]; //float
        //     var b01=a22*a11-a12*a21; //float
        //     var b11=-a22*a10+a12*a20; //float
        //     var b21=a21*a10-a11*a20; //float
        //     var det=a00*b01+a01*b11+a02*b21; //float
        //     return mat3(b01,(-a22*a01+a02*a21),(a12*a01-a02*a11),
        //         b11,(a22*a00-a02*a20),(-a12*a00+a02*a10),
        //         b21,(-a21*a00+a01*a20),(a11*a00-a01*a10))/det;
        // }

        function toLinearSpace(color:Vec3):Vec3 {
            return pow(color,vec3(LinearEncodePowerApprox));
        }

        function toGammaSpaceVec3(color:Vec3):Vec3 {
            return pow(color,vec3(GammaEncodePowerApprox));
        }

        function toGammaSpaceFloat(color:Float):Float {
            return pow(color,GammaEncodePowerApprox);
        }

        function square(value:Float):Float {
            return value*value;
        }

        function pow5(value:Float):Float {
            var sq=value*value; //float
            return sq*sq*value;
        }

        function getLuminance(color:Vec3):Float {
            return clamp(dot(color,vec3(LuminanceEncodeApproxX, LuminanceEncodeApproxY, LuminanceEncodeApproxZ)),0.,1.);
        }
        
        function getRand(seed:Vec2):Float {
            return fract(sin(dot(seed.xy ,vec2(12.9898,78.233)))*43758.5453);
        }

        function dither(seed:Vec2, varianceAmount:Float):Float {
            var rand=getRand(seed); //float
            var dither=mix(-varianceAmount/255.0,varianceAmount/255.0,rand); //float
            return dither;
        }
        
        function toRGBD(color:Vec3):Vec4 {
            var maxRGB=maxEps(max(color.r,max(color.g,color.b))); //float
            var D=max(rgbdMaxRange/maxRGB,1.); //float
            D=clamp(floor(D)/255.0,0.,1.);
        
            var rgb=color.rgb*D; //vec3
        
            rgb=toGammaSpaceVec3(rgb);
            return vec4(rgb,D);
        }
        
        function fromRGBD(rgbd:Vec4):Vec3 {
            rgbd.rgb=toLinearSpace(rgbd.rgb);
            return rgbd.rgb/rgbd.a;
        }

        function convertRoughnessToAverageSlope(roughness:Float):Float {
            return square(roughness) + MINIMUMVARIANCE;
        }
        
        function fresnelGrazingReflectance(reflectance0:Float):Float {
            var reflectance90 = saturate(reflectance0 * 25.0); //float
            return reflectance90;
        }
        
        function getAARoughnessFactors(normalVector:Vec3):Vec2 {
            var nDfdx = dFdx(normalVector.xyz); //vec3
            var nDfdy = dFdy(normalVector.xyz); //vec3
            var slopeSquare = max(dot(nDfdx, nDfdx), dot(nDfdy, nDfdy)); //float
            var geometricRoughnessFactor = pow(saturate(slopeSquare), 0.333); //float
            var geometricAlphaGFactor = sqrt(slopeSquare); //float
            geometricAlphaGFactor *= 0.75;
            return vec2(geometricRoughnessFactor, geometricAlphaGFactor);
        }
        
        function applyImageProcessing(result:Vec4):Vec4 {
            result.rgb = toGammaSpaceVec3(result.rgb);
            result.rgb = saturateVec3(result.rgb);
            return result;
        }
           
        function computeEnvironmentIrradiance(normal:Vec3):Vec3 {
            return vSphericalL00 +
                vSphericalL1_1 * (normal.y) +
                vSphericalL10 * (normal.z) +
                vSphericalL11 * (normal.x) +
                vSphericalL2_2 * (normal.y * normal.x) +
                vSphericalL2_1 * (normal.y * normal.z) +
                vSphericalL20 * ((3.0 * normal.z * normal.z) - 1.0) +
                vSphericalL21 * (normal.z * normal.x) +
                vSphericalL22 * (normal.x * normal.x - (normal.y * normal.y));
        }
        
        // function computePointAndSpotPreLightingInfo(lightData:Vect, V:Vec3, N:Vec3):PreLightingInfo {
        //     var result:PreLightingInfo;
        //     result.lightOffset = lightData.xyz - vPositionW;
        //     result.lightDistanceSquared = dot(result.lightOffset, result.lightOffset);
        //     result.lightDistance = sqrt(result.lightDistanceSquared);
        //     result.L = normalize(result.lightOffset);
        //     result.H = normalize(V + result.L);
        //     result.VdotH = saturate(dot(V, result.H));
        //     result.NdotLUnclamped = dot(N, result.L);
        //     result.NdotL = saturateEps(result.NdotLUnclamped);
        //     return result;
        // }
        
        // function computeDirectionalPreLightingInfo(lightData:Vec4, V:Vec3, N:Vec3):PreLightingInfo {
        //     var result:PreLightingInfo;
        //     result.lightDistance = length(-lightData.xyz);
        //     result.L = normalize(-lightData.xyz);
        //     result.H = normalize(V + result.L);
        //     result.VdotH = saturate(dot(V, result.H));
        //     result.NdotLUnclamped = dot(N, result.L);
        //     result.NdotL = saturateEps(result.NdotLUnclamped);
        //     return result;
        // }
        
        // function computeHemisphericPreLightingInfo(lightData:Vec4, V:Vec3, N:Vec3):PreLightingInfo {
        //     var result:PreLightingInfo;
        //     result.NdotL = dot(N, lightData.xyz) * 0.5 + 0.5;
        //     result.NdotL = saturateEps(result.NdotL);
        //     result.NdotLUnclamped = result.NdotL;
        //     return result;
        // }
        
        function computeDistanceLightFalloff_Standard(lightOffset:Vec3, range:Float):Float {
            return max(0., 1.0 - length(lightOffset) / range);
        }
        
        function computeDistanceLightFalloff_Physical(lightDistanceSquared:Float):Float {
            return 1.0 / maxEps(lightDistanceSquared);
        }
        
        function computeDistanceLightFalloff_GLTF(lightDistanceSquared:Float, inverseSquaredRange:Float):Float {
            var lightDistanceFalloff = 1.0 / maxEps(lightDistanceSquared); //float
            var factor = lightDistanceSquared * inverseSquaredRange; //float
            var attenuation = saturate(1.0 - factor * factor); //float
            attenuation *= attenuation;
            lightDistanceFalloff *= attenuation;
            return lightDistanceFalloff;
        }
        
        function computeDistanceLightFalloff(lightOffset:Vec3, lightDistanceSquared:Float, range:Float, inverseSquaredRange:Float):Float {
            return computeDistanceLightFalloff_Physical(lightDistanceSquared);
        }
        
        function computeDirectionalLightFalloff_Standard(lightDirection:Vec3, directionToLightCenterW:Vec3, cosHalfAngle:Float, exponent:Float):Float {
            var falloff = 0.0; //float
            var cosAngle = maxEps(dot(-lightDirection, directionToLightCenterW)); //float
            if (cosAngle >= cosHalfAngle) {
                falloff = max(0., pow(cosAngle, exponent));
            }
            return falloff;
        }
        
        function computeDirectionalLightFalloff_Physical(lightDirection:Vec3, directionToLightCenterW:Vec3, cosHalfAngle:Float):Float {
            /*const*/ var kMinusLog2ConeAngleIntensityRatio = 6.64385618977; //float
            var concentrationKappa = kMinusLog2ConeAngleIntensityRatio / (1.0 - cosHalfAngle); //float
            var lightDirectionSpreadSG = vec4(-lightDirection * concentrationKappa, -concentrationKappa); //vec4
            var falloff = exp2(dot(vec4(directionToLightCenterW, 1.0), lightDirectionSpreadSG)); //float
            return falloff;
        }
        
        function computeDirectionalLightFalloff_GLTF(lightDirection:Vec3, directionToLightCenterW:Vec3, lightAngleScale:Float, lightAngleOffset:Float):Float {
            var cd = dot(-lightDirection, directionToLightCenterW); //float
            var falloff = saturate(cd * lightAngleScale + lightAngleOffset); //float
            falloff *= falloff;
            return falloff;
        }
        
        function computeDirectionalLightFalloff(lightDirection:Vec3, directionToLightCenterW:Vec3, cosHalfAngle:Float, exponent:Float, lightAngleScale:Float, lightAngleOffset:Float):Float {
            return computeDirectionalLightFalloff_Physical(lightDirection, directionToLightCenterW, cosHalfAngle);
        }
        
        function getEnergyConservationFactor(/*const*/ specularEnvironmentR0:Vec3, /*const*/ environmentBrdf:Vec3):Vec3 {
            return 1.0 + specularEnvironmentR0 * (1.0 / environmentBrdf.y - 1.0);
        }
        
        function getBRDFLookup(NdotV:Float, perceptualRoughness:Float):Vec3 {
            var UV = vec2(NdotV, perceptualRoughness); //vec2
            var brdfLookup = environmentBrdfSampler.get(UV); //vec4
            return brdfLookup.rgb;
        }
        
        function getReflectanceFromBRDFLookup(/*const*/ specularEnvironmentR0:Vec3, /*const*/ environmentBrdf:Vec3):Vec3 {
            var reflectance = mix(environmentBrdf.xxx, environmentBrdf.yyy, specularEnvironmentR0); //vec3
            return reflectance;
        }
        
        function fresnelSchlickGGXVec3(VdotH:Float, reflectance0:Vec3, reflectance90:Vec3):Vec3 {
            return reflectance0 + (reflectance90 - reflectance0) * pow5(1.0 - VdotH);
        }
        
        function fresnelSchlickGGXFloat(VdotH:Float, reflectance0:Float, reflectance90:Float):Float {
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
        
        function diffuseBRDF_Burley(NdotL:Float, NdotV:Float, VdotH:Float, roughness:Float):Float {
            var diffuseFresnelNV = pow5(saturateEps(1.0 - NdotL)); //float
            var diffuseFresnelNL = pow5(saturateEps(1.0 - NdotV)); //float
            var diffuseFresnel90 = 0.5 + 2.0 * VdotH * VdotH * roughness; //float
            var fresnel = //float
                (1.0 + (diffuseFresnel90 - 1.0) * diffuseFresnelNL) *
                (1.0 + (diffuseFresnel90 - 1.0) * diffuseFresnelNV);
            return fresnel / PI;
        }
        
        // function adjustRoughnessFromLightProperties(roughness:Float, lightRadius:Float, lightDistance:Float):Float {
        //     var lightRoughness = lightRadius / lightDistance; //float
        //     var totalRoughness = saturate(lightRoughness + roughness); //float
        //     return totalRoughness;
        // }
        
        // function computeHemisphericDiffuseLighting(info:PreLightingInfo, lightColor:Vec3, groundColor:Vec3):Vec3 {
        //     return mix(groundColor, lightColor, info.NdotL);
        // }
        
        // function computeDiffuseLighting(info:PreLightingInfo, lightColor:Vec3):Vec3 {
        //     var diffuseTerm = diffuseBRDF_Burley(info.NdotL, info.NdotV, info.VdotH, info.roughness); //float
        //     return diffuseTerm * info.attenuation * info.NdotL * lightColor;
        // }
        
        // function computeProjectionTextureDiffuseLighting(projectionLightSampler:Sampler2D, textureProjectionMatrix:Mat4):Vec3 {
        //     var strq = mat4mulvec4(textureProjectionMatrix, vec4(vPositionW, 1.0)); //textureProjectionMatrix * vec4(vPositionW, 1.0); //vec4
        //     strq /= strq.w;
        //     var textureColor = projectionLightSampler.get(strq.xy).rgb; //vec3
        //     return toLinearSpace(textureColor);
        // }

        // function test(m:Mat4):Vec4 {
        //     var n:Buffer<Vec4,4> = m;
        //     var v1:Vec4 = n[0];
        //     return v1.x;
        // }

        // function mat4mulvec4(m:Mat4, v:Vec4):Mat4 {
        //     // {{a, b, c, d}, {e, f, g, h}, {i, j, k, l}, {m, n, o, p}} * {w, x, y, z} = 
        //     //     {aw + bx + cy + dz, 
        //     //      ew + fx + gy + hz, 
        //     //      iw + jx + ky + lz,
        //     //      mw + nx + oy + pz}
        //     return mat4( vec4(m.x.x * v.x, m.x.y * v.y, m.x.z * v.z, m.x.w * v.w),
        //         vec4(m._21 * v.x, m._22 * v.y, m._23 * v.z, m._24 * v.w),
        //         vec4(m._31 * v.x, m._32 * v.y, m._23 * v.z, m._34 * v.w),
        //         vec4(m._31 * v.x, m._32 * v.y, m._23 * v.z, m._34 * v.w));
        // }

        // function mat3mulvec3(m:Mat3, v:Vec3):Mat3 {
        //     // {{a, b, c, d}, {e, f, g, h}, {i, j, k, l}, {m, n, o, p}} * {w, x, y, z} = 
        //     //     {aw + bx + cy + dz, 
        //     //      ew + fx + gy + hz, 
        //     //      iw + jx + ky + lz,
        //     //      mw + nx + oy + pz}
        //     return mat3( vec3(m._11 * v.x, m._12 * v.y, m._13 * v.z),
        //         vec3(m._21 * v.x, m._22 * v.y, m._23 * v.z),
        //         vec3(m._31 * v.x, m._32 * v.y, m._33 * v.z));
        // }

        function getLodFromAlphaG(cubeMapDimensionPixels:Float, microsurfaceAverageSlope:Float):Float {
            var microsurfaceAverageSlopeTexels = cubeMapDimensionPixels * microsurfaceAverageSlope; //float
            var lod = log2(microsurfaceAverageSlopeTexels); //float
            return lod;
        }
        
        function getLinearLodFromRoughness(cubeMapDimensionPixels:Float, roughness:Float):Float {
            var lod = log2(cubeMapDimensionPixels) * roughness; //float
            return lod;
        }
        
        function environmentRadianceOcclusion(ambientOcclusion:Float, NdotVUnclamped:Float):Float {
            var temp = NdotVUnclamped + ambientOcclusion; //float
            return saturate(square(temp) - 1.0 + ambientOcclusion);
        }
        
        function environmentHorizonOcclusion(view:Vec3, normal:Vec3):Float {
            var reflection = reflect(view, normal); //vec3
            var temp = saturate(1.0 + 1.1 * dot(reflection, normal)); //float
            return square(temp);
        }
        
        function perturbNormal(cotangentFrame:Mat3, textureSample:Vec3, scale:Float):Vec3 {
            textureSample = textureSample * 2.0 - 1.0;
            textureSample = normalize(textureSample * vec3(scale, scale, 1.0));
            return normalize( cotangentFrame * textureSample ); 
        }
        
        function cotangent_frameWithTS(normal:Vec3, p:Vec3, uv:Vec2, tangentSpaceParams:Vec2):Mat3 {
            uv = uv;// gl_FrontFacing ? uv : -uv;
            var dp1:Vec3 = dFdx(p); //vec3
            var dp2:Vec3 = dFdy(p); //vec3
            var duv1:Vec2 = dFdx(uv); //vec2
            var duv2:Vec2 = dFdy(uv); //vec2
            var dp2perp:Vec3 = cross(dp2, normal); //vec3 cross( dFdy(vPositionW), vNormal )
            var dp1perp:Vec3 = cross(normal, dp1); //vec3
            var tangent:Vec3 = dp2perp * duv1.x + dp1perp * duv2.x; //vec3
            var bitangent:Vec3 = dp2perp * duv1.y + dp1perp * duv2.y; //vec3
            tangent *= tangentSpaceParams.x;
            bitangent *= tangentSpaceParams.y;
            var invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent))); //float
            return mat3(tangent * invmax, bitangent * invmax, normal);
        }
        
        function perturbNormalUV(cotangentFrame:Mat3, uv:Vec2):Vec3 {
            // var bmp = bumpSampler.get(uv); //*/ vec3(-bmp.x, bmp.z, bmp.y)
            return perturbNormal(cotangentFrame, bumpSampler.get(uv).xyz, vBumpInfos.y);
        }
        
        function perturbNormalColor(cotangentFrame:Mat3, color:Vec3):Vec3 {
            return perturbNormal(cotangentFrame, color, vBumpInfos.y);
        }
        
        function cotangent_frame(normal:Vec3, p:Vec3, uv:Vec2):Mat3 {
            return cotangent_frameWithTS(normal, p, uv, vTangentSpaceParams);
        }
        
        function parallaxCorrectNormal(vertexPos:Vec3, origVec:Vec3, cubeSize:Vec3, cubePos:Vec3):Vec3 {
            var invOrigVec = vec3(1.0, 1.0, 1.0) / origVec; //vec3
            var halfSize = cubeSize * 0.5; //vec3
            var intersecAtMaxPlane = (cubePos + halfSize - vertexPos) * invOrigVec; //vec3
            var intersecAtMinPlane = (cubePos - halfSize - vertexPos) * invOrigVec; //vec3
            var largestIntersec = max(intersecAtMaxPlane, intersecAtMinPlane); //vec3
            var distance = min(min(largestIntersec.x, largestIntersec.y), largestIntersec.z); //float
            var intersectPositionWS = vertexPos + origVec * distance; //vec3
            return intersectPositionWS - cubePos;
        }
        
        function computeFixedEquirectangularCoords(worldPos:Vec4, worldNormal:Vec3, direction:Vec3):Vec3 {
            var lon = atan(direction.z, direction.x); //float
            var lat = acos(direction.y); //float
            var sphereCoords = vec2(lon, lat) * RECIPROCAL_PI2 * 2.0; //vec2
            var s = sphereCoords.x * 0.5 + 0.5; //float
            var t = sphereCoords.y; //float
            return vec3(s, t, 0);
        }
        
        function computeMirroredFixedEquirectangularCoords(worldPos:Vec4, worldNormal:Vec3, direction:Vec3):Vec3 {
            var lon = atan(direction.z, direction.x); //float
            var lat = acos(direction.y); //float
            var sphereCoords = vec2(lon, lat) * RECIPROCAL_PI2 * 2.0; //vec2
            var s = sphereCoords.x * 0.5 + 0.5; //float
            var t = sphereCoords.y; //float
            return vec3(1.0 - s, t, 0);
        }
        
        // function computeEquirectangularCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
        //     var cameraToVertex = normalize(worldPos.xyz - eyePosition); //vec3
        //     var r = normalize(reflect(cameraToVertex, worldNormal)); //vec3
        //     r = vec3((vec4(r, 0) * reflectionMatrix).rgb); // vec3(reflectionMatrix * vec4(r, 0));
        //     var lon = atan(r.z, r.x); //float
        //     var lat = acos(r.y); //float
        //     var sphereCoords = vec2(lon, lat) * RECIPROCAL_PI2 * 2.0; //vec2
        //     var s = sphereCoords.x * 0.5 + 0.5; //float
        //     var t = sphereCoords.y; //float
        //     return vec3(s, t, 0);
        // }
        
        // function computeSphericalCoords(worldPos:Vec4, worldNormal:Vec3, view:Mat4, reflectionMatrix:Mat4):Vec3 {
        //     var viewDir = normalize(vec3(view * worldPos)); //vec3
        //     var viewNormal = normalize(vec3(view * vec4(worldNormal, 0.0))); //vec3
        //     var r = reflect(viewDir, viewNormal); //vec3
        //     r = vec3(reflectionMatrix * vec4(r, 0));
        //     r.z = r.z - 1.0;
        //     var m = 2.0 * length(r); //float
        //     return vec3(r.x / m + 0.5, 1.0 - r.y / m - 0.5, 0);
        // }
        
        // function computePlanarCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
        //     var viewDir = worldPos.xyz - eyePosition; //vec3
        //     var coords = normalize(reflect(viewDir, worldNormal)); //vec3
        //     return vec3(reflectionMatrix * vec4(coords, 1));
        // }
        
        function computeCubicCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
            var viewDir = normalize(worldPos.xyz - eyePosition); //vec3
            var coords = reflect(viewDir, worldNormal); //vec3
            coords = (reflectionMatrix * vec4(coords, 0)).xyz; //coords = vec3(reflectionMatrix * vec4(coords, 0));
            return coords;
        }
        
        function computeCubicLocalCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4, reflectionSize:Vec3, reflectionPosition:Vec3):Vec3 {
            var viewDir = normalize(worldPos.xyz - eyePosition); //vec3
            var coords:Vec3 = reflect(viewDir, worldNormal); //vec3
            coords = parallaxCorrectNormal(worldPos.xyz, coords, reflectionSize, reflectionPosition);
            coords = (reflectionMatrix * vec4(coords, 0)).xyz; // coords = vec3(reflectionMatrix * vec4(coords, 0));
            return coords;
        }
        
        function computeProjectionCoords(worldPos:Vec4, view:Mat4, reflectionMatrix:Mat4):Vec3 {
            return (reflectionMatrix * (worldPos * view)).rgb; // return vec3(reflectionMatrix * (view * worldPos));
        }
        
        function computeSkyBoxCoords(positionW:Vec3, reflectionMatrix:Mat4):Vec3 {
            return (reflectionMatrix * vec4(positionW, 0)).rgb; // return vec3(reflectionMatrix * vec4(positionW, 0));
        }
        
        function computeReflectionCoords(worldPos:Vec4, worldNormal:Vec3):Vec3 {
            return computeCubicCoords(worldPos, worldNormal, vEyePosition.xyz, reflectionMatrix);
        }
        
		function __init__() {
			// relativePosition = input.position;
			// transformedPosition = relativePosition * global.modelView.mat3x4();
			// projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
			// transformedNormal = (input.normal * global.modelView.mat3()).normalize();
			// camera.dir = (camera.position - transformedPosition).normalize();
			// pixelColor = color;
			// specPower = specularPower;
			// specColor = specularColor * specularAmount;
			// screenUV = screenToUv(projectedPosition.xy / projectedPosition.w);
			// depth = projectedPosition.z / projectedPosition.w;
			// worldDist = length(transformedPosition - camera.position) / camera.zFar;
		}

        function vertex() {
            // /*@const*/ var PI : Float = 3.1415926535897932384626433832795;
            // /*@const*/ var LinearEncodePowerApprox : Float = 2.2;
            // /*@const*/ var GammaEncodePowerApprox : Float = 1.0/LinearEncodePowerApprox;
            // /*@const*/ var LuminanceEncodeApprox : Vec3 = vec3(0.2126,0.7152,0.0722);
            // /*@const*/ var Epsilon : Float = 0.0000001;

            // /*@const*/ var rgbdMaxRange : Float = 255.0;
            PI = 3.1415926535897932384626433832795;
            LinearEncodePowerApprox  = 2.2;
            GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            LuminanceEncodeApproxX  = 0.2126;
            LuminanceEncodeApproxY = 0.7152;
            LuminanceEncodeApproxZ  = 0.0722;
            Epsilon = 0.0000001;
    
            rgbdMaxRange = 255.0;
    
            RECIPROCAL_PI2 = 0.15915494;
            RECIPROCAL_PI = 0.31830988618;
            MINIMUMVARIANCE = 0.0005;

            var positionUpdated = input.position; //vec3
            var normalUpdated = input.normal; //vec3
            var uvUpdated = input.uv; //vec2
            var finalWorld = global.modelView;//world; //mat4
            // transformedPosition = positionUpdated * global.modelView.mat3x4();
            // output.position = vec4(transformedPosition, 1.0) * camera.viewProj * finalWorld; // viewProjection * finalWorld * vec4(positionUpdated, 1.0);
            var worldPos = vec4(positionUpdated, 1.0) * finalWorld; //vec4 // finalWorld * vec4(positionUpdated, 1.0)
            // vPositionW = transformedPosition.rgb; //vec3(-transformedPosition.r, transformedPosition.b, transformedPosition.g);//vec3(worldPos.rgb);
            vPositionW = vec3(transformedPosition.r, transformedPosition.b, transformedPosition.g);//vec3(worldPos.rgb);
            var normalWorld = mat3(finalWorld); //mat3
            var tmpNormal = normalUpdated * normalWorld;
            // vNormalW = normalUpdated * normalWorld;//normalize(vec3(-tmpNormal.r, tmpNormal.b, tmpNormal.g)); // normalize(normalWorld * normalUpdated);
            vNormalW = normalize(vec3(tmpNormal.r, tmpNormal.b, tmpNormal.g)); // normalize(normalWorld * normalUpdated);
            var uv2 = vec2(0., 0.); //vec2
            vMainUV1 = uvUpdated;

            vEyePosition = vec3(camera.position.r, camera.position.b, camera.position.g); //camera.position;//
        }

        function fragment() {
            // /*@const*/ var PI : Float = 3.1415926535897932384626433832795;
            // /*@const*/ var LinearEncodePowerApprox : Float = 2.2;
            // /*@const*/ var GammaEncodePowerApprox : Float = 1.0/LinearEncodePowerApprox;
            // /*@const*/ var LuminanceEncodeApprox : Vec3 = vec3(0.2126,0.7152,0.0722);
            // /*@const*/ var Epsilon : Float = 0.0000001;

            // /*@const*/ var rgbdMaxRange : Float = 255.0;
            PI = 3.1415926535897932384626433832795;
            LinearEncodePowerApprox  = 2.2;
            GammaEncodePowerApprox  = 0.45454545454545454; //1.0/LinearEncodePowerApprox;
            LuminanceEncodeApprox  = vec3(0.2126,0.7152,0.0722);
            LuminanceEncodeApproxX  = 0.2126;
            LuminanceEncodeApproxY = 0.7152;
            LuminanceEncodeApproxZ  = 0.0722;
            Epsilon = 0.0000001;
    
            rgbdMaxRange = 255.0;
    
            RECIPROCAL_PI2 = 0.15915494;
            RECIPROCAL_PI = 0.31830988618;
            MINIMUMVARIANCE = 0.0005;
            
/*OK*/      var viewDirectionW = normalize(vEyePosition.xyz - vPositionW); //vec3 // 
/*OK*/      var normalW = normalize(vNormalW); //vec3
/*OK*/      var uvOffset = vec2(0.0, 0.0); //vec2
/*OK*/      var normalScale = 1.0; //float
/*OK*/      var TBN = cotangent_frame(normalW * normalScale, vPositionW, vMainUV1); //mat3 // vBumpUV -> vMainUV1
            // var TBN = cotangent_frameWithTS(normalW, vPositionW, vMainUV1, vec2(1., 1.)); //mat3 // WithTS
/*OK*/      var normalW = perturbNormalUV(TBN, vMainUV1 + uvOffset); // vBumpUV -> vMainUV1 // added UV version
            var surfaceAlbedo = vAlbedoColor.rgb; //vec3
            var alpha = vAlbedoColor.a; //float
            var albedoTexture = albedoSampler.get(vMainUV1 + uvOffset); //vec4 // vAlbedoUV -> vMainUV1
            surfaceAlbedo *= toLinearSpace(albedoTexture.rgb);
            surfaceAlbedo *= vAlbedoInfos.y;
            var ambientOcclusionColor = vec3(1., 1., 1.); //vec3
/*OK*/      var ambientOcclusionColorMap = ambientSampler.get(vMainUV1 + uvOffset).rgb * vAmbientInfos.y; //vec3 // vAmbientUV -> vMainUV1
/*OK*/      ambientOcclusionColorMap = vec3(ambientOcclusionColorMap.r, ambientOcclusionColorMap.r, ambientOcclusionColorMap.r);
/*OK*/      ambientOcclusionColor = mix(ambientOcclusionColor, ambientOcclusionColorMap, vAmbientInfos.z);
            var microSurface = vReflectivityColor.a; //float
/*OK*/      var surfaceReflectivityColor = vReflectivityColor.rgb; //vec3
/*OK*/      var metallicRoughness = surfaceReflectivityColor.rg; //vec2
/*OK*/      var surfaceMetallicColorMap = reflectivitySampler.get(vMainUV1 + uvOffset); //vec4 // vReflectivityUV -> vMainUV1
/*OK*/      metallicRoughness.r *= surfaceMetallicColorMap.b;
/*OK*/      metallicRoughness.g *= surfaceMetallicColorMap.g;
/*OK*/      microSurface = 1.0 - metallicRoughness.g;
/*OK*/      var baseColor = surfaceAlbedo; //vec3
/*OK*/      var metallicF0 = vec3(vReflectivityColor.a, vReflectivityColor.a, vReflectivityColor.a); //vec3
/*OK*/      surfaceAlbedo = mix(baseColor.rgb * (1.0 - metallicF0.r), vec3(0., 0., 0.), metallicRoughness.r);
/*OK*/      surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
/*OK*/      microSurface = saturate(microSurface);
            var roughness = 1. - microSurface; //float
            var NdotVUnclamped = dot(normalW, viewDirectionW); //float
            var NdotV = absEps(NdotVUnclamped); //float
            var alphaG = convertRoughnessToAverageSlope(roughness); //float
            var AARoughnessFactors = getAARoughnessFactors(normalW.xyz); //vec2
            alphaG += AARoughnessFactors.y;
            var environmentRadiance = vec4(0., 0., 0., 0.); //vec4
            var environmentIrradiance = vec3(0., 0., 0.); //vec3
            var reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW); //vec3
            reflectionVector.z *= -1.0;
            var reflectionCoords = reflectionVector; //vec3
            var reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG); //float
            reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            var requestedReflectionLOD = reflectionLOD; //float
            environmentRadiance = textureLod(reflectionSampler, reflectionCoords, requestedReflectionLOD); // sampleReflectionLod
            environmentRadiance.rgb = fromRGBD(environmentRadiance);
            var irradianceVector = vec3((vec4(normalW, 0) * reflectionMatrix).rgb).xyz; //vec3 //vec3(reflectionMatrix * vec4(normalW, 0)).xyz
            environmentIrradiance = computeEnvironmentIrradiance(irradianceVector);
            // environmentIrradiance = irradianceSampler.get(reflectionCoords).rgb; // sampleReflection(irradianceSampler, reflectionCoords).rg
            // environmentIrradiance.rgb = fromRGBD(vec4(environmentIrradiance, 1.));
            environmentRadiance.rgb *= vReflectionInfos.x;
            environmentRadiance.rgb *= vReflectionColor.rgb;
            environmentIrradiance *= vReflectionColor.rgb;
            var reflectance = max(max(surfaceReflectivityColor.r, surfaceReflectivityColor.g), surfaceReflectivityColor.b); //float
            var reflectance90 = fresnelGrazingReflectance(reflectance); //float
            var specularEnvironmentR0 = surfaceReflectivityColor.rgb; //vec3
            var specularEnvironmentR90 = vec3(1.0, 1.0, 1.0) * reflectance90; //vec3
            var environmentBrdf = getBRDFLookup(NdotV, roughness); //vec3
            var energyConservationFactor = getEnergyConservationFactor(specularEnvironmentR0, environmentBrdf); //vec3
            var diffuseBase = vec3(0., 0., 0.); //vec3
            // var preInfo:PreLightingInfo;
            // var info:LightingInfo;
            var shadow = 1.; //float
            var specularEnvironmentReflectance = getReflectanceFromBRDFLookup(specularEnvironmentR0, environmentBrdf); //vec3
            var ambientMonochrome = ambientOcclusionColor.r; //float
            var seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped); //float
            specularEnvironmentReflectance *= seo;
            var eho = environmentHorizonOcclusion(-viewDirectionW, normalW); //float
            specularEnvironmentReflectance *= eho;
            var finalIrradiance = environmentIrradiance; //vec3
            finalIrradiance *= surfaceAlbedo.rgb;
            var finalRadiance = environmentRadiance.rgb; //vec3
            finalRadiance *= specularEnvironmentReflectance;
            var finalRadianceScaled = finalRadiance * vLightingIntensity.z; //vec3
            finalRadianceScaled *= energyConservationFactor;
            var finalDiffuse = diffuseBase; //vec3
            finalDiffuse *= surfaceAlbedo.rgb;
            finalDiffuse = max(finalDiffuse, 0.0);
            var finalAmbient = vAmbientColor; //vec3
            finalAmbient *= surfaceAlbedo.rgb;
            var finalEmissive = vEmissiveColor; //vec3
            var emissiveColorTex = emissiveSampler.get(vMainUV1 + uvOffset).rgb; //vec3 // vEmissiveUV -> vMainUV1
            finalEmissive *= toLinearSpace(emissiveColorTex.rgb);
            finalEmissive *= vEmissiveInfos.y;
            var ambientOcclusionForDirectDiffuse = mix(vec3(1.), ambientOcclusionColor, vAmbientInfos.w); //vec3
            var finalColor = vec4( //vec4
                finalAmbient * ambientOcclusionColor +
                finalDiffuse * ambientOcclusionForDirectDiffuse * vLightingIntensity.x +
                finalIrradiance * ambientOcclusionColor * vLightingIntensity.z +
                finalRadianceScaled +
                finalEmissive * vLightingIntensity.y,
                alpha);
            finalColor = max(finalColor, 0.0);
            finalColor = applyImageProcessing(finalColor);
            finalColor.a *= visibility;
            // var tangent = normalize(cross( dFdy(vPositionW), normalW ) * dFdx(vMainUV1).x + cross( normalW, dFdx(vPositionW) ) * dFdy(vMainUV1).x).rgb;
            // var bitangent = normalize(cross( dFdy(vPositionW), normalW ) * dFdx(vMainUV1).y + cross( normalW, dFdx(vPositionW) ) * dFdy(vMainUV1).y).rgb;
            // tangent *= vTangentSpaceParams.x;
            // bitangent *= vTangentSpaceParams.y;
            // var invmax = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
            // var tsample = bumpSampler.get(vMainUV1 + uvOffset).rgb*2.0-1.0;
            // tsample = normalize(tsample * vec3(vBumpInfos.y,vBumpInfos.y,1.));
            // var m = mat_to_34(TBN);
            // var v = mat3(TBN);
            // var wPos:Vec4 = vec4(vPositionW.xyz, 1.);
            // var viewDir=normalize(wPos.xyz-vEyePosition);
            // var coords=reflect(viewDir,normalW);
            // coords = (reflectionMatrix * vec4(coords, 0)).rgb;
            output.color = finalColor;//vec4(vec3(environmentRadiance.rgb), 1.); //finalColor;
        }
	};

	public function new() {
		super();
		this.albedoSampler = null;
        this.ambientSampler = null;
        this.emissiveSampler = null;
        this.reflectivitySampler = null;
        this.reflectionSampler = null;
        this.environmentBrdfSampler = null;
        this.bumpSampler = null;


        this.vAmbientColor.set( 0, 0, 0 );
        this.vSphericalL10.set( 0.0979, 0.0495, 0.0295 );
        //this.vEyePosition.set( 0.0025, 0.0000, 4.0361, -1 );
        this.world.loadValues([ -1, 0, 0, 0, 0, -0.0000, 1.0000, 0, 0, -1.0000, -0.0000, 0, 0, 0, 0, 1 ]);
        this.vSphericalL22.set( 0.0093, -0.0337, -0.1483 );
        this.vSphericalL11.set( 0.0867, 0.1087, 0.1688 );
        this.vSphericalL00.set( 0.5444, 0.4836, 0.6262 );
        this.vSphericalL20.set( 0.0062, -0.0018, -0.0101 );
        this.vSphericalL21.set( 0.0408, 0.0495, 0.0935 );
        this.vSphericalL2_2.set( 0.0154, 0.0403, 0.1151 );
        this.vSphericalL2_1.set( 0.0442, 0.0330, 0.0402 );
        //this.viewProjection.loadValues([ -1.0421, -0.0000, -0.0000, -0.0000, 0, 2.3652, -0.0000, -0.0000, 0.0000, -0.0000, -1.0000, -1, 0.0026, -0.0000, 3.9375, 4.0361 ]);
        //this.view.loadValues([ -1, -0.0000, -0.0000, 0, 0, 1, -0.0000, 0, 0.0000, -0.0000, -1, 0, 0.0025, -0.0000, 4.0361, 1 ]);
        this.vAlbedoInfos.set( 0, 1 );
        this.vAmbientInfos.set( 0, 1, 1, 0 );
        // this.vOpacityInfos.set( 0, 0 );
        this.vEmissiveInfos.set( 0, 1 );
        // this.vLightmapInfos.set( 0, 0 );
        this.vReflectivityInfos.set( 0, 1, 1 );
        // this.vMicroSurfaceSamplerInfos.set( 0, 0 );
        this.vReflectionInfos.set( 1, 0 );
        // this.vReflectionPosition.set( 0, 0, 0 );
        // this.vReflectionSize.set( 0, 0, 0 );
        this.vBumpInfos.set( 0, 1, 0.0500 );
        this.albedoMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]);
        this.ambientMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]);
        // this.opacityMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        this.emissiveMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]);
        // this.lightmapMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        this.reflectivityMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]);
        // this.microSurfaceSamplerMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        this.bumpMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]);
        this.vTangentSpaceParams.set( 1, -1 );
        this.reflectionMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
        this.vReflectionColor.set( 1, 1, 1 );
        this.vAlbedoColor.set( 1, 1, 1, 1 );
        this.vLightingIntensity.set( 1, 1, 1, 1 );
        this.vReflectionMicrosurfaceInfos.set( 128, 0.8000, 0 );
        // this.pointSize = 0;
        this.vReflectivityColor.set( 1, 1, 1, 0.0400 );
        this.vEmissiveColor.set( 1, 1, 1 );
        this.visibility = 1;
        // this.vClearCoatParams.set( 1, 0 );
        // this.vClearCoatRefractionParams.set( 0.0400, 0.6667, -0.5000, 2.5000 );
        // this.vClearCoatInfos.set( 0, 0 );
        // this.clearCoatMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vClearCoatBumpInfos.set( 0, 0 );
        // this.vClearCoatTangentSpaceParams.set( 0, 0 );
        // this.clearCoatBumpMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vClearCoatTintParams.set( 0, 0, 0, 0 );
        // this.clearCoatColorAtDistance = 0;
        // this.vClearCoatTintInfos.set( 0, 0 );
        // this.clearCoatTintMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vAnisotropy.set( 1, 0, 1 );
        // this.vAnisotropyInfos.set( 0, 0 );
        // this.anisotropyMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vSheenColor.set( 1, 1, 1, 1 );
        // this.vSheenRoughness = 0;
        // this.vSheenInfos.set( 0, 0 );
        // this.sheenMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vRefractionMicrosurfaceInfos.set( 0, 0, 0 );
        // this.vRefractionInfos.set( 0, 0, 0, 0 );
        // this.refractionMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vThicknessInfos.set( 0, 0 );
        // this.thicknessMatrix.loadValues( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        // this.vThicknessParam.set( 0, 1 );
        // this.vDiffusionDistance.set( 1, 1, 1 );
        // this.vTintColor.set( 1, 1, 1, 1 );
        // this.vSubSurfaceIntensity.set( 1, 1, 1 );
        
	}

}
