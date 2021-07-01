package h3d.shader.pbrsinglepass;

class FinalCombination extends PBRSinglePassLib {

	static var SRC = {

        var surfaceAlbedo:Vec3;
        var ambientOcclusionColor:Vec3;
        var ambientOcclusionForDirectDiffuse:Vec3;
        var environmentRadiance:Vec4;
        var environmentIrradiance:Vec3;

        var energyConservationFactor:Vec3;
        var diffuseBase:Vec3;
        var specularBase:Vec3;
        var specularEnvironmentReflectance:Vec3;

        // Sheen extension
        var sheenBase:Vec3;
        var sheenOutSheenColor:Vec3;
        var sheenOutSheenAlbedoScaling:Float;

        // Clearcoat extension
        var clearCoatBase:Vec3;
        var ccOutConservationFactor:Float;
        var ccOutEnergyConsFCC:Vec3;

        var finalAmbient:Vec3;
        var finalDiffuse:Vec3;
        var finalSpecular:Vec3;
        var finalIrradiance:Vec3;
        var finalSpecularScaled:Vec3;
        var finalRadiance:Vec3;
        var finalRadianceScaled:Vec3;
        var finalSheen:Vec3;
        var finalSheenScaled:Vec3;
        var finalSheenRadianceScaled:Vec3;
        var finalClearCoat:Vec3;
        var finalClearCoatScaled:Vec3;

        var ambientColor:Vec3;
        var lightingIntensity:Vec4;
        var alpha:Float;

        function fragment() {
            var sA:Vec3 = vec3(sheenOutSheenAlbedoScaling) * surfaceAlbedo.rgb;
            finalIrradiance = environmentIrradiance; //vec3
            finalIrradiance *= vec3(ccOutConservationFactor);
            finalIrradiance *= sA;
            finalIrradiance *= vec3(lightingIntensity.z);
            finalIrradiance *= ambientOcclusionColor;
            finalSpecular = specularBase;
            finalSpecular = max(finalSpecular, 0.0);
            finalSpecularScaled = finalSpecular * vec3(lightingIntensity.x) * vec3(lightingIntensity.w);
            finalSpecularScaled *= energyConservationFactor;
            finalRadiance = environmentRadiance.rgb; //vec3
            finalRadiance *= specularEnvironmentReflectance;
            finalRadianceScaled = finalRadiance * vec3(lightingIntensity.z); //vec3
            finalRadianceScaled *= energyConservationFactor;
            finalRadianceScaled *= vec3(sheenOutSheenAlbedoScaling);
            var luminanceOverAlpha:Float = 0.0;
            luminanceOverAlpha += getLuminance(finalRadianceScaled);
            alpha = saturate(alpha+luminanceOverAlpha*luminanceOverAlpha);
            finalSheen = sheenBase * sheenOutSheenColor;
            finalSheen = max(finalSheen, 0.0);
            finalSheenScaled = finalSheen * vec3(lightingIntensity.x) * vec3(lightingIntensity.w);
            finalSheenRadianceScaled *= vec3(ccOutConservationFactor);
            finalClearCoat = clearCoatBase;
            finalClearCoat = max(finalClearCoat, 0.0);
            finalClearCoatScaled = finalClearCoat * vec3(lightingIntensity.x) * vec3(lightingIntensity.w);
            finalClearCoatScaled *= ccOutEnergyConsFCC;
            finalDiffuse = diffuseBase; //vec3
            finalDiffuse *= sA;
            finalDiffuse = max(finalDiffuse, 0.0);
            finalDiffuse *= vec3(lightingIntensity.x);
            finalAmbient = ambientColor; //vec3
            finalAmbient *= sA;
            finalAmbient *= ambientOcclusionColor;
            finalDiffuse *= ambientOcclusionForDirectDiffuse;
        }
    }
}