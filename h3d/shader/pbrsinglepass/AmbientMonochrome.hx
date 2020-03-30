package h3d.shader.pbrsinglepass;

class AmbientMonochrome extends hxsl.Shader {

	static var SRC = {

        var ambientMonochrome:Float;
        var ambientOcclusionColor:Vec3;

        var LuminanceEncodeApproxX : Float;// = 0.2126;
        var LuminanceEncodeApproxY: Float;// = 0.7152;
        var LuminanceEncodeApproxZ : Float;// = 0.0722;

        function getLuminance(color:Vec3):Float {
            return clamp(dot(color,vec3(LuminanceEncodeApproxX, LuminanceEncodeApproxY, LuminanceEncodeApproxZ)),0.,1.);
        }
        
        function fragment() {
            ambientMonochrome = getLuminance(ambientOcclusionColor); //float
        }
	}
}