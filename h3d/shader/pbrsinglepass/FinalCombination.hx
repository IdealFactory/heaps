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
        var finalClearCoat:Vec3;
        var finalClearCoatScaled:Vec3;

        var ambientColor:Vec3;
        var lightingIntensity:Vec4;

        function fragment() {
            finalIrradiance = environmentIrradiance; //vec3
            finalIrradiance *= ccOutConservationFactor;
            finalIrradiance *= surfaceAlbedo.rgb;
            finalIrradiance *= lightingIntensity.z;
            finalIrradiance *= ambientOcclusionColor;
            finalSpecular = specularBase;
            finalSpecular = max(finalSpecular, 0.0);
            finalSpecularScaled = finalSpecular * lightingIntensity.x * lightingIntensity.w;
            finalSpecularScaled *= energyConservationFactor;
            finalRadiance = environmentRadiance.rgb; //vec3
            finalRadiance *= specularEnvironmentReflectance;
            finalRadianceScaled = finalRadiance * lightingIntensity.z; //vec3
            finalRadianceScaled *= energyConservationFactor;
            finalRadianceScaled *= sheenOutSheenAlbedoScaling;
            finalSheen = sheenBase * sheenOutSheenColor;
            finalSheen = max(finalSheen, 0.0);
            finalSheenScaled = finalSheen * lightingIntensity.x * lightingIntensity.w;
            finalClearCoat = clearCoatBase;
            finalClearCoat = max(finalClearCoat, 0.0);
            finalClearCoatScaled = finalClearCoat * lightingIntensity.x * lightingIntensity.w;
            finalClearCoatScaled *= ccOutEnergyConsFCC;
            finalDiffuse = diffuseBase; //vec3
            finalDiffuse *= surfaceAlbedo.rgb;
            finalDiffuse = max(finalDiffuse, 0.0);
            finalDiffuse *= lightingIntensity.x;
            finalAmbient = ambientColor; //vec3
            finalAmbient *= surfaceAlbedo.rgb;
            finalAmbient *= ambientOcclusionColor;
            finalDiffuse *= ambientOcclusionForDirectDiffuse;
        }
    }
}