package h3d.shader.pbrsinglepass;        

class Surface extends PBRSinglePassLib {

	static var SRC = {

        @param var uReflectivityColor : Vec4;
        @param var uMetallicReflectanceFactors : Vec4;

        @keep var surfaceAlbedo:Vec3;

        //@keep var baseColor:Vec3;
        @keep var microSurface:Float;
        @keep var roughness:Float;
        @keep var surfaceReflectivityColor:Vec3;
        @keep var metallicRoughness:Vec2;
        @keep var metallicReflectanceFactors:Vec4;
    
        fragfunction("reflectivityOutParams",
"struct reflectivityOutParams {
    float microSurface;
    float roughness;
    vec3 surfaceReflectivityColor;
    vec3 surfaceAlbedo;
};");
                            
        fragfunction("reflectivityBlock",
"void reflectivityBlock(
in vec4 vReflectivityColor, in vec3 surfaceAlbedo, in vec4 metallicReflectanceFactors, out reflectivityOutParams outParams
) {
    float microSurface = vReflectivityColor.a;
    vec3 surfaceReflectivityColor = vReflectivityColor.rgb;
    vec2 metallicRoughness = surfaceReflectivityColor.rg;
    #define CUSTOM_FRAGMENT_UPDATE_METALLICROUGHNESS
    microSurface = 1.0-metallicRoughness.g;
    vec3 baseColor = surfaceAlbedo;
    vec3 metallicF0 = metallicReflectanceFactors.rgb;
    outParams.surfaceAlbedo = mix(baseColor.rgb*(1.0-metallicF0), vec3(0., 0., 0.), metallicRoughness.r);
    surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
    microSurface = saturate(microSurface);
    float roughness = 1.-microSurface;
    outParams.microSurface = microSurface;
    outParams.roughness = roughness;
    outParams.surfaceReflectivityColor = surfaceReflectivityColor;
}
");

        function __init__fragment() {
            glslsource("// Surface __init__fragment");

            vReflectivityColor = uReflectivityColor;
            vMetallicReflectanceFactors = uMetallicReflectanceFactors;
		}

        function fragment() {
            // metallicReflectanceFactors = vMetallicReflectanceFactors;

            // // reflectivityOutParams {
            // //     float microSurface;
            // //     float roughness;
            // //     vec3 surfaceReflectivityColor;
            // //     vec3 surfaceAlbedo;
            // // }
            // // ReflectivityBlock ( vReflectivityColor, surfaceAlbedo, metallicReflectanceFactors) : ReflectivityOutParams
            // microSurface = vReflectivityColor.a; //float
            // surfaceReflectivityColor = vReflectivityColor.rgb; //vec3
            // metallicRoughness = surfaceReflectivityColor.rg; //vec2
            
            // microSurface = 1.0 - metallicRoughness.g;
            // baseColor = surfaceAlbedo; //vec3
            // var metallicF0 = metallicReflectanceFactors.rgb; //vec3
            // surfaceAlbedo = mix(baseColor.rgb * (1.0 - metallicF0), vec3(0., 0., 0.), metallicRoughness.r);
            // surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
            // microSurface = saturate(microSurface);
            // roughness = 1 - microSurface;

            glslsource("
    // Surface fragment
    vec3 baseColor = surfaceAlbedo;
    reflectivityOutParams reflectivityOut;
    vec4 metallicReflectanceFactors = vMetallicReflectanceFactors;
    reflectivityBlock(
    vReflectivityColor, surfaceAlbedo, metallicReflectanceFactors, reflectivityOut
    );
");
         }
    }

    public function new() {
        super();

        this.uReflectivityColor.set( 1, 1, 0.0400, 1 );
        this.uMetallicReflectanceFactors.set( 0.0400, 0.0400, 0.0400, 1 );
    }
}
        