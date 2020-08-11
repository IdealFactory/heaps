package h3d.shader.pbrsinglepass;

class Clearcoat extends hxsl.Shader {

	static var SRC = {

        @param var environmentBrdfSampler : Sampler2D;
        @param var vReflectionColor : Vec3;
        @param var reflectionSampler : SamplerCube;
        @param var vReflectionMicrosurfaceInfos : Vec3;
        @param var vReflectionInfos : Vec2;

        @param var vClearCoatParams : Vec2;
        @param var vClearCoatRefractionParams : Vec4;

        @var var vEyePosition : Vec3;
        @var var vPositionW : Vec3;

        var normalW:Vec3;
        var geometricNormalW:Vec3;
        var viewDirectionW:Vec3;
        var specularEnvironmentR0:Vec3;
        var specularEnvironmentR90:Vec3;
        var environmentBrdf:Vec3;
        var reflectionVector:Vec3;
        var reflectionMatrix:Mat4;
        var ambientMonochrome:Float;

        var MINIMUMVARIANCE : Float;
        var LinearEncodePowerApprox : Float;// = 2.2;
        var Epsilon : Float;

        var lightingIntensity:Vec4;

        var seo:Float;
        var eho:Float;
        var specularEnvironmentReflectance:Vec3;
        var finalIrradiance:Vec3;
        var energyConservationFactor:Vec3;

        var ccOutConservationFactor:Float;
        var ccOutFinalClearCoatRadianceScaled:Vec3;
        var ccOutEnergyConsFCC:Vec3;

        var debugVar:Vec4;

        function saturate(x:Float):Float { 
            return clamp(x,0.0,1.0);
        }

        function saturate3(x:Vec3):Vec3 { 
            return clamp(x,0.0,1.0);
        }

		function pow5(value:Float):Float {
            var sq=value*value; //float
            return sq*sq*value;
        }

        function getR0RemappedForClearCoat(f0:Vec3):Vec3 {
            return saturate3(f0 * (f0 * (0.941892 - 0.263008 * f0) + 0.346479) - 0.0285998);
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

        function absEps(x:Float):Float {
            return abs(x)+Epsilon;
        }

		function fromRGBD(rgbd:Vec4):Vec3 {
            rgbd.rgb=toLinearSpace(rgbd.rgb);//toLinearSpace(rgbd.bgr);
            return rgbd.rgb/rgbd.a;
        }

        function getBRDFLookup(NdotV:Float, perceptualRoughness:Float):Vec3 {
            var UV = vec2(NdotV, perceptualRoughness); //vec2
            var brdfLookup = fromRGBD(environmentBrdfSampler.get(UV)); //vec4
            return brdfLookup.rgb;
        }
        
		function square(value:Float):Float {
            return value*value;
        }

        function convertRoughnessToAverageSlope(roughness:Float):Float {
            return square(roughness) + MINIMUMVARIANCE;
        }
        
        function computeReflectionCoords(worldPos:Vec4, worldNormal:Vec3):Vec3 {
            return computeCubicCoords(worldPos, worldNormal, vEyePosition.xyz, reflectionMatrix);
        }
        
        function computeCubicCoords(worldPos:Vec4, worldNormal:Vec3, eyePosition:Vec3, reflectionMatrix:Mat4):Vec3 {
            var viewDir = normalize(worldPos.xyz - eyePosition); //vec3
            var coords = reflect(viewDir, worldNormal); //vec3
            coords = (reflectionMatrix * vec4(coords, 0)).xyz; //coords = vec3(reflectionMatrix * vec4(coords, 0));
            return coords;
        }
    
        function getLodFromAlphaG(cubeMapDimensionPixels:Float, microsurfaceAverageSlope:Float):Float {
            var microsurfaceAverageSlopeTexels = cubeMapDimensionPixels * microsurfaceAverageSlope; //float
            var lod = log2(microsurfaceAverageSlopeTexels); //float
            return lod;
        }

        function toLinearSpace(color:Vec3):Vec3 {
            return pow(color,vec3(LinearEncodePowerApprox));
        }

        function getReflectanceFromBRDFLookup(/*const*/ specularEnvironmentR0:Vec3, /*const*/ specularEnvironmentR90:Vec3, /*const*/ environmentBrdf:Vec3):Vec3 {
			var reflectance = (specularEnvironmentR90-specularEnvironmentR0)*environmentBrdf.x+specularEnvironmentR0*environmentBrdf.y;
			return reflectance;
		}

        function getReflectanceFromBRDFLookup2(/*const*/ specularEnvironmentR0:Vec3,/*const*/ environmentBrdf:Vec3):Vec3 {
			var reflectance = mix(environmentBrdf.xxx, environmentBrdf.yyy, specularEnvironmentR0);
			return reflectance;
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

        function fresnelSchlickGGX_F(VdotH:Float, reflectance0:Float, reflectance90:Float):Float {
            return reflectance0 + (reflectance90 - reflectance0) * pow5(1.0 - VdotH);
        }

        function getEnergyConservationFactor(/*const*/ specularEnvironmentR0:Vec3, /*const*/ environmentBrdf:Vec3):Vec3 {
            return 1.0 + specularEnvironmentR0 * (1.0 / environmentBrdf.y - 1.0);
        }

        function fragment() {

            // var clearCoatMapData:Vec2 = texture(clearCoatSampler, vClearCoatUV + uvOffset).rg * vClearCoatInfos.y;

            // const in vec3 vPositionW,
            // const in vec3 geometricNormalW,
            // const in vec3 viewDirectionW,
            // const in vec2 vClearCoatParams,
            // const in vec3 specularEnvironmentR0,
            // const in vec2 clearCoatMapData,
            // const in vec3 vReflectionMicrosurfaceInfos,
            // const in vec2 vReflectionInfos,
            // const in vec3 vReflectionColor,
            // const in vec4 vLightingIntensity,
            // const in samplerCube reflectionSampler,
            // const in float ambientMonochrome,
            // out clearcoatOutParams outParams

            // struct clearcoatOutParams {
            //     vec3 specularEnvironmentR0;
            //     float conservationFactor;
            //     vec3 clearCoatNormalW;
            //     vec2 clearCoatAARoughnessFactors;
            //     float clearCoatIntensity;
            //     float clearCoatRoughness;
            //     vec3 finalClearCoatRadianceScaled;
            //     vec3 energyConservationFactorClearCoat;
            // };


            // Function clearcoatBlock
            var clearCoatIntensity = vClearCoatParams.x;
            var clearCoatRoughness = vClearCoatParams.y;
            // clearCoatIntensity *= clearCoatMapData.x;
            // clearCoatRoughness *= clearCoatMapData.y;
            var ccOutClearCoatIntensity:Float = clearCoatIntensity;
            var ccOutClearCoatRoughness:Float = clearCoatRoughness;
            var specularEnvironmentR0Updated:Vec3 = getR0RemappedForClearCoat(specularEnvironmentR0); 
            var ccOutSpecularEnvironmentR0:Vec3 = mix(specularEnvironmentR0, specularEnvironmentR0Updated, clearCoatIntensity);
            var clearCoatNormalW:Vec3 = geometricNormalW;
            var ccOutClearCoatNormalW:Vec3 = clearCoatNormalW;
            var ccOutClearCoatAARoughnessFactors:Vec2 = getAARoughnessFactors(clearCoatNormalW.xyz);
            var clearCoatNdotVUnclamped:Float = dot(clearCoatNormalW, viewDirectionW);
            var clearCoatNdotV:Float = absEps(clearCoatNdotVUnclamped);
            var environmentClearCoatBrdf:Vec3 = getBRDFLookup(clearCoatNdotV, clearCoatRoughness);
            var clearCoatAlphaG:Float = convertRoughnessToAverageSlope(clearCoatRoughness);
            clearCoatAlphaG += ccOutClearCoatAARoughnessFactors.y;
            var environmentClearCoatRadiance:Vec4 = vec4(0., 0., 0., 0.);
            var clearCoatReflectionVector:Vec3 = computeReflectionCoords(vec4(vPositionW, 1.0), clearCoatNormalW);
            var clearCoatReflectionCoords:Vec3 = clearCoatReflectionVector * vec3(-1, -1, 1);
            ccOutEnergyConsFCC = vec3(0.);

            var reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, clearCoatAlphaG); //float
            reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            environmentClearCoatRadiance = #if !flash textureLod(reflectionSampler, clearCoatReflectionCoords, reflectionLOD); #else texture(reflectionSampler, clearCoatReflectionCoords); #end// sampleReflectionLod
            environmentClearCoatRadiance.rgb = fromRGBD(environmentClearCoatRadiance); // When using RGBD HDR images
            environmentClearCoatRadiance.rgb *= vReflectionInfos.x;
            environmentClearCoatRadiance.rgb *= vReflectionColor.rgb;
 
            var clearCoatEnvironmentReflectance:Vec3 = getReflectanceFromBRDFLookup2(vec3(vClearCoatRefractionParams.x), environmentClearCoatBrdf);
            var clearCoatSeo:Float = environmentRadianceOcclusion(ambientMonochrome, clearCoatNdotVUnclamped);
            clearCoatEnvironmentReflectance *= clearCoatSeo;
            var clearCoatEho:Float = environmentHorizonOcclusion(-viewDirectionW, clearCoatNormalW, geometricNormalW);
            clearCoatEnvironmentReflectance *= clearCoatEho;
            clearCoatEnvironmentReflectance *= clearCoatIntensity;
            ccOutFinalClearCoatRadianceScaled = environmentClearCoatRadiance.rgb * clearCoatEnvironmentReflectance * lightingIntensity.z;
            var fresnelIBLClearCoat:Float = fresnelSchlickGGX_F(clearCoatNdotV, vClearCoatRefractionParams.x, 1.0); // CLEARCOATREFLECTANCE90 = 1.0
            fresnelIBLClearCoat *= clearCoatIntensity;
            ccOutConservationFactor = (1. - fresnelIBLClearCoat);
            ccOutEnergyConsFCC = getEnergyConservationFactor(ccOutSpecularEnvironmentR0, environmentClearCoatBrdf);
 
            // end function clearcoatBlock

            specularEnvironmentReflectance = getReflectanceFromBRDFLookup(ccOutSpecularEnvironmentR0, specularEnvironmentR90, environmentBrdf);
            // specularEnvironmentReflectance = getReflectanceFromBRDFLookup2(specularEnvironmentR0, specularEnvironmentR90);
            
            specularEnvironmentReflectance *= clearCoatSeo;
            specularEnvironmentReflectance *= clearCoatEho;
            specularEnvironmentReflectance *= ccOutConservationFactor;

            energyConservationFactor = getEnergyConservationFactor(ccOutSpecularEnvironmentR0, environmentBrdf);
        }
    }
    
    public function new() {
        super();
        trace("SETTING UP SHADER FOR CLEARCOAT");
        this.vClearCoatParams.set( 0, 0 );
        this.vClearCoatRefractionParams.set( 0.0400, 0.6667, -0.5000, 2.5000 );

        this.vReflectionInfos.set( 1, 0 );
        this.vReflectionColor.set( 1, 1, 1 );
        this.vReflectionMicrosurfaceInfos.set( 128, 0.8000, 0 );

    }
}