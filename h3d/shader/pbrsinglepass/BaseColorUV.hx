package h3d.shader.pbrsinglepass;

class BaseColorUV extends hxsl.Shader {

	static var SRC = {
		@input var input : {
            var uv : Vec2;
        }

        @var var vMainUV1 : Vec2;                                       // varying vec2 vMainUV1;
        
        @param var vAlbedoInfos : Vec2;                                 // uniform vec2 vAlbedoInfos;
        @param var vAmbientInfos : Vec4;                                // uniform vec4 vAmbientInfos;

        @param var vAlbedoColor : Vec4;                 // uniform vec4 vAlbedoColor;

        var uvOffset:Vec2;

 		function vertex() {
            var uvUpdated : Vec2 = input.uv;
            vMainUV1 = uvUpdated;
        }

        // Fragment vars
        var surfaceAlbedo:Vec3;
        var alpha:Float;
        var ambientOcclusionColor:Vec3;
        
        var ambientInfos:Vec4;
        var uvMain:Vec2;

        var LinearEncodePowerApprox : Float;// = 2.2;

        var testvar:Vec4;

		function fragment() {
            surfaceAlbedo = vAlbedoColor.rgb; //vec3
            alpha = vAlbedoColor.a; //float

            uvMain = vMainUV1;

            ambientOcclusionColor = vec3(1., 1., 1.); //vec3
            ambientInfos = vAmbientInfos;
       }
    };

	public function new() {
        super();

        this.vAlbedoColor.set( 1, 1, 1, 1 );
        this.vAlbedoInfos.set( 0, 1 );//0 );
        this.vAmbientInfos.set( 0, 1, 1, 0) ;//0, 0, 0 );

    }
}