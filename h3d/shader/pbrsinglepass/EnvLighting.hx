package h3d.shader.pbrsinglepass;

class EnvLighting extends hxsl.Shader {

	static var SRC = {

		@param var environmentBrdfSampler : Sampler2D;

		@param var vLightData0 : Vec4;
		@param var vLightDiffuse0 : Vec4;
		@param var vLightSpecular0 : Vec4;
		@param var vLightGround0 : Vec3;
		@param var glossiness : Float;

		var MINIMUMVARIANCE : Float;
		var Epsilon : Float;
		var AARoughnessFactors:Vec2;
		
		var normalW:Vec3;
		var viewDirectionW:Vec3;

		var NdotV:Float;

		var roughness:Float;
		var surfaceReflectivityColor:Vec3;
		var energyConservationFactor:Vec3;
		var shadow:Float;
		var specularEnvironmentReflectance:Vec3;
		var diffuseBase:Vec3;
		var specularBase:Vec3;

		// LightingInfo
		var lIDiffuse:Vec3;
		var lISpecular:Vec3;

		// PreLightingInfo
        var pLILightOffset:Vec3;
        var pLILightDistanceSquared:Float;
        var pLILightDistance:Float;
        var pLIAttenuation:Float;
        var pLIL:Vec3;
        var pLIH:Vec3;
        var pLINdotV:Float;
        var pLINdotLUnclamped:Float;
        var pLINdotL:Float;
        var pLIVdotH:Float;
		var pLIRoughness:Float;
		
		var environmentBrdf:Vec3;
		var specularEnvironmentR90:Vec3;
		
		function fromRGBD(rgbd:Vec4):Vec3 {
            rgbd.rgb=toLinearSpace(rgbd.bgr);
            return rgbd.rgb/rgbd.a;
        }

        function toLinearSpace(color:Vec3):Vec3 {
            return pow(color,vec3(LinearEncodePowerApprox));
        }

        var LinearEncodePowerApprox:Float;

		function square(value:Float):Float {
            return value*value;
        }

		function saturateEps(x:Float):Float {
            return clamp(x,Epsilon,1.0);
        }

		function pow5(value:Float):Float {
            var sq=value*value; //float
            return sq*sq*value;
        }

		function fresnelGrazingReflectance(reflectance0:Float):Float {
            var reflectance90 = saturate(reflectance0 * 25.0); //float
            return reflectance90;
        }
        
        function getBRDFLookup(NdotV:Float, perceptualRoughness:Float):Vec3 {
            var UV = vec2(NdotV, perceptualRoughness); //vec2
            var brdfLookup = fromRGBD(environmentBrdfSampler.get(UV)); //vec4
            return brdfLookup.rgb;
        }
        
        function getEnergyConservationFactor(/*const*/ specularEnvironmentR0:Vec3, /*const*/ environmentBrdf:Vec3):Vec3 {
            return 1.0 + specularEnvironmentR0 * (1.0 / environmentBrdf.y - 1.0);
        }
        
        function getReflectanceFromBRDFLookup(/*const*/ specularEnvironmentR0:Vec3, /*const*/ environmentBrdf:Vec3):Vec3 {
            var reflectance = mix(environmentBrdf.xxx, environmentBrdf.yyy, specularEnvironmentR0); //vec3
            return reflectance;
        }

        function convertRoughnessToAverageSlope(roughness:Float):Float {
            return square(roughness) + MINIMUMVARIANCE;
        }

		function fresnelSchlickGGX(VdotH:Float, reflectance0:Vec3, reflectance90:Vec3):Vec3 {
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

		// function computeHemisphericPreLightingInfo(lightData:Vec4, V:Vec3, N:Vec3):PreLightingInfo {
        //     var result:PreLightingInfo;
        //     result.NdotL = dot(N, lightData.xyz) * 0.5 + 0.5;
        //     result.NdotL = saturateEps(result.NdotL);
        //     result.NdotLUnclamped = result.NdotL;
		//	   result.L = normalize(lightData.xyz);
		//	   result.H = normalize(V + result.L);
		//	   result.VdotH = saturate(dot(V, result.H));
		//     return result;
        // }

		function computeHemisphericDiffuseLighting(infoNdotL:Float, lightColor:Vec3, groundColor:Vec3):Vec3 {
            return mix(groundColor, lightColor, infoNdotL);
        }
 
		// function computeSpecularLighting(info:PreLightinInfo, N:Vec3, reflectance0:Vec3, reflectance90:Vec3, geometricRoughnessFactor:Float, lightColor:Vec3):Vec3 {
		// 	var NdotH = saturateEps(dot(N, info.H)); //float
		// 	var roughness = max(info.roughness, geometricRoughnessFactor);  //float
		// 	var alphaG = convertRoughnessToAverageSlope(roughness); //float
		// 	var fresnel = fresnelSchlickGGX(info.VdotH, reflectance0, reflectance90); //vec3
		// 	var distribution = normalDistributionFunction_TrowbridgeReitzGGX(NdotH, alphaG);  //float
		// 	var smithVisibility = smithVisibility_GGXCorrelated(info.NdotL, info.NdotV, alphaG); //float
		// 	var specTerm = fresnel * distribution * smithVisibility; //vec3
		// 	return specTerm * info.attenuation * info.NdotL * lightColor;
		// }
		function computeSpecularLighting(infoH:Vec3, infoRoughness:Float, infoVdotH:Float, infoNdotL:Float, infoNdotV:Float, infoAttenuation:Float, N:Vec3, reflectance0:Vec3, reflectance90:Vec3, geometricRoughnessFactor:Float, lightColor:Vec3):Vec3 {
			var NdotH = saturateEps(dot(N, infoH)); //float
			var roughness = max(infoRoughness, geometricRoughnessFactor);  //float
			var alphaG = convertRoughnessToAverageSlope(roughness); //float
			var fresnel = fresnelSchlickGGX(infoVdotH, reflectance0, reflectance90); //vec3
			var distribution = normalDistributionFunction_TrowbridgeReitzGGX(NdotH, alphaG);  //float
			var smithVisibility = smithVisibility_GGXCorrelated(infoNdotL, infoNdotV, alphaG); //float
			var specTerm = fresnel * distribution * smithVisibility; //vec3
			return specTerm * infoAttenuation * infoNdotL * lightColor;
		}

		// function computeHemisphericLighting(viewDirectionW:Vec3, vNormal:Vec3, lightData:Vec4, diffuseColor:Vec3, specularColor:Vec3, groundColor:Vec3, glossiness:Float):LightingInfo {
		// 	lightingInfo result;
		// 	var ndl=dot(vNormal,lightData.xyz)*0.5+0.5; //float
		// 	result.diffuse = mix(groundColor,diffuseColor,ndl); //
		// 	var angleW = normalize(viewDirectionW+lightData.xyz); //vec3
		// 	var specComp = max(0.,dot(vNormal,angleW)); //float
		// 	specComp = pow(specComp,max(1.,glossiness)); //
		// 	result.specular = specComp*specularColor; //
		// 	return result;
		// }
		
		function fragment() {
            var reflectance = max(max(surfaceReflectivityColor.r, surfaceReflectivityColor.g), surfaceReflectivityColor.b); //float
            var reflectance90 = fresnelGrazingReflectance(reflectance); //float
            var specularEnvironmentR0 = surfaceReflectivityColor.rgb; //vec3
            var specularEnvironmentR90 = vec3(1.0, 1.0, 1.0) * reflectance90; //vec3
            environmentBrdf = getBRDFLookup(NdotV, roughness); //vec3
            energyConservationFactor = getEnergyConservationFactor(specularEnvironmentR0, environmentBrdf); //vec3
			
			diffuseBase = vec3(0., 0., 0.); //vec3
            specularBase = vec3(0., 0., 0.); //vec3
			
			// Convert

			// LightingInfo
			// struct lightingInfo {
			// 	vec3 diffuse;
			// 	vec3 specular;
			// };
			
			// PreLightingInfo
			// struct preLightingInfo {
			// 	vec3 lightOffset;
			// 	float lightDistanceSquared;
			// 	float lightDistance;
			// 	float attenuation;
			// 	vec3 L;
			// 	vec3 H;
			// 	float NdotV;
			// 	float NdotLUnclamped;
			// 	float NdotL;
			// 	float VdotH;
			// 	float roughness;
			// };
			
			//preLightingInfo preInfo;
			//lightingInfo info;
			//float shadow = 1.;

			// THE FOLLOWING CHUNK SEEMS TO BE OVERWRITTEN BY THE info = computeHemisphericLighting BELOW
			// ##########################################################################################
			// preInfo = computeHemisphericPreLightingInfo(vLightData0, viewDirectionW, normalW);
			pLINdotL = dot(normalW, vLightData0.xyz) * 0.5 + 0.5;
            pLINdotL = saturateEps(pLINdotL);
            pLINdotLUnclamped = pLINdotL;
			pLIL = normalize(vLightData0.xyz);
			pLIH = normalize(viewDirectionW + pLIL);
			pLIVdotH = saturate(dot(viewDirectionW, pLIH));

			pLINdotV = NdotV; // preInfo.NdotV = NdotV;
			pLIAttenuation = 1.0; // preInfo.attenuation = 1.0;
			pLIRoughness = roughness; // preInfo.roughness = roughness;

			lIDiffuse = computeHemisphericDiffuseLighting(pLINdotL, vLightDiffuse0.rgb, vLightGround0);
			lISpecular = computeSpecularLighting(pLIH, pLIRoughness, pLIVdotH, pLINdotL, pLINdotV, pLIAttenuation, normalW, specularEnvironmentR0, specularEnvironmentR90, AARoughnessFactors.x, vLightDiffuse0.rgb);
			// ##########################################################################################
			
			// info = computeHemisphericLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0.rgb, vLightGround0, glossiness);
			// Diffuse part
			// var ld = vLightData0.xyz ;
			// var ndl = dot(normalW, ld.xyz) * 0.5 + 0.5; //float
			// lIDiffuse.rgb = mix(vLightGround0, vLightDiffuse0.rgb, ndl); //
			// // Specular part
			// var angleW = normalize(viewDirectionW + ld.xyz); //vec3
			// var specComp = max( 0., dot(normalW, angleW) ); //float
			// specComp = pow(specComp, max(1., glossiness)); //
			// testvar = vec3(specComp);
			// lISpecular = specComp * vLightSpecular0.rgb; //

			// End convert
			
			shadow = 1.; //float
			diffuseBase += lIDiffuse.rgb * shadow;
			specularBase += lISpecular * shadow;
			specularEnvironmentReflectance = getReflectanceFromBRDFLookup(specularEnvironmentR0, environmentBrdf); //vec3
        }
	}

	public function new() {
		super();

		this.vLightData0.set(0, 1, 0, 0);
		this.vLightDiffuse0.set(1, 1, 1, 1);
		this.vLightSpecular0.set(1, 1, 1, 0);
		this.vLightGround0.set(0, 0, 0);
		this.glossiness = 1;

	}
}