package h3d.shader.pbrsinglepass;        

class SurfaceMap extends hxsl.Shader {

	static var SRC = {

        @param var vReflectivityColor : Vec4;
        @param var reflectivitySampler : Sampler2D;

        @var var vMainUV1 : Vec2; 
        
        var surfaceAlbedo:Vec3;
        var uvOffset:Vec2;

        var microSurface:Float;
        var surfaceReflectivityColor:Vec3;
        var metallicRoughness:Vec2;
        var baseColor:Vec3;
    
        function fragment() {
            microSurface = vReflectivityColor.a; //float
            surfaceReflectivityColor = vReflectivityColor.rgb; //vec3
            metallicRoughness = surfaceReflectivityColor.rg; //vec2
            var surfaceMetallicColorMap = reflectivitySampler.get(vMainUV1 + uvOffset); //vec4 // vReflectivityUV -> vMainUV1
            metallicRoughness.r *= surfaceMetallicColorMap.b;
            metallicRoughness.g *= surfaceMetallicColorMap.g;
            microSurface = 1.0 - metallicRoughness.g;
            baseColor = surfaceAlbedo; //vec3
            var metallicF0 = vec3(vReflectivityColor.a, vReflectivityColor.a, vReflectivityColor.a); //vec3
            surfaceAlbedo = mix(baseColor.rgb * (1.0 - metallicF0.r), vec3(0., 0., 0.), metallicRoughness.r);
            surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
            microSurface = saturate(microSurface);
         }
    }

    public function new() {
        super();

        this.vReflectivityColor.set( 1, 1, 1, 0.0400 );
    }
}
        