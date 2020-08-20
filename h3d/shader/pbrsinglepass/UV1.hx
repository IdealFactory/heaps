package h3d.shader.pbrsinglepass;

class UV1 extends PBRSinglePassLib {

	static var SRC = {
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
            surfaceAlbedo *= toLinearSpace_V3(albedoTexture.rgb);
            surfaceAlbedo *= vAlbedoInfos.y;
       }
    };
}