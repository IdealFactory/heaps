package h3d.shader.pbrsinglepass;

class Debug extends hxsl.Shader {

	static var SRC = {

        var output : {
			var color : Vec4;
		};

        @param var debugid : Float;
        @keep var finalColor : Vec4;
        @keep @keepv var screenUV : Vec2;
        @keep var dbgid : Float;

        function __init__fragment() {
            dbgid = debugid;
        }

        function fragment() {

            glslsource("
    // Debug fragment
    if (dbgid!=0.0 && screenUV.x > 0.) {
");
            glslsource("if (dbgid==1.0) {
        finalColor.rgb = vPositionW.rgb;
        finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
    }");
        glslsource("if (dbgid==90.0) {
            finalColor.rgb = normalize(debugVar.rgb);
    }");
            glslsource("if (dbgid==2.0) {
        finalColor.rgb = vNormalW.rgb;
        finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
    }");
            glslsource("if (dbgid==3.0) {
        finalColor.rgb = TBN[0];
        finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
    }");
            glslsource("if (dbgid==4.0) {
        finalColor.rgb = TBN[1];
        finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
    }");
            glslsource("if (dbgid==5.0) {
        finalColor.rgb = normalW;
        finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
    }");
            glslsource("if (dbgid==6.0) {
        finalColor.rgb = vec3(vMainUV1, 0.0);
    }");
//             glslsource("if (dbgid==8.0) {
//         finalColor.rgb = clearcoatOut.TBNClearCoat[0];
//         finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
// }");
//             glslsource("if (dbgid==9.0) {
//         finalColor.rgb = clearcoatOut.TBNClearCoat[1];
//         finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
// }");
            glslsource("if (dbgid==10.0) {
        finalColor.rgb = clearcoatOut.clearCoatNormalW;
        finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
}");
//             glslsource("if (dbgid==11.0) {
//         finalColor.rgb = anisotropicOut.anisotropicNormal;
//         finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
// }");
//             glslsource("if (dbgid==12.0) {
//         finalColor.rgb = anisotropicOut.anisotropicTangent;
//         finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
// }");
//             glslsource("if (dbgid==13.0) {
//         finalColor.rgb = anisotropicOut.anisotropicBitangent;
//         finalColor.rgb = normalize(finalColor.rgb) * 0.5 + 0.5;
// }");
            glslsource("if (dbgid==20.0) {
        finalColor.rgb = albedoTexture.rgb;
    }");
            glslsource("if (dbgid==21.0) {
        finalColor.rgb = aoOut.ambientOcclusionColorMap.rgb;
    }");
//             glslsource("if (dbgid==22.0) {
//         finalColor.rgb = opacityMap.rgb;
// }");
            glslsource("if (dbgid==23.0) {
        finalColor.rgb = emissiveColorTex.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
//             glslsource("if (dbgid==24.0) {
//         finalColor.rgb = lightmapColor.rgb;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
//             glslsource("if (dbgid==25.0) {
//         finalColor.rgb = reflectivityOut.surfaceMetallicColorMap.rgb;
// }");
//             glslsource("if (dbgid==26.0) {
//         finalColor.rgb = reflectivityOut.surfaceReflectivityColorMap.rgb;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
//             glslsource("if (dbgid==27.0) {
//         finalColor.rgb = vec3(clearcoatOut.clearCoatMapData.rg, 0.0);
// }");
//             glslsource("if (dbgid==28.0) {
//         finalColor.rgb = clearcoatOut.clearCoatTintMapData.rgb;
// }");
//             glslsource("if (dbgid==29.0) {
//         finalColor.rgb = sheenOut.sheenMapData.rgb;
// }");
//             glslsource("if (dbgid==30.0) {
//         finalColor.rgb = anisotropicOut.anisotropyMapData.rgb;
// }");
//             glslsource("if (dbgid==31.0) {
//         finalColor.rgb = subSurfaceOut.thicknessMap.rgb;
// }");
//             glslsource("if (dbgid==40.0) {
//         finalColor.rgb = subSurfaceOut.environmentRefraction.rgb;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
            glslsource("if (dbgid==41.0) {
        finalColor.rgb = reflectionOut.environmentRadiance.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
//             glslsource("if (dbgid==42.0) {
//         finalColor.rgb = clearcoatOut.environmentClearCoatRadiance.rgb;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
            glslsource("if (dbgid==50.0) {
        finalColor.rgb = diffuseBase.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
            glslsource("if (dbgid==51.0) {
        finalColor.rgb = specularBase.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
            glslsource("if (dbgid==52.0) {
        finalColor.rgb = clearCoatBase.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
            glslsource("if (dbgid==53.0) {
        finalColor.rgb = sheenBase.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
            glslsource("if (dbgid==54.0) {
        finalColor.rgb = reflectionOut.environmentIrradiance.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
            glslsource("if (dbgid==60.0) {
        finalColor.rgb = surfaceAlbedo.rgb;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
            glslsource("if (dbgid==61.0) {
        finalColor.rgb = clearcoatOut.specularEnvironmentR0;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
//             glslsource("if (dbgid==62.0) {
//         finalColor.rgb = vec3(reflectivityOut.metallicRoughness.r);
// }");
//             glslsource("if (dbgid==71.0) {
//         finalColor.rgb = reflectivityOut.metallicF0;
// }");
            glslsource("if (dbgid==63.0) {
        finalColor.rgb = vec3(roughness);
    }");
            glslsource("if (dbgid==64.0) {
        finalColor.rgb = vec3(alphaG);
    }");
            glslsource("if (dbgid==65.0) {
        finalColor.rgb = vec3(NdotV);
    }");
//             glslsource("if (dbgid==66.0) {
//         finalColor.rgb = clearcoatOut.clearCoatColor.rgb;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
            glslsource("if (dbgid==67.0) {
        finalColor.rgb = vec3(clearcoatOut.clearCoatRoughness);
    }");
//             glslsource("if (dbgid==68.0) {
//         finalColor.rgb = vec3(clearcoatOut.clearCoatNdotV);
// }");
//             glslsource("if (dbgid==69.0) {
//         finalColor.rgb = subSurfaceOut.transmittance;
// }");
//             glslsource("if (dbgid==70.0) {
//         finalColor.rgb = subSurfaceOut.refractionTransmittance;
// }");
            glslsource("if (dbgid==80.0) {
        finalColor.rgb = vec3(seo);
    }");
            glslsource("if (dbgid==81.0) {
        finalColor.rgb = vec3(eho);
    }");
            glslsource("if (dbgid==82.0) {
        finalColor.rgb = vec3(energyConservationFactor);
    }");
            glslsource("if (dbgid==83.0) {
        finalColor.rgb = specularEnvironmentReflectance;
        finalColor.rgb = toGammaSpace(finalColor.rgb);
    }");
//             glslsource("if (dbgid==84.0) {
//         finalColor.rgb = clearcoatOut.clearCoatEnvironmentReflectance;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
//             glslsource("if (dbgid==85.0) {
//         finalColor.rgb = sheenOut.sheenEnvironmentReflectance;
//         finalColor.rgb = toGammaSpace(finalColor.rgb);
// }");
//             glslsource("if (dbgid==86.0) {
//         finalColor.rgb = vec3(luminanceOverAlpha);
// }");
            glslsource("if (dbgid==87.0) {
        finalColor.rgb = vec3(alpha);
    }");

            glslsource("
        finalColor.a = 1.0;
    }
");

            // output.color = vec4(finalColor.rgb, finalColor.a);
            output.color = finalColor;

        }
    }

    public function new() {
        super();

        this.debugid = 2;
    }
}