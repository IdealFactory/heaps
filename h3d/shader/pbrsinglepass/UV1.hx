package h3d.shader.pbrsinglepass;

class UV1 extends PBRSinglePassLib {

	static var SRC = {
        @param var hasAlpha : Int;
        @param var alphaCutoff : Float;

        @input var input : {
            var uv : Vec2;
        }

        @keep @param var albedoSampler : Sampler2D;                           // uniform sampler2D albedoSampler;
        
 		function vertex() {
            glslsource("// UV1 vertex");

            var uvUpdated : Vec2 = input.uv;
            vMainUV1 = uvUpdated;
        }

        // Fragment vars
        @keep var surfaceAlbedo:Vec3;
        @keep var alpha:Float;

        fragfunction("albedoOpacityOutParams",
"struct albedoOpacityOutParams {
    vec3 surfaceAlbedo;
    float alpha;
};");
            
        fragfunction("albedoOpacityBlock",
"void albedoOpacityBlock(
    in vec4 vAlbedoColor, in vec4 albedoTexture, in vec2 albedoInfos, out albedoOpacityOutParams outParams
) {
    vec3 surfaceAlbedo = vAlbedoColor.rgb;
    float alpha = vAlbedoColor.a;
    surfaceAlbedo *= toLinearSpace(albedoTexture.rgb);
    surfaceAlbedo *= albedoInfos.y;    
    #define CUSTOM_FRAGMENT_UPDATE_ALBEDO
    outParams.surfaceAlbedo = surfaceAlbedo;
    outParams.alpha = alpha;
}");

        function fragment() {
            // surfaceAlbedo = vAlbedoColor.rgb; //vec3
            // alpha = vAlbedoColor.a; //float

            // glslsource("vec3 myvar = vec3(0.);");

            // var albedoTexture = albedoSampler.get(vMainUV1 + uvOffset); //vec4 // vAlbedoUV -> vMainUV1
            // alpha *= albedoTexture.a;
            // surfaceAlbedo *= toLinearSpace(albedoTexture.rgb);
            // surfaceAlbedo *= vAlbedoInfos.y;

            // if (hasAlpha==1) {
            //     if (alphaCutoff>0) {
            //         alpha = 1;
            //         if (albedoTexture.a < alphaCutoff) 
            //             discard;
            //     }
            // } 

            glslsource("
    // UV1 fragment
    albedoOpacityOutParams albedoOpacityOut;
    vec4 albedoTexture = texture(albedoSampler, vMainUV1+uvOffset);
    albedoOpacityBlock(
        vAlbedoColor, albedoTexture, vAlbedoInfos, albedoOpacityOut
    );

    vec3 surfaceAlbedo = albedoOpacityOut.surfaceAlbedo;
    float alpha = albedoOpacityOut.alpha;
");
        }
    };

    public function new() {
        super();

        this.hasAlpha = 0;
        this.alphaCutoff = 0;
    }

}