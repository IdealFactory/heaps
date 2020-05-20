package h3d.shader.pbrsinglepass;

class EmissiveMap extends hxsl.Shader {

	static var SRC = {

        @param var emissiveSampler : Sampler2D;
        @param var vEmissiveInfos : Vec2;
        @param var vEmissiveColor : Vec3; 
        
        @var var vMainUV1 : Vec2;

        var uvMain:Vec2;
        var uvOffset:Vec2;
        var finalEmissive:Vec3;
        var lightingIntensity:Vec4;

        var LinearEncodePowerApprox : Float;// = 2.2;
        
        function toLinearSpace(color:Vec3):Vec3 {
            return pow(color,vec3(LinearEncodePowerApprox));
        }

        function fragment() {
            finalEmissive = vEmissiveColor;
            finalEmissive *= lightingIntensity.y;
            var emissiveColorTex = emissiveSampler.get(vMainUV1 + uvOffset).rgb; //vec3 // vEmissiveUV -> vMainUV1
            finalEmissive *= toLinearSpace(emissiveColorTex.rgb);
            finalEmissive *= vEmissiveInfos.y;
          }
    }
    
    public function new() {
        super(); 

        this.vEmissiveInfos.set( 0, 1 );
        this.vEmissiveColor.set( 1, 1, 1 );
    }
}