package h3d.shader.pbrsinglepass;        

class BaseColor extends PBRSinglePassLib {

	static var SRC = {

        var normalW:Vec3;

        function vertex() {
            var uvUpdated = vec2(0., 0.);
            vMainUV1 = vec2(0., 0.);
        }

        @keep var surfaceAlbedo:Vec3;
        @keep var alpha:Float;
        @keep var ambientOcclusionColor:Vec3;

        fragfunction("albedoOpacityOutParams",
"struct albedoOpacityOutParams {
    vec3 surfaceAlbedo;
    float alpha;
};");
            
        fragfunction("albedoOpacityBlock",
"void albedoOpacityBlock(
    in vec4 vAlbedoColor, out albedoOpacityOutParams outParams
) {
    vec3 surfaceAlbedo = vAlbedoColor.rgb;
    float alpha = vAlbedoColor.a;
    #define CUSTOM_FRAGMENT_UPDATE_ALBEDO
    outParams.surfaceAlbedo = surfaceAlbedo;
    outParams.alpha = alpha;
}");

        function fragment() {
            // surfaceAlbedo = vAlbedoColor.rgb; //vec3
            // alpha = vAlbedoColor.a; //float

            // ambientOcclusionColor = vec3(1., 1., 1.); //vec3  

            glslsource("
    // BaseColor fragment
    albedoOpacityOutParams albedoOpacityOut;
    albedoOpacityBlock(
        vAlbedoColor, albedoOpacityOut
    );
    surfaceAlbedo = albedoOpacityOut.surfaceAlbedo;
    alpha = albedoOpacityOut.alpha;
");

        }
    }
}
        