package h3d.shader.pbrsinglepass;        

class BaseColor extends PBRSinglePassLib {

	static var SRC = {

        var normalW:Vec3;

        function vertex() {
            var uvUpdated = vec2(0., 0.);
        }

        var surfaceAlbedo:Vec3;
        var alpha:Float;
        var ambientOcclusionColor:Vec3;

        function fragment() {
            surfaceAlbedo = vAlbedoColor.rgb; //vec3
            alpha = vAlbedoColor.a; //float

            ambientOcclusionColor = vec3(1., 1., 1.); //vec3  
        }
    }
}
        