package h3d.shader.pbrsinglepass;

class Sheen extends PBRSinglePassLib {

	static var SRC = {

        @param var vSheenColor : Vec4;
        @param var vSheenRoughness : Float;

        var lightingIntensity:Vec4;
        var NdotVUnclamped:Float;
        var NdotV:Float;
        var AARoughnessFactors:Vec2;
        var reflectionCoords:Vec3;
        var seo:Float;
        var eho:Float;
 
        var sheenBase:Vec3;
        var sheenOutSheenIntensity:Float;
        var sheenOutSheenColor:Vec3;
        var sheenOutSheenRoughness:Float;
        var sheenOutSheenAlbedoScaling:Float;
        var finalSheenRadianceScaled:Vec3;

        function fragment() {
            // sheenBase = vec3(0., 0., 0.);

            // // sheenBlock( vSheenColor, vSheenRoughness, roughness, reflectance, NdotV, environmentBrdf, AARoughnessFactors, vReflectionMicrosurfaceInfos, vReflectionInfos, vReflectionColor, vLightingIntensity, reflectionSampler, reflectionOut.reflectionCoords, NdotVUnclamped, seo, eho, sheenOut);
            // var sheenIntensity:Float = vSheenColor.a;
            // var sheenColor:Vec3 = vSheenColor.rgb;
            // var sheenRoughness:Float = vSheenRoughness;
            // sheenColor *= vec3(sheenIntensity);
            // var environmentSheenBrdf:Vec3 = getBRDFLookup(NdotV, sheenRoughness, environmentBrdfSampler);
            // var sheenAlphaG:Float = convertRoughnessToAverageSlope(sheenRoughness);
            // sheenAlphaG += AARoughnessFactors.y;
            // var environmentSheenRadiance:Vec4 = vec4(0., 0., 0., 0.);    
            
            // // Expanded sampleReflectionTexture( sheenAlphaG, vReflectionMicrosurfaceInfos, vReflectionInfos, vReflectionColor, reflectionSampler, reflectionCoords, environmentSheenRadiance );
            // var reflectionLOD:Float = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, sheenAlphaG);
            // reflectionLOD = reflectionLOD * vReflectionMicrosurfaceInfos.y + vReflectionMicrosurfaceInfos.z;
            // var environmentSheenRadiance:Vec4 = #if !flash textureLod(reflectionSampler, reflectionCoords, reflectionLOD); #else texture(reflectionSampler, reflectionCoords); #end//sampleReflectionLod(reflectionSampler, reflectionCoords, reflectionLOD);
            // // environmentSheenRadiance.rgb = fromRGBD(environmentSheenRadiance);
            // environmentSheenRadiance.rgb *= vec3(vReflectionInfos.x);
            // environmentSheenRadiance.rgb *= vReflectionColor.rgb;
            // // end sampleReflectionTexture

            // var sheenEnvironmentReflectance:Vec3 = getSheenReflectanceFromBRDFLookup(sheenColor, environmentSheenBrdf);
            // sheenEnvironmentReflectance *= vec3(seo);
            // sheenEnvironmentReflectance *= vec3(eho);
            // finalSheenRadianceScaled =
            //     environmentSheenRadiance.rgb *
            //     sheenEnvironmentReflectance *
            //     vec3(lightingIntensity.z);
            // sheenOutSheenAlbedoScaling = 1.0 - sheenIntensity * max(max(sheenColor.r, sheenColor.g), sheenColor.b) * environmentSheenBrdf.b;
            // sheenOutSheenIntensity = sheenIntensity;
            // sheenOutSheenColor = sheenColor;
            // sheenOutSheenRoughness = sheenRoughness;

            glslsource("// Sheen fragment");
        }
    }
    
    public function new() {
        super();

        // vSheenColor.rgb defines the sheen color vSheenColor.a defines the intensity
        this.vSheenColor.set( 1, 1, 1, 0 );
        this.vSheenRoughness = 0;
    }
}