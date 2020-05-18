package h3d.shader.pbrsinglepass;        

class RGBDDecode extends hxsl.Shader {

	static var SRC = {
        @:import h3d.shader.Base2d;

        @param var textureSampler:Sampler2D;
        @param var scale:Vec2;
        
        var madd:Vec2;                      //=vec2(0.5,0.5);
        var PI:Float;                       //=3.1415926535897932384626433832795;
        var LinearEncodePowerApprox:Float;  //=2.2;
        var GammaEncodePowerApprox:Float;   //=1.0/LinearEncodePowerApprox;
        var LuminanceEncodeApprox:Vec3;     //=vec3(0.2126,0.7152,0.0722);
        var Epsilon:Float;                  //=0.0000001;
        var rgbdMaxRange:Float;             //=255.0
        
        function toLinearSpace3(color:Vec3):Vec3 {
            return pow(color, vec3(LinearEncodePowerApprox));
        }

        function toGammaSpace3(color:Vec3):Vec3 {
            return pow(color,vec3(GammaEncodePowerApprox));
        }

        function fromRGBD(rgbd:Vec4):Vec3 {
        
            rgbd.rgb = toLinearSpace3(rgbd.bgr);
        
            return rgbd.rgb/rgbd.a;
        }
        
        function fragment() {
            rgbdMaxRange = 255.0;
            PI = 3.1415926535897932384626433832795;
            LinearEncodePowerApprox = 2.2;
            GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
            LuminanceEncodeApprox = vec3(0.2126,0.7152,0.0722);
            Epsilon = 0.0000001;
            pixelColor = vec4(fromRGBD(textureSampler.get(calculatedUV)), 1.0);
        }
    };
}
