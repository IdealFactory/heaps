package h3d.shader.pbrsinglepass;

class UV1 extends PBRSinglePassLib {

	static var SRC = {
        @param var hasAlpha : Int;
        @param var alphaCutoff : Float;

        @input var input : {
            var uv : Vec2;
        }

        @param var albedoSampler : Sampler2D;                           // uniform sampler2D albedoSampler;
        
        var uvOffset:Vec2;

 		function vertex() {
            var uvUpdated : Vec2 = input.uv;
            vMainUV1 = uvUpdated;
        }

        // Fragment vars
        var surfaceAlbedo:Vec3;
        var alpha:Float;

		function fragment() {
            surfaceAlbedo = vAlbedoColor.rgb; //vec3
            alpha = vAlbedoColor.a; //float

            var albedoTexture = albedoSampler.get(vMainUV1 + uvOffset); //vec4 // vAlbedoUV -> vMainUV1
            alpha *= albedoTexture.a;
            surfaceAlbedo *= toLinearSpace_V3(albedoTexture.rgb);
            surfaceAlbedo *= vAlbedoInfos.y;
            if (hasAlpha==1) {
                if (alphaCutoff>0) {
                    alpha = 1;
                    if (albedoTexture.a < alphaCutoff) 
                        discard;
                }
            } 
        }
    };

    public function new() {
        super();

        this.hasAlpha = 0;
        this.alphaCutoff = 0;
    }

}