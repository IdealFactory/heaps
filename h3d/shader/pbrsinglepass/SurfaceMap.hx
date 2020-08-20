package h3d.shader.pbrsinglepass;        

class SurfaceMap extends PBRSinglePassLib {

	static var SRC = {

        @param var vReflectivityColor : Vec4;
        @param var reflectivitySampler : Sampler2D;
        @param var vMetallicReflectanceFactors : Vec4;
       
        var surfaceAlbedo:Vec3;
        var uvOffset:Vec2;

        var microSurface:Float;
        var roughness:Float;
        var surfaceReflectivityColor:Vec3;
        var metallicRoughness:Vec2;
        var metallicReflectanceFactors:Vec4;

        function fragment() {
            var surfaceMetallicOrReflectivityColorMap = reflectivitySampler.get(vMainUV1 + uvOffset); //vec4 // vReflectivityUV -> vMainUV1
            metallicReflectanceFactors = vMetallicReflectanceFactors;
            
            // reflectivityOutParams {
            //     float microSurface;
            //     float roughness;
            //     vec3 surfaceReflectivityColor;
            //     vec3 surfaceAlbedo;
            // }
            // ReflectivityBlock ( vReflectivityColor, surfaceAlbedo, metallicReflectanceFactors) : ReflectivityOutParams
            microSurface = vReflectivityColor.a; //float
            surfaceReflectivityColor = vReflectivityColor.rgb; //vec3
            metallicRoughness = surfaceReflectivityColor.rg; //vec2
            metallicRoughness.r *= surfaceMetallicOrReflectivityColorMap.b;
            metallicRoughness.g *= surfaceMetallicOrReflectivityColorMap.g;
            microSurface = 1.0 - metallicRoughness.g;
            var baseColor = surfaceAlbedo; //vec3
            var metallicF0 = metallicReflectanceFactors.rgb; //vec3
            surfaceAlbedo = mix(baseColor.rgb * (1.0 - metallicF0), vec3(0., 0., 0.), metallicRoughness.r);
            surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
            microSurface = saturate(microSurface);
            roughness = 1 - microSurface;
         }
    }

    public function new() {
        super();

        this.vReflectivityColor.set( 1, 1, 0.0400, 1 );
		this.vMetallicReflectanceFactors.set( 0.0934, 0.0934, 0.0934, 1 );
    }
}
        