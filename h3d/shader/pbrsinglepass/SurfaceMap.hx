package h3d.shader.pbrsinglepass;        

class SurfaceMap extends PBRSinglePassLib {

	static var SRC = {

        @param var uReflectivityColor : Vec4;
        @keep @param var reflectivitySampler : Sampler2D;
        @param var uMetallicReflectanceFactors : Vec4;
        @param var uReflectivityInfos : Vec3;
       
        @keep var surfaceAlbedo:Vec3;
        
        @keep var microSurface:Float;
        @keep var roughness:Float;
        @keep var surfaceReflectivityColor:Vec3;
        @keep var metallicRoughness:Vec2;
        @keep var metallicReflectanceFactors:Vec4;

        fragfunction("reflectivityOutParamsDefine",
"#define vReflectivityUV vMainUV1");

        fragfunction("reflectivityOutParams",
"struct reflectivityOutParams {
    float microSurface;
    float roughness;
    vec3 surfaceReflectivityColor;
    vec3 surfaceAlbedo;
};");
                            
        fragfunction("reflectivityBlock",
"void reflectivityBlock(
in vec4 vReflectivityColor, in vec3 surfaceAlbedo, in vec4 metallicReflectanceFactors, in vec3 reflectivityInfos, in vec4 surfaceMetallicOrReflectivityColorMap, out reflectivityOutParams outParams
) {
    float microSurface = vReflectivityColor.a;
    vec3 surfaceReflectivityColor = vReflectivityColor.rgb;
    vec2 metallicRoughness = surfaceReflectivityColor.rg;
    metallicRoughness.r *= surfaceMetallicOrReflectivityColorMap.b;
    metallicRoughness.g *= surfaceMetallicOrReflectivityColorMap.g;
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
            glslsource("// SurfaceMap __init__fragment");

            vReflectivityColor = uReflectivityColor;
            vMetallicReflectanceFactors = uMetallicReflectanceFactors;
            vReflectivityInfos = uReflectivityInfos;
		}

        function fragment() {
            // var surfaceMetallicOrReflectivityColorMap = reflectivitySampler.get(vMainUV1 + uvOffset); //vec4 // vReflectivityUV -> vMainUV1
            // metallicReflectanceFactors = vMetallicReflectanceFactors;
            
            // // reflectivityOutParams {
            // //     float microSurface;
            // //     float roughness;
            // //     vec3 surfaceReflectivityColor;
            // //     vec3 surfaceAlbedo;
            // // }
            // // ReflectivityBlock ( in vec4 vReflectivityColor, in vec3 surfaceAlbedo, in vec4 metallicReflectanceFactors, in vec3 reflectivityInfos, 
            // //                     in vec4 surfaceMetallicOrReflectivityColorMap) : ReflectivityOutParams
            // microSurface = vReflectivityColor.a; //float
            // surfaceReflectivityColor = vReflectivityColor.rgb; //vec3
            // metallicRoughness = surfaceReflectivityColor.rg; //vec2
            // metallicRoughness.r *= surfaceMetallicOrReflectivityColorMap.b;
            // metallicRoughness.g *= surfaceMetallicOrReflectivityColorMap.g;
            // microSurface = 1.0 - metallicRoughness.g;
            // var baseColor = surfaceAlbedo; //vec3
            // var metallicF0 = metallicReflectanceFactors.rgb; //vec3
            // surfaceAlbedo = mix(baseColor.rgb * (1.0 - metallicF0), vec3(0., 0., 0.), metallicRoughness.r);
            // surfaceReflectivityColor = mix(metallicF0, baseColor, metallicRoughness.r);
            // microSurface = saturate(microSurface);
            // roughness = 1 - microSurface;

            glslsource("
    // SurfaceMap fragment
    vec3 baseColor = surfaceAlbedo;
    reflectivityOutParams reflectivityOut;
    vec4 surfaceMetallicOrReflectivityColorMap = texture(reflectivitySampler, vReflectivityUV+uvOffset);
    vec4 baseReflectivity = surfaceMetallicOrReflectivityColorMap;
    vec4 metallicReflectanceFactors = vMetallicReflectanceFactors;
    reflectivityBlock(
        vReflectivityColor, surfaceAlbedo, metallicReflectanceFactors, vReflectivityInfos, surfaceMetallicOrReflectivityColorMap, reflectivityOut
    );
");
       }
    }

    public function new() {
        super();

        this.uReflectivityColor.set( 1, 1, 0.0400, 1 );
		this.uMetallicReflectanceFactors.set( 0.0934, 0.0934, 0.0934, 1 );
		this.uReflectivityInfos.set( 0, 1, 1 );
    }
}
        