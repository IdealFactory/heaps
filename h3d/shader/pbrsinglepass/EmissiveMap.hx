package h3d.shader.pbrsinglepass;

class EmissiveMap extends PBRSinglePassLib {

	static var SRC = {

        @keep @param var emissiveSampler : Sampler2D;
        @param var uEmissiveInfos : Vec2;
        @param var uEmissiveColor : Vec3; 
        
        @keep var finalEmissive:Vec3;
        var lightingIntensity:Vec4;

        @keep var vEmissiveInfos : Vec2;
        @keep var vEmissiveColor : Vec3; 

        function __init__fragment() {
            glslsource("// EmmissiveMap __init__fragment");

            vEmissiveInfos = uEmissiveInfos;
            vEmissiveColor = uEmissiveColor;
        }

        fragfunction("emissiveDefine",
"#define vEmissiveUV vMainUV1");

        function fragment() {
            glslsource("
    // EmmissiveMap fragment
    finalEmissive = vEmissiveColor;
    vec3 emissiveColorTex = texture(emissiveSampler, vEmissiveUV+uvOffset).rgb;
    finalEmissive *= toLinearSpace(emissiveColorTex.rgb);
    finalEmissive *= vEmissiveInfos.y;
");

            // finalEmissive = vEmissiveColor;
            // finalEmissive *= lightingIntensity.y;
            // var emissiveColorTex = emissiveSampler.get(vMainUV1 + uvOffset).rgb; //vec3 // vEmissiveUV -> vMainUV1
            // finalEmissive *= toLinearSpace(emissiveColorTex.rgb);
            // finalEmissive *= vEmissiveInfos.y;
          }
    }
    
    public function new() {
        super(); 

        this.uEmissiveInfos.set( 0, 1 );
        this.uEmissiveColor.set( 1, 1, 1 );
    }
}