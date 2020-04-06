package h3d.shader.pbrsinglepass;

class UV1 extends hxsl.Shader {

	static var SRC = {
		@input var input : {
            var uv : Vec2;
        }

        @param var albedoSampler : Sampler2D;                           // uniform sampler2D albedoSampler;
        
        @var var vMainUV1 : Vec2;                                       // varying vec2 vMainUV1;
        
        @param var vAlbedoInfos : Vec2;                                 // uniform vec2 vAlbedoInfos;
        @param var vAmbientInfos : Vec4;                                // uniform vec4 vAmbientInfos;
        @param var vReflectivityInfos : Vec3;                           // uniform vec3 vReflectivityInfos;

        @param var vAlbedoColor : Vec4;                 // uniform vec4 vAlbedoColor;

        var uvOffset:Vec2;

        function toLinearSpace(color:Vec3):Vec3 {
            return pow(color,vec3(LinearEncodePowerApprox));
        }
        
 		function vertex() {
            var uvUpdated : Vec2 = input.uv;
            vMainUV1 = uvUpdated;
        }

        // Fragment vars
        // var viewDirectionW:Vec3;
        var surfaceAlbedo:Vec3;
        var alpha:Float;
        var ambientOcclusionColor:Vec3;
        
        var ambientInfos:Vec4;
        var uvMain:Vec2;

        // var vAlbedoColor:Vec4;
        var LinearEncodePowerApprox : Float;// = 2.2;

        var testvar:Vec4;

		function fragment() {
            surfaceAlbedo = vAlbedoColor.rgb; //vec3
            alpha = vAlbedoColor.a; //float

            uvMain = vMainUV1;
            //uvMain.x = 1. - uvMain.x;
            var albedoTexture = albedoSampler.get(uvMain + uvOffset); //vec4 // vAlbedoUV -> vMainUV1
            surfaceAlbedo *= toLinearSpace(albedoTexture.rgb);
            surfaceAlbedo *= vAlbedoInfos.y;

            ambientOcclusionColor = vec3(1., 1., 1.); //vec3
            ambientInfos = vAmbientInfos;

            // testvar = vec4(vec3(surfaceAlbedo.rgb), 1);
        }
    };

	public function new() {
        super();

        this.vAlbedoColor.set( 1, 1, 1, 1 );
        this.vAlbedoInfos.set( 0, 1 );
        this.vAmbientInfos.set( 0, 1, 1, 0 );
        this.vReflectivityInfos.set( 0, 1, 1 );

    }
}