package h3d.shader.pbrsinglepass;

class Clearcoat extends PBRSinglePassLib {

    // Public fields for external access (e.g., from PBRSinglePass.hx)
    public var clearCoatIntensity(default, set) : Float = 0.0;
    public var clearCoatRoughness(default, set) : Float = 0.0;

    static var SRC = {

        @param var vClearCoatParams : Vec2;  // Legacy: base intensity.x, roughness.y
        @param var vClearCoatRefractionParams : Vec4;

        // New sampler params for textures
        @param var clearCoatIntensitySampler : Sampler2D;
        @param var clearCoatRoughnessSampler : Sampler2D;

        var normalW:Vec3;
        var geometricNormalW:Vec3;
        var viewDirectionW:Vec3;
        var specularEnvironmentR0:Vec3;
        var specularEnvironmentR90:Vec3;
        var environmentBrdf:Vec3;
        var reflectionVector:Vec3;
        var ambientMonochrome:Float;

        var lightingIntensity:Vec4;

        var seo:Float;
        var eho:Float;
        var specularEnvironmentReflectance:Vec3;
        var finalIrradiance:Vec3;
        var energyConservationFactor:Vec3;

        var ccOutConservationFactor:Float;
        var ccOutFinalClearCoatRadianceScaled:Vec3;
        var ccOutEnergyConsFCC:Vec3;

        function fragment() {

            // Function clearcoatBlock
            var clearCoatIntensity = vClearCoatParams.x;
            var clearCoatRoughness = vClearCoatParams.y;

            // Sample textures and modulate (Babylon.js ref: pbr.fragment.ts ~1243-1280)
            // Use vMainUV1 for UVs (standard in PBRSinglePassLib)
            var texIntensity = clearCoatIntensitySampler.get(vMainUV1).r;
            var texRoughness = clearCoatRoughnessSampler.get(vMainUV1).r;
            clearCoatIntensity *= texIntensity;
            clearCoatRoughness *= texRoughness;

            // Clamp to [0,1] for safety (assuming saturate is defined in lib; else use clamp(clearCoatIntensity, 0., 1.))
            clearCoatIntensity = saturate(clearCoatIntensity);
            clearCoatRoughness = saturate(clearCoatRoughness);

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

            // Expanded sampleReflectionTexture
            var reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, clearCoatAlphaG); //float
            reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            environmentClearCoatRadiance = #if !flash textureLod(reflectionSampler, clearCoatReflectionCoords, reflectionLOD); #else texture(reflectionSampler, clearCoatReflectionCoords); #end// sampleReflectionLod
            if (rgbdDecodeEnv) {
                environmentClearCoatRadiance.rgb = fromRGBD(environmentClearCoatRadiance);
            }
            environmentClearCoatRadiance.rgb *= vec3(vReflectionInfos.x);
            environmentClearCoatRadiance.rgb *= vReflectionColor.rgb;
 
            var clearCoatEnvironmentReflectance:Vec3 = getReflectanceFromBRDFLookup2(vec3(vClearCoatRefractionParams.x), environmentClearCoatBrdf);
            var clearCoatSeo:Float = environmentRadianceOcclusion(ambientMonochrome, clearCoatNdotVUnclamped);
            clearCoatEnvironmentReflectance *= vec3(clearCoatSeo);
            var clearCoatEho:Float = environmentHorizonOcclusion(-viewDirectionW, clearCoatNormalW, geometricNormalW);
            clearCoatEnvironmentReflectance *= vec3(clearCoatEho);
            clearCoatEnvironmentReflectance *= vec3(clearCoatIntensity);
            ccOutFinalClearCoatRadianceScaled = environmentClearCoatRadiance.rgb * clearCoatEnvironmentReflectance * vec3(lightingIntensity.z);
            var fresnelIBLClearCoat:Float = fresnelSchlickGGX(clearCoatNdotV, vClearCoatRefractionParams.x, 1.0); // CLEARCOATREFLECTANCE90 = 1.0
            fresnelIBLClearCoat *= clearCoatIntensity;
            ccOutConservationFactor = (1. - fresnelIBLClearCoat);
            ccOutEnergyConsFCC = getEnergyConservationFactor(ccOutSpecularEnvironmentR0, environmentClearCoatBrdf);
 
            // end function clearcoatBlock

            specularEnvironmentReflectance = getReflectanceFromBRDFLookup(ccOutSpecularEnvironmentR0, specularEnvironmentR90, environmentBrdf);
            
            specularEnvironmentReflectance *= vec3(clearCoatSeo);
            specularEnvironmentReflectance *= vec3(clearCoatEho);
            specularEnvironmentReflectance *= vec3(ccOutConservationFactor);

            energyConservationFactor = getEnergyConservationFactor(ccOutSpecularEnvironmentR0, environmentBrdf);
        }
    };

    public function new( ?intensity : Float = 0.0, ?roughness : Float = 0.0, ?intensityTex : h3d.mat.Texture, ?roughnessTex : h3d.mat.Texture ) {
        super();
        clearCoatIntensity = intensity;
        clearCoatRoughness = roughness;
        vClearCoatParams.set(intensity, roughness);  // Sync to legacy uniform
        vClearCoatRefractionParams.set( 0.0400, 0.6667, -0.5000, 2.5000 );
        // Set samplers to textures or white defaults (multiplies by 1.0 if null)
        clearCoatIntensitySampler = intensityTex != null ? intensityTex : h3d.mat.Texture.fromColor(0xFFFFFFFF);
        clearCoatRoughnessSampler = roughnessTex != null ? roughnessTex : h3d.mat.Texture.fromColor(0xFFFFFFFF);
    }

    function set_clearCoatIntensity(v : Float) : Float {
        vClearCoatParams.x = v;
        return clearCoatIntensity = v;
    }

    function set_clearCoatRoughness(v : Float) : Float {
        vClearCoatParams.y = v;
        return clearCoatRoughness = v;
    }
}