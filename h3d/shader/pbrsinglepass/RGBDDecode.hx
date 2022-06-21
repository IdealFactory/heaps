package h3d.shader.pbrsinglepass;        

class RGBDDecode extends h3d.shader.ScreenShader {

	static var SRC = {
        // @:import h3d.shader.Base2d;

        @keep @param var textureSampler:Sampler2D;
        @param var scale:Vec2;

        @keep var finalColor : Vec4;
        @keep @keepv @var var mainUV : Vec2;
        
        var madd:Vec2;                      //=vec2(0.5,0.5);
        // var PI:Float;                       //=3.1415926535897932384626433832795;
        // var LinearEncodePowerApprox:Float;  //=2.2;
        // var GammaEncodePowerApprox:Float;   //=1.0/LinearEncodePowerApprox;
        // var LuminanceEncodeApprox:Vec3;     //=vec3(0.2126,0.7152,0.0722);
        // var Epsilon:Float;                  //=0.0000001;
        // var rgbdMaxRange:Float;             //=255.0
        
        // function toLinearSpace3(color:Vec3):Vec3 {
        //     return pow(color, vec3(LinearEncodePowerApprox));
        // }

        // function toGammaSpace3(color:Vec3):Vec3 {
        //     return pow(color,vec3(GammaEncodePowerApprox));
        // }

        // function fromRGBD(rgbd:Vec4):Vec3 {
        
        //     rgbd.rgb = toLinearSpace3(rgbd.rgb);
        
        //     return rgbd.rgb/rgbd.a;
        // }
        
        @keep var testing:Float;

		function __init__vertex() {
            glslsource("// RGBDecode __init__vertex");
        }

		function vertex() {
            glslsource("// RGBDecode vertex");
            madd = vec2(0.5);
            mainUV = (vec2(input.position.x, input.position.y * flipY) * madd + madd) * scale;
			output.position = vec4(input.position.x, input.position.y * flipY, 0, 1);
            glslsource("// RGBDecode vertex again");
		}

        fragfunction("defines",
"
const float PI = 3.1415926535897932384626433832795;
const float LinearEncodePowerApprox = 2.2;
const float GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
const vec3 LuminanceEncodeApprox = vec3(0.2126, 0.7152, 0.0722);
const float Epsilon = 0.0000001;

");
            
         fragfunction("toLinearSpace", 
"float toLinearSpace(float color) { 
	return pow(color, LinearEncodePowerApprox);
}
vec3 toLinearSpace(vec3 color) {
	return pow(color, vec3(LinearEncodePowerApprox));
}
vec4 toLinearSpace(vec4 color) {
	return vec4(pow(color.rgb, vec3(LinearEncodePowerApprox)), color.a);
}");

        fragfunction("fromRGBD", 
"vec3 fromRGBD(vec4 rgbd) {
    rgbd.rgb = toLinearSpace(rgbd.rgb);
    return rgbd.rgb/rgbd.a;
}");
    
    
        @keep var finalCol : Vec4;

        function __init__fragment() {
            glslsource("// RGBDecode __init__fragment-1");
            testing = 1.2;
            glslsource("// RGBDecode __init__fragment-2");
        }

        function fragment() {
            // rgbdMaxRange = 255.0;
            // PI = 3.1415926535897932384626433832795;
            // LinearEncodePowerApprox = 2.2;
            // GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
            // LuminanceEncodeApprox = vec3(0.2126,0.7152,0.0722);
            // Epsilon = 0.0000001;
            // output.color = vec4(fromRGBD(textureSampler.get(calculatedUV)), 1.0);

            // finalCol = vec4(0.);

            glslsource("// RGBDecode fragment
    finalCol = vec4(fromRGBD(texture(textureSampler, mainUV)), 1.0);
");
            
            output.color = finalCol;
            glslsource("// RGBDecode fragment-2");
        }
    };

	public function new() {
        super();

        this.scale.set( 1, 1 );
	}

    // static var SRC = {
    //     @:import h3d.shader.Base2d;

    //     @param var textureSampler:Sampler2D;
    //     @param var scale:Vec2;
        
    //     var madd:Vec2;                      //=vec2(0.5,0.5);
    //     var PI:Float;                       //=3.1415926535897932384626433832795;
    //     var LinearEncodePowerApprox:Float;  //=2.2;
    //     var GammaEncodePowerApprox:Float;   //=1.0/LinearEncodePowerApprox;
    //     var LuminanceEncodeApprox:Vec3;     //=vec3(0.2126,0.7152,0.0722);
    //     var Epsilon:Float;                  //=0.0000001;
    //     var rgbdMaxRange:Float;             //=255.0
        
    //     function toLinearSpace3(color:Vec3):Vec3 {
    //         return pow(color, vec3(LinearEncodePowerApprox));
    //     }

    //     function toGammaSpace3(color:Vec3):Vec3 {
    //         return pow(color,vec3(GammaEncodePowerApprox));
    //     }

    //     function fromRGBD(rgbd:Vec4):Vec3 {
        
    //         rgbd.rgb = toLinearSpace3(rgbd.bgr);
        
    //         return rgbd.rgb/rgbd.a;
    //     }
        
    //     function fragment() {
    //         rgbdMaxRange = 255.0;
    //         PI = 3.1415926535897932384626433832795;
    //         LinearEncodePowerApprox = 2.2;
    //         GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
    //         LuminanceEncodeApprox = vec3(0.2126,0.7152,0.0722);
    //         Epsilon = 0.0000001;
    //         pixelColor = vec4(fromRGBD(textureSampler.get(calculatedUV)), 1.0);
    //     }
    // };
}
