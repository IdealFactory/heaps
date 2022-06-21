package h3d.shader.pbrsinglepass;

class BaseColorUV extends PBRSinglePassLib {

	static var SRC = {
		@input var input : {
            var uv : Vec2;
        }

 		function vertex() {
            var uvUpdated : Vec2 = input.uv;
            vMainUV1 = uvUpdated;
        }

        var surfaceAlbedo:Vec3;
        @keep var alpha:Float;

        function fragment() {
            surfaceAlbedo = vAlbedoColor.rgb; //vec3
            alpha = vAlbedoColor.a; //float
       }
    };
}