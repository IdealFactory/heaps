package h3d.shader.pbrsinglepass;        

class BaseColor extends hxsl.Shader {

	static var SRC = {

        @param var reflectionMatrix : Mat4;             // uniform mat4 reflectionMatrix;
        
        @param var vAlbedoColor : Vec4;                 // uniform vec4 vAlbedoColor;

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

    public function new() {
        super();

        this.vAlbedoColor.set( 1, 1, 1, 1 );

    }
}
        