package h3d.shader.pbrsinglepass;

class Clearcoat extends h3d.shader.pbrsinglepass.PBRSinglePassLib  {

	static var SRC = {

        @param var vClearCoatParams : Vec2;
        @param var vClearCoatRefractionParams : Vec4;

        // var normalW:Vec3;
        // var geometricNormalW:Vec3;
        // var viewDirectionW:Vec3;
        // var specularEnvironmentR0:Vec3;
        // var specularEnvironmentR90:Vec3;
        // var environmentBrdf:Vec3;
        // var reflectionVector:Vec3;
        // var ambientMonochrome:Float;

    //    @keep var lightingIntensity:Vec4;

    //    @keep var seo:Float;
    //    @keep var eho:Float;
    //    @keep var specularEnvironmentReflectance:Vec3;
    //    @keep var finalIrradiance:Vec3;
    //    @keep var energyConservationFactor:Vec3;

    //    @keep var ccOutConservationFactor:Float;
    //    @keep var ccOutFinalClearCoatRadianceScaled:Vec3;
    //    @keep var ccOutEnergyConsFCC:Vec3;

        function fragment() {

            /*
            // Function clearcoatBlock
            var clearCoatIntensity = vClearCoatParams.x;
            var clearCoatRoughness = vClearCoatParams.y;
            var ccOutClearCoatIntensity:Float = clearCoatIntensity;
            var ccOutClearCoatRoughness:Float = clearCoatRoughness;
            var specularEnvironmentR0Updated:Vec3 = getR0RemappedForClearCoat(specularEnvironmentR0); 
            var ccOutSpecularEnvironmentR0:Vec3 = mix(specularEnvironmentR0, specularEnvironmentR0Updated, clearCoatIntensity);
            var clearCoatNormalW:Vec3 = geometricNormalW;
            var ccOutClearCoatNormalW:Vec3 = clearCoatNormalW;
            var ccOutClearCoatAARoughnessFactors:Vec2 = getAARoughnessFactors(clearCoatNormalW.xyz);
            var clearCoatNdotVUnclamped:Float = dot(clearCoatNormalW, viewDirectionW);
            var clearCoatNdotV:Float = absEps(clearCoatNdotVUnclamped);
            var environmentClearCoatBrdf:Vec3 = getBRDFLookup(clearCoatNdotV, clearCoatRoughness, environmentBrdfSampler);
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
 
            var clearCoatEnvironmentReflectance:Vec3 = getReflectanceFromBRDFLookup(vec3(vClearCoatRefractionParams.x), environmentClearCoatBrdf);
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
            */
            glslsource("
    // Clearcoat fragment
    clearcoatOutParams clearcoatOut;
    clearcoatOut.specularEnvironmentR0 = specularEnvironmentR0;
    vec3 specularEnvironmentReflectance = getReflectanceFromBRDFLookup(clearcoatOut.specularEnvironmentR0, specularEnvironmentR90, environmentBrdf);
    specularEnvironmentReflectance *= seo;
    specularEnvironmentReflectance *= eho;
    subSurfaceOutParams subSurfaceOut;
    subSurfaceOut.specularEnvironmentReflectance = specularEnvironmentReflectance;

    vec3 diffuseBase = vec3(0., 0., 0.);
    preLightingInfo preInfo;
    lightingInfo info;
    float shadow = 1.;
    vec3 energyConservationFactor = getEnergyConservationFactor(clearcoatOut.specularEnvironmentR0, environmentBrdf);
");
        }
    }
    
    public function new() {
        super();
        
        this.vClearCoatParams.set( 0, 0 );
        this.vClearCoatRefractionParams.set( 0.0400, 0.6667, -0.5000, 2.5000 );
    }
}