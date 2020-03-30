
#define PBR
#define ALBEDODIRECTUV 0
#define AMBIENTDIRECTUV 0
#define OPACITYDIRECTUV 0
#define ALPHATESTVALUE 0.4
#define SPECULAROVERALPHA
#define RADIANCEOVERALPHA
#define EMISSIVEDIRECTUV 0
#define REFLECTIVITYDIRECTUV 0
#define SPECULARTERM
#define LODBASEDMICROSFURACE
#define MICROSURFACEMAPDIRECTUV 0
#define ENVIRONMENTBRDF
#define NORMAL
#define BUMPDIRECTUV 0
#define NORMALXYSCALE
#define LIGHTMAPDIRECTUV 0
#define REFLECTION
#define REFLECTIONMAP_3D
#define REFLECTIONMAP_CUBIC
#define USESPHERICALFROMREFLECTIONMAP
#define REFRACTION
#define REFRACTIONMAP_3D
#define LINKREFRACTIONTOTRANSPARENCY
#define NUM_BONE_INFLUENCERS 0
#define BonesPerMesh 0
#define NUM_MORPH_INFLUENCERS 0
#define IMAGEPROCESSING
#define VIGNETTEBLENDMODEMULTIPLY
#define CONTRAST
#define EXPOSURE
#define USEPHYSICALLIGHTFALLOFF
#define LIGHT0
#define POINTLIGHT0

#if defined(BUMP) || !defined(NORMAL) || defined(FORCENORMALFORWARD)
    #extension GL_OES_standard_derivatives : enable
#endif
#ifdef LODBASEDMICROSFURACE
    #extension GL_EXT_shader_texture_lod : enable
#endif
#ifdef LOGARITHMICDEPTH
    #extension GL_EXT_frag_depth : enable
#endif
precision highp float;
uniform vec3 vReflectionColor;
uniform vec4 vAlbedoColor;
uniform vec4 vLightingIntensity;
uniform vec4 vReflectivityColor;
uniform vec3 vEmissiveColor;
#ifdef ALBEDO
    uniform vec2 vAlbedoInfos;
#endif
#ifdef AMBIENT
    uniform vec3 vAmbientInfos;
#endif
#ifdef BUMP
    uniform vec3 vBumpInfos;
    uniform vec4 vNormalReoderParams;
#endif
#ifdef OPACITY 
    uniform vec2 vOpacityInfos;
#endif
#ifdef EMISSIVE
    uniform vec2 vEmissiveInfos;
#endif
#ifdef LIGHTMAP
    uniform vec2 vLightmapInfos;
#endif
#ifdef REFLECTIVITY
    uniform vec3 vReflectivityInfos;
#endif
#ifdef MICROSURFACEMAP
    uniform vec2 vMicroSurfaceSamplerInfos;
#endif

#if defined(REFLECTIONMAP_SPHERICAL) || defined(REFLECTIONMAP_PROJECTION) || defined(REFRACTION)
    uniform mat4 view;
#endif

#ifdef REFRACTION
    uniform vec4 vRefractionInfos;
    uniform mat4 refractionMatrix;
    uniform vec3 vRefractionMicrosurfaceInfos;
#endif

#ifdef REFLECTION
    uniform vec2 vReflectionInfos;
    uniform mat4 reflectionMatrix;
    uniform vec3 vReflectionMicrosurfaceInfos;
#endif
uniform vec4 vEyePosition;
uniform vec3 vAmbientColor;
uniform vec4 vCameraInfos;
varying vec3 vPositionW;
#ifdef MAINUV1
    varying vec2 vMainUV1;
#endif 
#ifdef MAINUV2 
    varying vec2 vMainUV2;
#endif 
#ifdef NORMAL
    varying vec3 vNormalW;
    #if defined(USESPHERICALFROMREFLECTIONMAP) && !defined(USESPHERICALINFRAGMENT)
        varying vec3 vEnvironmentIrradiance;
    #endif
#endif
#ifdef VERTEXCOLOR
    varying vec4 vColor;
#endif

#ifdef LIGHT0
    uniform vec4 vLightData0;
    uniform vec4 vLightDiffuse0;
    #ifdef SPECULARTERM
        uniform vec3 vLightSpecular0;
    #else
        vec3 vLightSpecular0 = vec3(0.);
    #endif
    #ifdef SHADOW0
        #if defined(SHADOWCUBE0)
            uniform samplerCube shadowSampler0;
        #else
            varying vec4 vPositionFromLight0;
            varying float vDepthMetric0;
            uniform sampler2D shadowSampler0;
            uniform mat4 lightMatrix0;
        #endif
        uniform vec4 shadowsInfo0;
        uniform vec2 depthValues0;
    #endif
    #ifdef SPOTLIGHT0
        uniform vec4 vLightDirection0;
    #endif
    #ifdef HEMILIGHT0
        uniform vec3 vLightGround0;
    #endif
#endif
#ifdef LIGHT1
    uniform vec4 vLightData1;
    uniform vec4 vLightDiffuse1;
    #ifdef SPECULARTERM
        uniform vec3 vLightSpecular1;
    #else
        vec3 vLightSpecular1 = vec3(0.);
    #endif
    #ifdef SHADOW1
        #if defined(SHADOWCUBE1)
            uniform samplerCube shadowSampler1;
        #else
            varying vec4 vPositionFromLight1;
            varying float vDepthMetric1;
            uniform sampler2D shadowSampler1;
            uniform mat4 lightMatrix1;
        #endif
        uniform vec4 shadowsInfo1;
        uniform vec2 depthValues1;
    #endif
    #ifdef SPOTLIGHT1
        uniform vec4 vLightDirection1;
    #endif
    #ifdef HEMILIGHT1
        uniform vec3 vLightGround1;
    #endif
#endif
#ifdef LIGHT2
    uniform vec4 vLightData2;
    uniform vec4 vLightDiffuse2;
    #ifdef SPECULARTERM
        uniform vec3 vLightSpecular2;
    #else
        vec3 vLightSpecular2 = vec3(0.);
    #endif
    #ifdef SHADOW2
        #if defined(SHADOWCUBE2)
            uniform samplerCube shadowSampler2;
        #else
            varying vec4 vPositionFromLight2;
            varying float vDepthMetric2;
            uniform sampler2D shadowSampler2;
            uniform mat4 lightMatrix2;
        #endif
        uniform vec4 shadowsInfo2;
        uniform vec2 depthValues2;
    #endif
    #ifdef SPOTLIGHT2
        uniform vec4 vLightDirection2;
    #endif
    #ifdef HEMILIGHT2
        uniform vec3 vLightGround2;
    #endif
#endif
#ifdef LIGHT3
    uniform vec4 vLightData3;
    uniform vec4 vLightDiffuse3;
    #ifdef SPECULARTERM
        uniform vec3 vLightSpecular3;
    #else
        vec3 vLightSpecular3 = vec3(0.);
    #endif
    #ifdef SHADOW3
        #if defined(SHADOWCUBE3)
            uniform samplerCube shadowSampler3;
        #else
            varying vec4 vPositionFromLight3;
            varying float vDepthMetric3;
            uniform sampler2D shadowSampler3;
            uniform mat4 lightMatrix3;
        #endif
        uniform vec4 shadowsInfo3;
        uniform vec2 depthValues3;
    #endif
    #ifdef SPOTLIGHT3
        uniform vec4 vLightDirection3;
    #endif
    #ifdef HEMILIGHT3
        uniform vec3 vLightGround3;
    #endif
#endif


#ifdef ALBEDO
    #if ALBEDODIRECTUV == 1
        #define vAlbedoUV vMainUV1
        #elif ALBEDODIRECTUV == 2
        #define vAlbedoUV vMainUV2
    #else
        varying vec2 vAlbedoUV;
    #endif
    uniform sampler2D albedoSampler;
#endif
#ifdef AMBIENT
    #if AMBIENTDIRECTUV == 1
        #define vAmbientUV vMainUV1
        #elif AMBIENTDIRECTUV == 2
        #define vAmbientUV vMainUV2
    #else
        varying vec2 vAmbientUV;
    #endif
    uniform sampler2D ambientSampler;
#endif
#ifdef OPACITY
    #if OPACITYDIRECTUV == 1
        #define vOpacityUV vMainUV1
        #elif OPACITYDIRECTUV == 2
        #define vOpacityUV vMainUV2
    #else
        varying vec2 vOpacityUV;
    #endif
    uniform sampler2D opacitySampler;
#endif
#ifdef EMISSIVE
    #if EMISSIVEDIRECTUV == 1
        #define vEmissiveUV vMainUV1
        #elif EMISSIVEDIRECTUV == 2
        #define vEmissiveUV vMainUV2
    #else
        varying vec2 vEmissiveUV;
    #endif
    uniform sampler2D emissiveSampler;
#endif
#ifdef LIGHTMAP
    #if LIGHTMAPDIRECTUV == 1
        #define vLightmapUV vMainUV1
        #elif LIGHTMAPDIRECTUV == 2
        #define vLightmapUV vMainUV2
    #else
        varying vec2 vLightmapUV;
    #endif
    uniform sampler2D lightmapSampler;
#endif
#ifdef REFLECTIVITY
    #if REFLECTIVITYDIRECTUV == 1
        #define vReflectivityUV vMainUV1
        #elif REFLECTIVITYDIRECTUV == 2
        #define vReflectivityUV vMainUV2
    #else
        varying vec2 vReflectivityUV;
    #endif
    uniform sampler2D reflectivitySampler;
#endif
#ifdef MICROSURFACEMAP
    #if MICROSURFACEMAPDIRECTUV == 1
        #define vMicroSurfaceSamplerUV vMainUV1
        #elif MICROSURFACEMAPDIRECTUV == 2
        #define vMicroSurfaceSamplerUV vMainUV2
    #else
        varying vec2 vMicroSurfaceSamplerUV;
    #endif
    uniform sampler2D microSurfaceSampler;
#endif

#ifdef REFRACTION
    #ifdef REFRACTIONMAP_3D
        #define sampleRefraction(s, c) textureCube(s, c)
        uniform samplerCube refractionSampler;
        #ifdef LODBASEDMICROSFURACE
            #define sampleRefractionLod(s, c, l) textureCubeLodEXT(s, c, l)
        #else
            uniform samplerCube refractionSamplerLow;
            uniform samplerCube refractionSamplerHigh;
        #endif
    #else
        #define sampleRefraction(s, c) texture2D(s, c)
        uniform sampler2D refractionSampler;
        #ifdef LODBASEDMICROSFURACE
            #define sampleRefractionLod(s, c, l) texture2DLodEXT(s, c, l)
        #else
            uniform samplerCube refractionSamplerLow;
            uniform samplerCube refractionSamplerHigh;
        #endif
    #endif
#endif

#ifdef REFLECTION
    #ifdef REFLECTIONMAP_3D
        #define sampleReflection(s, c) textureCube(s, c)
        uniform samplerCube reflectionSampler;
        #ifdef LODBASEDMICROSFURACE
            #define sampleReflectionLod(s, c, l) textureCubeLodEXT(s, c, l)
        #else
            uniform samplerCube reflectionSamplerLow;
            uniform samplerCube reflectionSamplerHigh;
        #endif
    #else
        #define sampleReflection(s, c) texture2D(s, c)
        uniform sampler2D reflectionSampler;
        #ifdef LODBASEDMICROSFURACE
            #define sampleReflectionLod(s, c, l) texture2DLodEXT(s, c, l)
        #else
            uniform samplerCube reflectionSamplerLow;
            uniform samplerCube reflectionSamplerHigh;
        #endif
    #endif
    #ifdef REFLECTIONMAP_SKYBOX
        varying vec3 vPositionUVW;
    #else
        #if defined(REFLECTIONMAP_EQUIRECTANGULAR_FIXED) || defined(REFLECTIONMAP_MIRROREDEQUIRECTANGULAR_FIXED)
            varying vec3 vDirectionW;
        #endif
    #endif
    vec3 computeReflectionCoords(vec4 worldPos, vec3 worldNormal) {
        #if defined(REFLECTIONMAP_EQUIRECTANGULAR_FIXED) || defined(REFLECTIONMAP_MIRROREDEQUIRECTANGULAR_FIXED)
            vec3 direction = normalize(vDirectionW);
            float t = clamp(direction.y*-0.5+0.5, 0., 1.0);
            float s = atan(direction.z, direction.x)*RECIPROCAL_PI2+0.5;
            #ifdef REFLECTIONMAP_MIRROREDEQUIRECTANGULAR_FIXED
                return vec3(1.0-s, t, 0);
            #else
                return vec3(s, t, 0);
            #endif
        #endif
        #ifdef REFLECTIONMAP_EQUIRECTANGULAR
            vec3 cameraToVertex = normalize(worldPos.xyz-vEyePosition.xyz);
            vec3 r = reflect(cameraToVertex, worldNormal);
            float t = clamp(r.y*-0.5+0.5, 0., 1.0);
            float s = atan(r.z, r.x)*RECIPROCAL_PI2+0.5;
            return vec3(s, t, 0);
        #endif
        #ifdef REFLECTIONMAP_SPHERICAL
            vec3 viewDir = normalize(vec3(view*worldPos));
            vec3 viewNormal = normalize(vec3(view*vec4(worldNormal, 0.0)));
            vec3 r = reflect(viewDir, viewNormal);
            r.z = r.z-1.0;
            float m = 2.0*length(r);
            return vec3(r.x/m+0.5, 1.0-r.y/m-0.5, 0);
        #endif
        #ifdef REFLECTIONMAP_PLANAR
            vec3 viewDir = worldPos.xyz-vEyePosition.xyz;
            vec3 coords = normalize(reflect(viewDir, worldNormal));
            return vec3(reflectionMatrix*vec4(coords, 1));
        #endif
        #ifdef REFLECTIONMAP_CUBIC
            vec3 viewDir = worldPos.xyz-vEyePosition.xyz;
            vec3 coords = reflect(viewDir, worldNormal);
            #ifdef INVERTCUBICMAP
                coords.y = 1.0-coords.y;
            #endif
            return vec3(reflectionMatrix*vec4(coords, 0));
        #endif
        #ifdef REFLECTIONMAP_PROJECTION
            return vec3(reflectionMatrix*(view*worldPos));
        #endif
        #ifdef REFLECTIONMAP_SKYBOX
            return vPositionUVW;
        #endif
        #ifdef REFLECTIONMAP_EXPLICIT
            return vec3(0, 0, 0);
        #endif
    }
#endif
#ifdef ENVIRONMENTBRDF
    uniform sampler2D environmentBrdfSampler;
#endif

#ifndef FROMLINEARSPACE
    #define FROMLINEARSPACE;
#endif
#ifdef EXPOSURE
    uniform float exposureLinear;
#endif
#ifdef CONTRAST
    uniform float contrast;
#endif
#ifdef VIGNETTE
    uniform vec2 vInverseScreenSize;
    uniform vec4 vignetteSettings1;
    uniform vec4 vignetteSettings2;
#endif
#ifdef COLORCURVES
    uniform vec4 vCameraColorCurveNegative;
    uniform vec4 vCameraColorCurveNeutral;
    uniform vec4 vCameraColorCurvePositive;
#endif
#ifdef COLORGRADING
    uniform sampler2D txColorTransform;
    uniform vec4 colorTransformSettings;
#endif
const float PI = 3.1415926535897932384626433832795;
const float LinearEncodePowerApprox = 2.2;
const float GammaEncodePowerApprox = 1.0/LinearEncodePowerApprox;
const vec3 LuminanceEncodeApprox = vec3(0.2126, 0.7152, 0.0722);
mat3 transposeMat3(mat3 inMatrix) {
    vec3 i0 = inMatrix[0];
    vec3 i1 = inMatrix[1];
    vec3 i2 = inMatrix[2];
    mat3 outMatrix = mat3(
    vec3(i0.x, i1.x, i2.x), vec3(i0.y, i1.y, i2.y), vec3(i0.z, i1.z, i2.z)
    );
    return outMatrix;
}
float computeFallOff(float value, vec2 clipSpace, float frustumEdgeFalloff) {
    float mask = smoothstep(1.0-frustumEdgeFalloff, 1.0, clamp(dot(clipSpace, clipSpace), 0., 1.));
    return mix(value, 1.0, mask);
}
vec3 applyEaseInOut(vec3 x) {
    return x*x*(3.0-2.0*x);
}
vec3 toLinearSpace(vec3 color) {
    return pow(color, vec3(LinearEncodePowerApprox));
}
vec3 toGammaSpace(vec3 color) {
    return pow(color, vec3(GammaEncodePowerApprox));
}
float square(float value) {
    return value*value;
}
float getLuminance(vec3 color) {
    return clamp(dot(color, LuminanceEncodeApprox), 0., 1.);
}
#ifdef COLORGRADING
    
    vec3 sampleTexture3D(sampler2D colorTransform, vec3 color, vec2 sampler3dSetting) {
        float sliceSize = 2.0*sampler3dSetting.x;
        #ifdef SAMPLER3DGREENDEPTH
            float sliceContinuous = (color.g-sampler3dSetting.x)*sampler3dSetting.y;
        #else
            float sliceContinuous = (color.b-sampler3dSetting.x)*sampler3dSetting.y;
        #endif
        float sliceInteger = floor(sliceContinuous);
        float sliceFraction = sliceContinuous-sliceInteger;
        #ifdef SAMPLER3DGREENDEPTH
            vec2 sliceUV = color.rb;
        #else
            vec2 sliceUV = color.rg;
        #endif
        sliceUV.x *= sliceSize;
        sliceUV.x += sliceInteger*sliceSize;
        sliceUV = clamp(sliceUV, 0., 1.);
        vec4 slice0Color = texture2D(colorTransform, sliceUV);
        sliceUV.x += sliceSize;
        sliceUV = clamp(sliceUV, 0., 1.);
        vec4 slice1Color = texture2D(colorTransform, sliceUV);
        vec3 result = mix(slice0Color.rgb, slice1Color.rgb, sliceFraction);
        #ifdef SAMPLER3DBGRMAP
            color.rgb = result.rgb;
        #else
            color.rgb = result.bgr;
        #endif
        return color;
    }
#endif
vec4 applyImageProcessing(vec4 result) {
    #ifdef EXPOSURE
        result.rgb *= exposureLinear;
    #endif
    #ifdef VIGNETTE
        
        vec2 viewportXY = gl_FragCoord.xy*vInverseScreenSize;
        viewportXY = viewportXY*2.0-1.0;
        vec3 vignetteXY1 = vec3(viewportXY*vignetteSettings1.xy+vignetteSettings1.zw, 1.0);
        float vignetteTerm = dot(vignetteXY1, vignetteXY1);
        float vignette = pow(vignetteTerm, vignetteSettings2.w);
        vec3 vignetteColor = vignetteSettings2.rgb;
        #ifdef VIGNETTEBLENDMODEMULTIPLY
            vec3 vignetteColorMultiplier = mix(vignetteColor, vec3(1, 1, 1), vignette);
            result.rgb *= vignetteColorMultiplier;
        #endif
        #ifdef VIGNETTEBLENDMODEOPAQUE
            result.rgb = mix(vignetteColor, result.rgb, vignette);
        #endif
    #endif
    #ifdef TONEMAPPING
        const float tonemappingCalibration = 1.590579;
        result.rgb = 1.0-exp2(-tonemappingCalibration*result.rgb);
    #endif
    
    result.rgb = toGammaSpace(result.rgb);
    result.rgb = clamp(result.rgb, 0.0, 1.0);
    #ifdef CONTRAST
        
        vec3 resultHighContrast = applyEaseInOut(result.rgb);
        if (contrast<1.0) {
            result.rgb = mix(vec3(0.5, 0.5, 0.5), result.rgb, contrast);
        }
        else {
            result.rgb = mix(result.rgb, resultHighContrast, contrast-1.0);
        }
    #endif
    
    #ifdef COLORGRADING
        vec3 colorTransformInput = result.rgb*colorTransformSettings.xxx+colorTransformSettings.yyy;
        vec3 colorTransformOutput = sampleTexture3D(txColorTransform, colorTransformInput, colorTransformSettings.yz).rgb;
        result.rgb = mix(result.rgb, colorTransformOutput, colorTransformSettings.www);
    #endif
    #ifdef COLORCURVES
        
        float luma = getLuminance(result.rgb);
        vec2 curveMix = clamp(vec2(luma*3.0-1.5, luma*-3.0+1.5), vec2(0.0), vec2(1.0));
        vec4 colorCurve = vCameraColorCurveNeutral+curveMix.x*vCameraColorCurvePositive-curveMix.y*vCameraColorCurveNegative;
        result.rgb *= colorCurve.rgb;
        result.rgb = mix(vec3(luma), result.rgb, colorCurve.a);
    #endif
    return result;
}
#ifdef SHADOWS
    #ifndef SHADOWFLOAT
        float unpack(vec4 color) {
            const vec4 bit_shift = vec4(1.0/(255.0*255.0*255.0), 1.0/(255.0*255.0), 1.0/255.0, 1.0);
            return dot(color, bit_shift);
        }
    #endif
    float computeShadowCube(vec3 lightPosition, samplerCube shadowSampler, float darkness, vec2 depthValues) {
        vec3 directionToLight = vPositionW-lightPosition;
        float depth = length(directionToLight);
        depth = (depth+depthValues.x)/(depthValues.y);
        depth = clamp(depth, 0., 1.0);
        directionToLight = normalize(directionToLight);
        directionToLight.y = -directionToLight.y;
        #ifndef SHADOWFLOAT
            float shadow = unpack(textureCube(shadowSampler, directionToLight));
        #else
            float shadow = textureCube(shadowSampler, directionToLight).x;
        #endif
        if (depth>shadow) {
            return darkness;
        }
        return 1.0;
    }
    float computeShadowWithPCFCube(vec3 lightPosition, samplerCube shadowSampler, float mapSize, float darkness, vec2 depthValues) {
        vec3 directionToLight = vPositionW-lightPosition;
        float depth = length(directionToLight);
        depth = (depth+depthValues.x)/(depthValues.y);
        depth = clamp(depth, 0., 1.0);
        directionToLight = normalize(directionToLight);
        directionToLight.y = -directionToLight.y;
        float visibility = 1.;
        vec3 poissonDisk[4];
        poissonDisk[0] = vec3(-1.0, 1.0, -1.0);
        poissonDisk[1] = vec3(1.0, -1.0, -1.0);
        poissonDisk[2] = vec3(-1.0, -1.0, -1.0);
        poissonDisk[3] = vec3(1.0, -1.0, 1.0);
        #ifndef SHADOWFLOAT
            if (unpack(textureCube(shadowSampler, directionToLight+poissonDisk[0]*mapSize))<depth) visibility -= 0.25;
            if (unpack(textureCube(shadowSampler, directionToLight+poissonDisk[1]*mapSize))<depth) visibility -= 0.25;
            if (unpack(textureCube(shadowSampler, directionToLight+poissonDisk[2]*mapSize))<depth) visibility -= 0.25;
            if (unpack(textureCube(shadowSampler, directionToLight+poissonDisk[3]*mapSize))<depth) visibility -= 0.25;
        #else
            if (textureCube(shadowSampler, directionToLight+poissonDisk[0]*mapSize).x<depth) visibility -= 0.25;
            if (textureCube(shadowSampler, directionToLight+poissonDisk[1]*mapSize).x<depth) visibility -= 0.25;
            if (textureCube(shadowSampler, directionToLight+poissonDisk[2]*mapSize).x<depth) visibility -= 0.25;
            if (textureCube(shadowSampler, directionToLight+poissonDisk[3]*mapSize).x<depth) visibility -= 0.25;
        #endif
        return min(1.0, visibility+darkness);
    }
    float computeShadowWithESMCube(vec3 lightPosition, samplerCube shadowSampler, float darkness, float depthScale, vec2 depthValues) {
        vec3 directionToLight = vPositionW-lightPosition;
        float depth = length(directionToLight);
        depth = (depth+depthValues.x)/(depthValues.y);
        float shadowPixelDepth = clamp(depth, 0., 1.0);
        directionToLight = normalize(directionToLight);
        directionToLight.y = -directionToLight.y;
        #ifndef SHADOWFLOAT
            float shadowMapSample = unpack(textureCube(shadowSampler, directionToLight));
        #else
            float shadowMapSample = textureCube(shadowSampler, directionToLight).x;
        #endif
        float esm = 1.0-clamp(exp(min(87., depthScale*shadowPixelDepth))*shadowMapSample, 0., 1.-darkness);
        return esm;
    }
    float computeShadowWithCloseESMCube(vec3 lightPosition, samplerCube shadowSampler, float darkness, float depthScale, vec2 depthValues) {
        vec3 directionToLight = vPositionW-lightPosition;
        float depth = length(directionToLight);
        depth = (depth+depthValues.x)/(depthValues.y);
        float shadowPixelDepth = clamp(depth, 0., 1.0);
        directionToLight = normalize(directionToLight);
        directionToLight.y = -directionToLight.y;
        #ifndef SHADOWFLOAT
            float shadowMapSample = unpack(textureCube(shadowSampler, directionToLight));
        #else
            float shadowMapSample = textureCube(shadowSampler, directionToLight).x;
        #endif
        float esm = clamp(exp(min(87., -depthScale*(shadowPixelDepth-shadowMapSample))), darkness, 1.);
        return esm;
    }
    float computeShadow(vec4 vPositionFromLight, float depthMetric, sampler2D shadowSampler, float darkness, float frustumEdgeFalloff) {
        vec3 clipSpace = vPositionFromLight.xyz/vPositionFromLight.w;
        vec2 uv = 0.5*clipSpace.xy+vec2(0.5);
        if (uv.x<0. || uv.x>1.0 || uv.y<0. || uv.y>1.0) {
            return 1.0;
        }
        float shadowPixelDepth = clamp(depthMetric, 0., 1.0);
        #ifndef SHADOWFLOAT
            float shadow = unpack(texture2D(shadowSampler, uv));
        #else
            float shadow = texture2D(shadowSampler, uv).x;
        #endif
        if (shadowPixelDepth>shadow) {
            return computeFallOff(darkness, clipSpace.xy, frustumEdgeFalloff);
        }
        return 1.;
    }
    float computeShadowWithPCF(vec4 vPositionFromLight, float depthMetric, sampler2D shadowSampler, float mapSize, float darkness, float frustumEdgeFalloff) {
        vec3 clipSpace = vPositionFromLight.xyz/vPositionFromLight.w;
        vec2 uv = 0.5*clipSpace.xy+vec2(0.5);
        if (uv.x<0. || uv.x>1.0 || uv.y<0. || uv.y>1.0) {
            return 1.0;
        }
        float shadowPixelDepth = clamp(depthMetric, 0., 1.0);
        float visibility = 1.;
        vec2 poissonDisk[4];
        poissonDisk[0] = vec2(-0.94201624, -0.39906216);
        poissonDisk[1] = vec2(0.94558609, -0.76890725);
        poissonDisk[2] = vec2(-0.094184101, -0.92938870);
        poissonDisk[3] = vec2(0.34495938, 0.29387760);
        #ifndef SHADOWFLOAT
            if (unpack(texture2D(shadowSampler, uv+poissonDisk[0]*mapSize))<shadowPixelDepth) visibility -= 0.25;
            if (unpack(texture2D(shadowSampler, uv+poissonDisk[1]*mapSize))<shadowPixelDepth) visibility -= 0.25;
            if (unpack(texture2D(shadowSampler, uv+poissonDisk[2]*mapSize))<shadowPixelDepth) visibility -= 0.25;
            if (unpack(texture2D(shadowSampler, uv+poissonDisk[3]*mapSize))<shadowPixelDepth) visibility -= 0.25;
        #else
            if (texture2D(shadowSampler, uv+poissonDisk[0]*mapSize).x<shadowPixelDepth) visibility -= 0.25;
            if (texture2D(shadowSampler, uv+poissonDisk[1]*mapSize).x<shadowPixelDepth) visibility -= 0.25;
            if (texture2D(shadowSampler, uv+poissonDisk[2]*mapSize).x<shadowPixelDepth) visibility -= 0.25;
            if (texture2D(shadowSampler, uv+poissonDisk[3]*mapSize).x<shadowPixelDepth) visibility -= 0.25;
        #endif
        return computeFallOff(min(1.0, visibility+darkness), clipSpace.xy, frustumEdgeFalloff);
    }
    float computeShadowWithESM(vec4 vPositionFromLight, float depthMetric, sampler2D shadowSampler, float darkness, float depthScale, float frustumEdgeFalloff) {
        vec3 clipSpace = vPositionFromLight.xyz/vPositionFromLight.w;
        vec2 uv = 0.5*clipSpace.xy+vec2(0.5);
        if (uv.x<0. || uv.x>1.0 || uv.y<0. || uv.y>1.0) {
            return 1.0;
        }
        float shadowPixelDepth = clamp(depthMetric, 0., 1.0);
        #ifndef SHADOWFLOAT
            float shadowMapSample = unpack(texture2D(shadowSampler, uv));
        #else
            float shadowMapSample = texture2D(shadowSampler, uv).x;
        #endif
        float esm = 1.0-clamp(exp(min(87., depthScale*shadowPixelDepth))*shadowMapSample, 0., 1.-darkness);
        return computeFallOff(esm, clipSpace.xy, frustumEdgeFalloff);
    }
    float computeShadowWithCloseESM(vec4 vPositionFromLight, float depthMetric, sampler2D shadowSampler, float darkness, float depthScale, float frustumEdgeFalloff) {
        vec3 clipSpace = vPositionFromLight.xyz/vPositionFromLight.w;
        vec2 uv = 0.5*clipSpace.xy+vec2(0.5);
        if (uv.x<0. || uv.x>1.0 || uv.y<0. || uv.y>1.0) {
            return 1.0;
        }
        float shadowPixelDepth = clamp(depthMetric, 0., 1.0);
        #ifndef SHADOWFLOAT
            float shadowMapSample = unpack(texture2D(shadowSampler, uv));
        #else
            float shadowMapSample = texture2D(shadowSampler, uv).x;
        #endif
        float esm = clamp(exp(min(87., -depthScale*(shadowPixelDepth-shadowMapSample))), darkness, 1.);
        return computeFallOff(esm, clipSpace.xy, frustumEdgeFalloff);
    }
#endif


#define RECIPROCAL_PI2 0.15915494
#define FRESNEL_MAXIMUM_ON_ROUGH 0.25

const float kRougnhessToAlphaScale = 0.1;
const float kRougnhessToAlphaOffset = 0.29248125;
float convertRoughnessToAverageSlope(float roughness) {
    const float kMinimumVariance = 0.0005;
    float alphaG = square(roughness)+kMinimumVariance;
    return alphaG;
}
float smithVisibilityG1_TrowbridgeReitzGGX(float dot, float alphaG) {
    float tanSquared = (1.0-dot*dot)/(dot*dot);
    return 2.0/(1.0+sqrt(1.0+alphaG*alphaG*tanSquared));
}
float smithVisibilityG_TrowbridgeReitzGGX_Walter(float NdotL, float NdotV, float alphaG) {
    return smithVisibilityG1_TrowbridgeReitzGGX(NdotL, alphaG)*smithVisibilityG1_TrowbridgeReitzGGX(NdotV, alphaG);
}
float normalDistributionFunction_TrowbridgeReitzGGX(float NdotH, float alphaG) {
    float a2 = square(alphaG);
    float d = NdotH*NdotH*(a2-1.0)+1.0;
    return a2/(PI*d*d);
}
vec3 fresnelSchlickGGX(float VdotH, vec3 reflectance0, vec3 reflectance90) {
    return reflectance0+(reflectance90-reflectance0)*pow(clamp(1.0-VdotH, 0., 1.), 5.0);
}
vec3 fresnelSchlickEnvironmentGGX(float VdotN, vec3 reflectance0, vec3 reflectance90, float smoothness) {
    float weight = mix(FRESNEL_MAXIMUM_ON_ROUGH, 1.0, smoothness);
    return reflectance0+weight*(reflectance90-reflectance0)*pow(clamp(1.0-VdotN, 0., 1.), 5.0);
}
vec3 computeSpecularTerm(float NdotH, float NdotL, float NdotV, float VdotH, float roughness, vec3 reflectance0, vec3 reflectance90) {
    float alphaG = convertRoughnessToAverageSlope(roughness);
    float distribution = normalDistributionFunction_TrowbridgeReitzGGX(NdotH, alphaG);
    float visibility = smithVisibilityG_TrowbridgeReitzGGX_Walter(NdotL, NdotV, alphaG);
    visibility /= (4.0*NdotL*NdotV);
    float specTerm = max(0., visibility*distribution)*NdotL;
    vec3 fresnel = fresnelSchlickGGX(VdotH, reflectance0, reflectance90);
    return fresnel*specTerm;
}
float computeDiffuseTerm(float NdotL, float NdotV, float VdotH, float roughness) {
    float diffuseFresnelNV = pow(clamp(1.0-NdotL, 0.000001, 1.), 5.0);
    float diffuseFresnelNL = pow(clamp(1.0-NdotV, 0.000001, 1.), 5.0);
    float diffuseFresnel90 = 0.5+2.0*VdotH*VdotH*roughness;
    float fresnel = (1.0+(diffuseFresnel90-1.0)*diffuseFresnelNL) *
    (1.0+(diffuseFresnel90-1.0)*diffuseFresnelNV);
    return fresnel*NdotL/PI;
}
float adjustRoughnessFromLightProperties(float roughness, float lightRadius, float lightDistance) {
    #ifdef USEPHYSICALLIGHTFALLOFF
        
        float lightRoughness = lightRadius/lightDistance;
        float totalRoughness = clamp(lightRoughness+roughness, 0., 1.);
        return totalRoughness;
    #else
        return roughness;
    #endif
}
float computeDefaultMicroSurface(float microSurface, vec3 reflectivityColor) {
    const float kReflectivityNoAlphaWorkflow_SmoothnessMax = 0.95;
    float reflectivityLuminance = getLuminance(reflectivityColor);
    float reflectivityLuma = sqrt(reflectivityLuminance);
    microSurface = reflectivityLuma*kReflectivityNoAlphaWorkflow_SmoothnessMax;
    return microSurface;
}
float fresnelGrazingReflectance(float reflectance0) {
    float reflectance90 = clamp(reflectance0*25.0, 0.0, 1.0);
    return reflectance90;
}
#define UNPACK_LOD(x) (1.0-x)*255.0
float getLodFromAlphaG(float cubeMapDimensionPixels, float alphaG, float NdotV) {
    float microsurfaceAverageSlope = alphaG;
    microsurfaceAverageSlope *= sqrt(abs(NdotV));
    float microsurfaceAverageSlopeTexels = microsurfaceAverageSlope*cubeMapDimensionPixels;
    float lod = log2(microsurfaceAverageSlopeTexels);
    return lod;
}
float environmentRadianceOcclusion(float ambientOcclusion, float NdotVUnclamped) {
    float temp = NdotVUnclamped+ambientOcclusion;
    return clamp(square(temp)-1.0+ambientOcclusion, 0.0, 1.0);
}
float environmentHorizonOcclusion(vec3 reflection, vec3 normal) {
    #ifdef REFLECTIONMAP_OPPOSITEZ
        reflection.z *= -1.0;
    #endif
    float temp = clamp( 1.0+1.1*dot(reflection, normal), 0.0, 1.0);
    return square(temp);
}
#ifdef USESPHERICALFROMREFLECTIONMAP
    uniform vec3 vSphericalX;
    uniform vec3 vSphericalY;
    uniform vec3 vSphericalZ;
    uniform vec3 vSphericalXX_ZZ;
    uniform vec3 vSphericalYY_ZZ;
    uniform vec3 vSphericalZZ;
    uniform vec3 vSphericalXY;
    uniform vec3 vSphericalYZ;
    uniform vec3 vSphericalZX;
    vec3 quaternionVectorRotation_ScaledSqrtTwo(vec4 Q, vec3 V) {
        vec3 T = cross(Q.xyz, V);
        T += Q.www*V;
        return cross(Q.xyz, T)+V;
    }
    vec3 environmentIrradianceJones(vec3 normal) {
        float Nx = normal.x;
        float Ny = normal.y;
        float Nz = normal.z;
        vec3 C1 = vSphericalZZ.rgb;
        vec3 Cx = vSphericalX.rgb;
        vec3 Cy = vSphericalY.rgb;
        vec3 Cz = vSphericalZ.rgb;
        vec3 Cxx_zz = vSphericalXX_ZZ.rgb;
        vec3 Cyy_zz = vSphericalYY_ZZ.rgb;
        vec3 Cxy = vSphericalXY.rgb;
        vec3 Cyz = vSphericalYZ.rgb;
        vec3 Czx = vSphericalZX.rgb;
        vec3 a1 = Cyy_zz*Ny+Cy;
        vec3 a2 = Cyz*Nz+a1;
        vec3 b1 = Czx*Nz+Cx;
        vec3 b2 = Cxy*Ny+b1;
        vec3 b3 = Cxx_zz*Nx+b2;
        vec3 t1 = Cz*Nz+C1;
        vec3 t2 = a2*Ny+t1;
        vec3 t3 = b3*Nx+t2;
        return t3;
    }
#endif

struct lightingInfo {
    vec3 diffuse;
    #ifdef SPECULARTERM
        vec3 specular;
    #endif
};
float computeDistanceLightFalloff(vec3 lightOffset, float lightDistanceSquared, float range) {
    #ifdef USEPHYSICALLIGHTFALLOFF
        float lightDistanceFalloff = 1.0/((lightDistanceSquared+0.001));
    #else
        float lightDistanceFalloff = max(0., 1.0-length(lightOffset)/range);
    #endif
    return lightDistanceFalloff;
}
float computeDirectionalLightFalloff(vec3 lightDirection, vec3 directionToLightCenterW, float cosHalfAngle, float exponent) {
    float falloff = 0.0;
    #ifdef USEPHYSICALLIGHTFALLOFF
        const float kMinusLog2ConeAngleIntensityRatio = 6.64385618977;
        float concentrationKappa = kMinusLog2ConeAngleIntensityRatio/(1.0-cosHalfAngle);
        vec4 lightDirectionSpreadSG = vec4(-lightDirection*concentrationKappa, -concentrationKappa);
        falloff = exp2(dot(vec4(directionToLightCenterW, 1.0), lightDirectionSpreadSG));
    #else
        float cosAngle = max(0.000000000000001, dot(-lightDirection, directionToLightCenterW));
        if (cosAngle >= cosHalfAngle) {
            falloff = max(0., pow(cosAngle, exponent));
        }
    #endif
    return falloff;
}
lightingInfo computeLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec3 diffuseColor, vec3 specularColor, float rangeRadius, float roughness, float NdotV, vec3 reflectance0, vec3 reflectance90, out float NdotL) {
    lightingInfo result;
    vec3 lightDirection;
    float attenuation = 1.0;
    float lightDistance;
    if (lightData.w == 0.) {
        vec3 lightOffset = lightData.xyz-vPositionW;
        float lightDistanceSquared = dot(lightOffset, lightOffset);
        attenuation = computeDistanceLightFalloff(lightOffset, lightDistanceSquared, rangeRadius);
        lightDistance = sqrt(lightDistanceSquared);
        lightDirection = normalize(lightOffset);
    }
    else {
        lightDistance = length(-lightData.xyz);
        lightDirection = normalize(-lightData.xyz);
    }
    roughness = adjustRoughnessFromLightProperties(roughness, rangeRadius, lightDistance);
    vec3 H = normalize(viewDirectionW+lightDirection);
    NdotL = clamp(dot(vNormal, lightDirection), 0.00000000001, 1.0);
    float VdotH = clamp(dot(viewDirectionW, H), 0.0, 1.0);
    float diffuseTerm = computeDiffuseTerm(NdotL, NdotV, VdotH, roughness);
    result.diffuse = diffuseTerm*diffuseColor*attenuation;
    #ifdef SPECULARTERM
        
        float NdotH = clamp(dot(vNormal, H), 0.000000000001, 1.0);
        vec3 specTerm = computeSpecularTerm(NdotH, NdotL, NdotV, VdotH, roughness, reflectance0, reflectance90);
        result.specular = specTerm*diffuseColor*attenuation;
    #endif
    return result;
}
lightingInfo computeSpotLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec4 lightDirection, vec3 diffuseColor, vec3 specularColor, float rangeRadius, float roughness, float NdotV, vec3 reflectance0, vec3 reflectance90, out float NdotL) {
    lightingInfo result;
    vec3 lightOffset = lightData.xyz-vPositionW;
    vec3 directionToLightCenterW = normalize(lightOffset);
    float lightDistanceSquared = dot(lightOffset, lightOffset);
    float attenuation = computeDistanceLightFalloff(lightOffset, lightDistanceSquared, rangeRadius);
    float directionalAttenuation = computeDirectionalLightFalloff(lightDirection.xyz, directionToLightCenterW, lightDirection.w, lightData.w);
    attenuation *= directionalAttenuation;
    float lightDistance = sqrt(lightDistanceSquared);
    roughness = adjustRoughnessFromLightProperties(roughness, rangeRadius, lightDistance);
    vec3 H = normalize(viewDirectionW+directionToLightCenterW);
    NdotL = clamp(dot(vNormal, directionToLightCenterW), 0.000000000001, 1.0);
    float VdotH = clamp(dot(viewDirectionW, H), 0.0, 1.0);
    float diffuseTerm = computeDiffuseTerm(NdotL, NdotV, VdotH, roughness);
    result.diffuse = diffuseTerm*diffuseColor*attenuation;
    #ifdef SPECULARTERM
        
        float NdotH = clamp(dot(vNormal, H), 0.000000000001, 1.0);
        vec3 specTerm = computeSpecularTerm(NdotH, NdotL, NdotV, VdotH, roughness, reflectance0, reflectance90);
        result.specular = specTerm*diffuseColor*attenuation;
    #endif
    return result;
}
lightingInfo computeHemisphericLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec3 diffuseColor, vec3 specularColor, vec3 groundColor, float roughness, float NdotV, vec3 reflectance0, vec3 reflectance90, out float NdotL) {
    lightingInfo result;
    NdotL = dot(vNormal, lightData.xyz)*0.5+0.5;
    result.diffuse = mix(groundColor, diffuseColor, NdotL);
    #ifdef SPECULARTERM
        
        vec3 lightVectorW = normalize(lightData.xyz);
        vec3 H = normalize(viewDirectionW+lightVectorW);
        float NdotH = clamp(dot(vNormal, H), 0.000000000001, 1.0);
        NdotL = clamp(NdotL, 0.000000000001, 1.0);
        float VdotH = clamp(dot(viewDirectionW, H), 0.0, 1.0);
        vec3 specTerm = computeSpecularTerm(NdotH, NdotL, NdotV, VdotH, roughness, reflectance0, reflectance90);
        result.specular = specTerm*diffuseColor;
    #endif
    return result;
}
#ifdef BUMP
    #if BUMPDIRECTUV == 1
        #define vBumpUV vMainUV1
        #elif BUMPDIRECTUV == 2
        #define vBumpUV vMainUV2
    #else
        varying vec2 vBumpUV;
    #endif
    uniform sampler2D bumpSampler;
    #if defined(TANGENT) && defined(NORMAL) 
        varying mat3 vTBN;
    #endif
    
    mat3 cotangent_frame(vec3 normal, vec3 p, vec2 uv) {
        uv = gl_FrontFacing ? uv : -uv;
        vec3 dp1 = dFdx(p);
        vec3 dp2 = dFdy(p);
        vec2 duv1 = dFdx(uv);
        vec2 duv2 = dFdy(uv);
        vec3 dp2perp = cross(dp2, normal);
        vec3 dp1perp = cross(normal, dp1);
        vec3 tangent = dp2perp*duv1.x+dp1perp*duv2.x;
        vec3 binormal = dp2perp*duv1.y+dp1perp*duv2.y;
        #ifdef USERIGHTHANDEDSYSTEM
            binormal = -binormal;
        #endif
        
        float invmax = inversesqrt(max(dot(tangent, tangent), dot(binormal, binormal)));
        return mat3(tangent*invmax, binormal*invmax, normal);
    }
    vec3 perturbNormal(mat3 cotangentFrame, vec2 uv) {
        vec3 map = texture2D(bumpSampler, uv).xyz;
        map.x = vNormalReoderParams.x+vNormalReoderParams.y*map.x;
        map.y = vNormalReoderParams.z+vNormalReoderParams.w*map.y;
        map = map*255./127.-128./127.;
        #ifdef NORMALXYSCALE
            map = normalize(map*vec3(vBumpInfos.y, vBumpInfos.y, 1.0));
        #endif
        return normalize(cotangentFrame*map);
    }
    #ifdef PARALLAX
        const float minSamples = 4.;
        const float maxSamples = 15.;
        const int iMaxSamples = 15;
        vec2 parallaxOcclusion(vec3 vViewDirCoT, vec3 vNormalCoT, vec2 texCoord, float parallaxScale) {
            float parallaxLimit = length(vViewDirCoT.xy)/vViewDirCoT.z;
            parallaxLimit *= parallaxScale;
            vec2 vOffsetDir = normalize(vViewDirCoT.xy);
            vec2 vMaxOffset = vOffsetDir*parallaxLimit;
            float numSamples = maxSamples+(dot(vViewDirCoT, vNormalCoT)*(minSamples-maxSamples));
            float stepSize = 1.0/numSamples;
            float currRayHeight = 1.0;
            vec2 vCurrOffset = vec2(0, 0);
            vec2 vLastOffset = vec2(0, 0);
            float lastSampledHeight = 1.0;
            float currSampledHeight = 1.0;
            for (int i = 0; i<iMaxSamples; i++) {
                currSampledHeight = texture2D(bumpSampler, vBumpUV+vCurrOffset).w;
                if (currSampledHeight>currRayHeight) {
                    float delta1 = currSampledHeight-currRayHeight;
                    float delta2 = (currRayHeight+stepSize)-lastSampledHeight;
                    float ratio = delta1/(delta1+delta2);
                    vCurrOffset = (ratio)* vLastOffset+(1.0-ratio)*vCurrOffset;
                    break;
                }
                else {
                    currRayHeight -= stepSize;
                    vLastOffset = vCurrOffset;
                    vCurrOffset += stepSize*vMaxOffset;
                    lastSampledHeight = currSampledHeight;
                }
        
            }
            return vCurrOffset;
        }
        vec2 parallaxOffset(vec3 viewDir, float heightScale) {
            float height = texture2D(bumpSampler, vBumpUV).w;
            vec2 texCoordOffset = heightScale*viewDir.xy*height;
            return -texCoordOffset;
        }
    #endif
#endif
#ifdef CLIPPLANE
    varying float fClipDistance;
#endif
#ifdef LOGARITHMICDEPTH
    uniform float logarithmicDepthConstant;
    varying float vFragmentDepth;
#endif

#ifdef FOG
    #define FOGMODE_NONE 0.
    #define FOGMODE_EXP 1.
    #define FOGMODE_EXP2 2.
    #define FOGMODE_LINEAR 3.
    #define E 2.71828
    uniform vec4 vFogInfos;
    uniform vec3 vFogColor;
    varying vec3 vFogDistance;
    float CalcFogFactor() {
        float fogCoeff = 1.0;
        float fogStart = vFogInfos.y;
        float fogEnd = vFogInfos.z;
        float fogDensity = vFogInfos.w;
        float fogDistance = length(vFogDistance);
        if (FOGMODE_LINEAR == vFogInfos.x) {
            fogCoeff = (fogEnd-fogDistance)/(fogEnd-fogStart);
        }
        else if (FOGMODE_EXP == vFogInfos.x) {
            fogCoeff = 1.0/pow(E, fogDistance*fogDensity);
        }
        else if (FOGMODE_EXP2 == vFogInfos.x) {
            fogCoeff = 1.0/pow(E, fogDistance*fogDistance*fogDensity*fogDensity);
        }
        return clamp(fogCoeff, 0.0, 1.0);
    }
#endif
void main(void) {
    #ifdef CLIPPLANE
        if (fClipDistance>0.0) {
            discard;
        }
    #endif
    
    
    vec3 viewDirectionW = normalize(vEyePosition.xyz-vPositionW);
    #ifdef NORMAL
        vec3 normalW = normalize(vNormalW);
    #else
        vec3 normalW = normalize(cross(dFdx(vPositionW), dFdy(vPositionW)))*vEyePosition.w;
    #endif
    vec2 uvOffset = vec2(0.0, 0.0);
    #if defined(BUMP) || defined(PARALLAX)
        #ifdef NORMALXYSCALE
            float normalScale = 1.0;
        #else 
            float normalScale = vBumpInfos.y;
        #endif
        #if defined(TANGENT) && defined(NORMAL)
            mat3 TBN = vTBN;
        #else
            mat3 TBN = cotangent_frame(normalW*normalScale, vPositionW, vBumpUV);
        #endif
    #endif
    #ifdef PARALLAX
        mat3 invTBN = transposeMat3(TBN);
        #ifdef PARALLAXOCCLUSION
            uvOffset = parallaxOcclusion(invTBN*-viewDirectionW, invTBN*normalW, vBumpUV, vBumpInfos.z);
        #else
            uvOffset = parallaxOffset(invTBN*viewDirectionW, vBumpInfos.z);
        #endif
    #endif
    #ifdef BUMP
        normalW = perturbNormal(TBN, vBumpUV+uvOffset);
    #endif
    #if defined(FORCENORMALFORWARD) && defined(NORMAL)
        vec3 faceNormal = normalize(cross(dFdx(vPositionW), dFdy(vPositionW)))*vEyePosition.w;
        #if defined(TWOSIDEDLIGHTING)
            faceNormal = gl_FrontFacing ? faceNormal : -faceNormal;
        #endif
        float comp = sign(dot(normalW, faceNormal));
        normalW *= -comp;
    #endif
    #if defined(TWOSIDEDLIGHTING) && defined(NORMAL)
        normalW = gl_FrontFacing ? normalW : -normalW;
    #endif
    
    
    vec3 surfaceAlbedo = vAlbedoColor.rgb;
    float alpha = vAlbedoColor.a;
    #ifdef ALBEDO
        vec4 albedoTexture = texture2D(albedoSampler, vAlbedoUV+uvOffset);
        #if defined(ALPHAFROMALBEDO) || defined(ALPHATEST)
            alpha *= albedoTexture.a;
        #endif
        surfaceAlbedo *= toLinearSpace(albedoTexture.rgb);
        surfaceAlbedo *= vAlbedoInfos.y;
    #endif
    
    #ifdef OPACITY
        vec4 opacityMap = texture2D(opacitySampler, vOpacityUV+uvOffset);
        #ifdef OPACITYRGB
            alpha = getLuminance(opacityMap.rgb);
        #else
            alpha *= opacityMap.a;
        #endif
        alpha *= vOpacityInfos.y;
    #endif
    #ifdef VERTEXALPHA
        alpha *= vColor.a;
    #endif
    #if !defined(LINKREFRACTIONTOTRANSPARENCY) && !defined(ALPHAFRESNEL)
        #ifdef ALPHATEST
            if (alpha <= ALPHATESTVALUE)
            discard;
            #ifndef ALPHABLEND
                
                alpha = 1.0;
            #endif
        #endif
    #endif
    #ifdef VERTEXCOLOR
        surfaceAlbedo *= vColor.rgb;
    #endif
    
    vec3 ambientOcclusionColor = vec3(1., 1., 1.);
    #ifdef AMBIENT
        vec3 ambientOcclusionColorMap = texture2D(ambientSampler, vAmbientUV+uvOffset).rgb*vAmbientInfos.y;
        #ifdef AMBIENTINGRAYSCALE
            ambientOcclusionColorMap = vec3(ambientOcclusionColorMap.r, ambientOcclusionColorMap.r, ambientOcclusionColorMap.r);
        #endif
        ambientOcclusionColor = mix(ambientOcclusionColor, ambientOcclusionColorMap, vAmbientInfos.z);
    #endif
    
    float microSurface = vReflectivityColor.a;
    vec3 surfaceReflectivityColor = vReflectivityColor.rgb;
    #ifdef METALLICWORKFLOW
        vec2 metallicRoughness = surfaceReflectivityColor.rg;
        #ifdef REFLECTIVITY
            vec4 surfaceMetallicColorMap = texture2D(reflectivitySampler, vReflectivityUV+uvOffset);
            #ifdef AOSTOREINMETALMAPRED
                vec3 aoStoreInMetalMap = vec3(surfaceMetallicColorMap.r, surfaceMetallicColorMap.r, surfaceMetallicColorMap.r);
                ambientOcclusionColor = mix(ambientOcclusionColor, aoStoreInMetalMap, vReflectivityInfos.z);
            #endif
            #ifdef METALLNESSSTOREINMETALMAPBLUE
                metallicRoughness.r *= surfaceMetallicColorMap.b;
            #else
                metallicRoughness.r *= surfaceMetallicColorMap.r;
            #endif
            #ifdef ROUGHNESSSTOREINMETALMAPALPHA
                metallicRoughness.g *= surfaceMetallicColorMap.a;
            #else
                #ifdef ROUGHNESSSTOREINMETALMAPGREEN
                    metallicRoughness.g *= surfaceMetallicColorMap.g;
                #endif
            #endif
        #endif
        #ifdef MICROSURFACEMAP
            vec4 microSurfaceTexel = texture2D(microSurfaceSampler, vMicroSurfaceSamplerUV+uvOffset)*vMicroSurfaceSamplerInfos.y;
            metallicRoughness.g *= microSurfaceTexel.r;
        #endif
        
        microSurface = 1.0-metallicRoughness.g;
        vec3 baseColor = surfaceAlbedo;
        const vec3 DefaultSpecularReflectanceDielectric = vec3(0.04, 0.04, 0.04);
        surfaceAlbedo = mix(baseColor.rgb*(1.0-DefaultSpecularReflectanceDielectric.r), vec3(0., 0., 0.), metallicRoughness.r);
        surfaceReflectivityColor = mix(DefaultSpecularReflectanceDielectric, baseColor, metallicRoughness.r);
    #else
        #ifdef REFLECTIVITY
            vec4 surfaceReflectivityColorMap = texture2D(reflectivitySampler, vReflectivityUV+uvOffset);
            surfaceReflectivityColor *= toLinearSpace(surfaceReflectivityColorMap.rgb);
            surfaceReflectivityColor *= vReflectivityInfos.y;
            #ifdef MICROSURFACEFROMREFLECTIVITYMAP
                microSurface *= surfaceReflectivityColorMap.a;
                microSurface *= vReflectivityInfos.z;
            #else
                #ifdef MICROSURFACEAUTOMATIC
                    microSurface *= computeDefaultMicroSurface(microSurface, surfaceReflectivityColor);
                #endif
                #ifdef MICROSURFACEMAP
                    vec4 microSurfaceTexel = texture2D(microSurfaceSampler, vMicroSurfaceSamplerUV+uvOffset)*vMicroSurfaceSamplerInfos.y;
                    microSurface *= microSurfaceTexel.r;
                #endif
            #endif
        #endif
    #endif
    
    microSurface = clamp(microSurface, 0., 1.);
    float roughness = 1.-microSurface;
    #ifdef ALPHAFRESNEL
        #if defined(ALPHATEST) || defined(ALPHABLEND)
            
            
            
            float opacityPerceptual = alpha;
            float opacity0 = opacityPerceptual*opacityPerceptual;
            float opacity90 = fresnelGrazingReflectance(opacity0);
            vec3 normalForward = faceforward(normalW, -viewDirectionW, normalW);
            alpha = fresnelSchlickEnvironmentGGX(clamp(dot(viewDirectionW, normalForward), 0.0, 1.0), vec3(opacity0), vec3(opacity90), sqrt(microSurface)).x;
            #ifdef ALPHATEST
                if (alpha <= ALPHATESTVALUE)
                discard;
                #ifndef ALPHABLEND
                    
                    alpha = 1.0;
                #endif
            #endif
        #endif
    #endif
    
    
    float NdotVUnclamped = dot(normalW, viewDirectionW);
    float NdotV = clamp(NdotVUnclamped, 0., 1.)+0.00001;
    float alphaG = convertRoughnessToAverageSlope(roughness);
    #ifdef REFRACTION
        vec3 environmentRefraction = vec3(0., 0., 0.);
        vec3 refractionVector = refract(-viewDirectionW, normalW, vRefractionInfos.y);
        #ifdef REFRACTIONMAP_OPPOSITEZ
            refractionVector.z *= -1.0;
        #endif
        
        #ifdef REFRACTIONMAP_3D
            refractionVector.y = refractionVector.y*vRefractionInfos.w;
            vec3 refractionCoords = refractionVector;
            refractionCoords = vec3(refractionMatrix*vec4(refractionCoords, 0));
        #else
            vec3 vRefractionUVW = vec3(refractionMatrix*(view*vec4(vPositionW+refractionVector*vRefractionInfos.z, 1.0)));
            vec2 refractionCoords = vRefractionUVW.xy/vRefractionUVW.z;
            refractionCoords.y = 1.0-refractionCoords.y;
        #endif
        #ifdef LODINREFRACTIONALPHA
            float refractionLOD = getLodFromAlphaG(vRefractionMicrosurfaceInfos.x, alphaG, NdotVUnclamped);
        #else
            float refractionLOD = getLodFromAlphaG(vRefractionMicrosurfaceInfos.x, alphaG, 1.0);
        #endif
        #ifdef LODBASEDMICROSFURACE
            
            refractionLOD = refractionLOD*vRefractionMicrosurfaceInfos.y+vRefractionMicrosurfaceInfos.z;
            #ifdef LODINREFRACTIONALPHA
                
                
                
                
                
                
                
                
                
                float automaticRefractionLOD = UNPACK_LOD(sampleRefraction(refractionSampler, refractionCoords).a);
                float requestedRefractionLOD = max(automaticRefractionLOD, refractionLOD);
            #else
                float requestedRefractionLOD = refractionLOD;
            #endif
            environmentRefraction = sampleRefractionLod(refractionSampler, refractionCoords, requestedRefractionLOD).rgb;
        #else
            float lodRefractionNormalized = clamp(refractionLOD/log2(vRefractionMicrosurfaceInfos.x), 0., 1.);
            float lodRefractionNormalizedDoubled = lodRefractionNormalized*2.0;
            vec3 environmentRefractionMid = sampleRefraction(refractionSampler, refractionCoords).rgb;
            if(lodRefractionNormalizedDoubled<1.0) {
                environmentRefraction = mix(
                sampleRefraction(refractionSamplerHigh, refractionCoords).rgb, environmentRefractionMid, lodRefractionNormalizedDoubled
                );
            }
            else {
                environmentRefraction = mix(
                environmentRefractionMid, sampleRefraction(refractionSamplerLow, refractionCoords).rgb, lodRefractionNormalizedDoubled-1.0
                );
            }
        #endif
        #ifdef GAMMAREFRACTION
            environmentRefraction = toLinearSpace(environmentRefraction.rgb);
        #endif
        
        environmentRefraction *= vRefractionInfos.x;
    #endif
    
    #ifdef REFLECTION
        vec3 environmentRadiance = vec3(0., 0., 0.);
        vec3 environmentIrradiance = vec3(0., 0., 0.);
        vec3 reflectionVector = computeReflectionCoords(vec4(vPositionW, 1.0), normalW);
        #ifdef REFLECTIONMAP_OPPOSITEZ
            reflectionVector.z *= -1.0;
        #endif
        
        #ifdef REFLECTIONMAP_3D
            vec3 reflectionCoords = reflectionVector;
        #else
            vec2 reflectionCoords = reflectionVector.xy;
            #ifdef REFLECTIONMAP_PROJECTION
                reflectionCoords /= reflectionVector.z;
            #endif
            reflectionCoords.y = 1.0-reflectionCoords.y;
        #endif
        #if defined(LODINREFLECTIONALPHA) && !defined(REFLECTIONMAP_SKYBOX)
            float reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG, NdotVUnclamped);
        #else
            float reflectionLOD = getLodFromAlphaG(vReflectionMicrosurfaceInfos.x, alphaG, 1.);
        #endif
        #ifdef LODBASEDMICROSFURACE
            
            reflectionLOD = reflectionLOD*vReflectionMicrosurfaceInfos.y+vReflectionMicrosurfaceInfos.z;
            #ifdef LODINREFLECTIONALPHA
                
                
                
                
                
                
                
                
                
                float automaticReflectionLOD = UNPACK_LOD(sampleReflection(reflectionSampler, reflectionCoords).a);
                float requestedReflectionLOD = max(automaticReflectionLOD, reflectionLOD);
            #else
                float requestedReflectionLOD = reflectionLOD;
            #endif
            environmentRadiance = sampleReflectionLod(reflectionSampler, reflectionCoords, requestedReflectionLOD).rgb;
        #else
            float lodReflectionNormalized = clamp(reflectionLOD/log2(vReflectionMicrosurfaceInfos.x), 0., 1.);
            float lodReflectionNormalizedDoubled = lodReflectionNormalized*2.0;
            vec3 environmentSpecularMid = sampleReflection(reflectionSampler, reflectionCoords).rgb;
            if(lodReflectionNormalizedDoubled<1.0) {
                environmentRadiance = mix(
                sampleReflection(reflectionSamplerHigh, reflectionCoords).rgb, environmentSpecularMid, lodReflectionNormalizedDoubled
                );
            }
            else {
                environmentRadiance = mix(
                environmentSpecularMid, sampleReflection(reflectionSamplerLow, reflectionCoords).rgb, lodReflectionNormalizedDoubled-1.0
                );
            }
        #endif
        #ifdef GAMMAREFLECTION
            environmentRadiance = toLinearSpace(environmentRadiance.rgb);
        #endif
        
        #ifdef USESPHERICALFROMREFLECTIONMAP
            #if defined(NORMAL) && !defined(USESPHERICALINFRAGMENT)
                environmentIrradiance = vEnvironmentIrradiance;
            #else
                vec3 irradianceVector = vec3(reflectionMatrix*vec4(normalW, 0)).xyz;
                #ifdef REFLECTIONMAP_OPPOSITEZ
                    irradianceVector.z *= -1.0;
                #endif
                environmentIrradiance = environmentIrradianceJones(irradianceVector);
            #endif
        #endif
        
        environmentRadiance *= vReflectionInfos.x;
        environmentRadiance *= vReflectionColor.rgb;
        environmentIrradiance *= vReflectionColor.rgb;
    #endif
    
    
    
    float reflectance = max(max(surfaceReflectivityColor.r, surfaceReflectivityColor.g), surfaceReflectivityColor.b);
    float reflectance90 = fresnelGrazingReflectance(reflectance);
    vec3 specularEnvironmentR0 = surfaceReflectivityColor.rgb;
    vec3 specularEnvironmentR90 = vec3(1.0, 1.0, 1.0)*reflectance90;
    vec3 diffuseBase = vec3(0., 0., 0.);
    #ifdef SPECULARTERM
        vec3 specularBase = vec3(0., 0., 0.);
    #endif
    #ifdef LIGHTMAP
        vec3 lightmapColor = texture2D(lightmapSampler, vLightmapUV+uvOffset).rgb*vLightmapInfos.y;
    #endif
    lightingInfo info;
    float shadow = 1.;
    float NdotL = -1.;
    #ifdef LIGHT0
        #if defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED0) && defined(LIGHTMAPNOSPECULAR0)
            
        #else
            #ifdef PBR
                #ifdef SPOTLIGHT0
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData0, vLightDirection0, vLightDiffuse0.rgb, vLightSpecular0, vLightDiffuse0.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #ifdef HEMILIGHT0
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0, vLightGround0, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #if defined(POINTLIGHT0) || defined(DIRLIGHT0)
                    info = computeLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0, vLightDiffuse0.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
            #else
                #ifdef SPOTLIGHT0
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData0, vLightDirection0, vLightDiffuse0.rgb, vLightSpecular0, vLightDiffuse0.a, glossiness);
                #endif
                #ifdef HEMILIGHT0
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0, vLightGround0, glossiness);
                #endif
                #if defined(POINTLIGHT0) || defined(DIRLIGHT0)
                    info = computeLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0, vLightDiffuse0.a, glossiness);
                #endif
            #endif
        #endif
        #ifdef SHADOW0
            #ifdef SHADOWCLOSEESM0
                #if defined(SHADOWCUBE0)
                    shadow = computeShadowWithCloseESMCube(vLightData0.xyz, shadowSampler0, shadowsInfo0.x, shadowsInfo0.z, depthValues0);
                #else
                    shadow = computeShadowWithCloseESM(vPositionFromLight0, vDepthMetric0, shadowSampler0, shadowsInfo0.x, shadowsInfo0.z, shadowsInfo0.w);
                #endif
            #else
                #ifdef SHADOWESM0
                    #if defined(SHADOWCUBE0)
                        shadow = computeShadowWithESMCube(vLightData0.xyz, shadowSampler0, shadowsInfo0.x, shadowsInfo0.z, depthValues0);
                    #else
                        shadow = computeShadowWithESM(vPositionFromLight0, vDepthMetric0, shadowSampler0, shadowsInfo0.x, shadowsInfo0.z, shadowsInfo0.w);
                    #endif
                #else 
                    #ifdef SHADOWPCF0
                        #if defined(SHADOWCUBE0)
                            shadow = computeShadowWithPCFCube(vLightData0.xyz, shadowSampler0, shadowsInfo0.y, shadowsInfo0.x, depthValues0);
                        #else
                            shadow = computeShadowWithPCF(vPositionFromLight0, vDepthMetric0, shadowSampler0, shadowsInfo0.y, shadowsInfo0.x, shadowsInfo0.w);
                        #endif
                    #else
                        #if defined(SHADOWCUBE0)
                            shadow = computeShadowCube(vLightData0.xyz, shadowSampler0, shadowsInfo0.x, depthValues0);
                        #else
                            shadow = computeShadow(vPositionFromLight0, vDepthMetric0, shadowSampler0, shadowsInfo0.x, shadowsInfo0.w);
                        #endif
                    #endif
                #endif
            #endif
        #else
            shadow = 1.;
        #endif
        #ifdef CUSTOMUSERLIGHTING
            diffuseBase += computeCustomDiffuseLighting(info, diffuseBase, shadow);
            #ifdef SPECULARTERM
                specularBase += computeCustomSpecularLighting(info, specularBase, shadow);
            #endif
            #elif defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED0)
            diffuseBase += lightmapColor*shadow;
            #ifdef SPECULARTERM
                #ifndef LIGHTMAPNOSPECULAR0
                    specularBase += info.specular*shadow*lightmapColor;
                #endif
            #endif
        #else
            diffuseBase += info.diffuse*shadow;
            #ifdef SPECULARTERM
                specularBase += info.specular*shadow;
            #endif
        #endif
    #endif
    #ifdef LIGHT1
        #if defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED1) && defined(LIGHTMAPNOSPECULAR1)
            
        #else
            #ifdef PBR
                #ifdef SPOTLIGHT1
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData1, vLightDirection1, vLightDiffuse1.rgb, vLightSpecular1, vLightDiffuse1.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #ifdef HEMILIGHT1
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1.rgb, vLightSpecular1, vLightGround1, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #if defined(POINTLIGHT1) || defined(DIRLIGHT1)
                    info = computeLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1.rgb, vLightSpecular1, vLightDiffuse1.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
            #else
                #ifdef SPOTLIGHT1
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData1, vLightDirection1, vLightDiffuse1.rgb, vLightSpecular1, vLightDiffuse1.a, glossiness);
                #endif
                #ifdef HEMILIGHT1
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1.rgb, vLightSpecular1, vLightGround1, glossiness);
                #endif
                #if defined(POINTLIGHT1) || defined(DIRLIGHT1)
                    info = computeLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1.rgb, vLightSpecular1, vLightDiffuse1.a, glossiness);
                #endif
            #endif
        #endif
        #ifdef SHADOW1
            #ifdef SHADOWCLOSEESM1
                #if defined(SHADOWCUBE1)
                    shadow = computeShadowWithCloseESMCube(vLightData1.xyz, shadowSampler1, shadowsInfo1.x, shadowsInfo1.z, depthValues1);
                #else
                    shadow = computeShadowWithCloseESM(vPositionFromLight1, vDepthMetric1, shadowSampler1, shadowsInfo1.x, shadowsInfo1.z, shadowsInfo1.w);
                #endif
            #else
                #ifdef SHADOWESM1
                    #if defined(SHADOWCUBE1)
                        shadow = computeShadowWithESMCube(vLightData1.xyz, shadowSampler1, shadowsInfo1.x, shadowsInfo1.z, depthValues1);
                    #else
                        shadow = computeShadowWithESM(vPositionFromLight1, vDepthMetric1, shadowSampler1, shadowsInfo1.x, shadowsInfo1.z, shadowsInfo1.w);
                    #endif
                #else 
                    #ifdef SHADOWPCF1
                        #if defined(SHADOWCUBE1)
                            shadow = computeShadowWithPCFCube(vLightData1.xyz, shadowSampler1, shadowsInfo1.y, shadowsInfo1.x, depthValues1);
                        #else
                            shadow = computeShadowWithPCF(vPositionFromLight1, vDepthMetric1, shadowSampler1, shadowsInfo1.y, shadowsInfo1.x, shadowsInfo1.w);
                        #endif
                    #else
                        #if defined(SHADOWCUBE1)
                            shadow = computeShadowCube(vLightData1.xyz, shadowSampler1, shadowsInfo1.x, depthValues1);
                        #else
                            shadow = computeShadow(vPositionFromLight1, vDepthMetric1, shadowSampler1, shadowsInfo1.x, shadowsInfo1.w);
                        #endif
                    #endif
                #endif
            #endif
        #else
            shadow = 1.;
        #endif
        #ifdef CUSTOMUSERLIGHTING
            diffuseBase += computeCustomDiffuseLighting(info, diffuseBase, shadow);
            #ifdef SPECULARTERM
                specularBase += computeCustomSpecularLighting(info, specularBase, shadow);
            #endif
            #elif defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED1)
            diffuseBase += lightmapColor*shadow;
            #ifdef SPECULARTERM
                #ifndef LIGHTMAPNOSPECULAR1
                    specularBase += info.specular*shadow*lightmapColor;
                #endif
            #endif
        #else
            diffuseBase += info.diffuse*shadow;
            #ifdef SPECULARTERM
                specularBase += info.specular*shadow;
            #endif
        #endif
    #endif
    #ifdef LIGHT2
        #if defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED2) && defined(LIGHTMAPNOSPECULAR2)
            
        #else
            #ifdef PBR
                #ifdef SPOTLIGHT2
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData2, vLightDirection2, vLightDiffuse2.rgb, vLightSpecular2, vLightDiffuse2.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #ifdef HEMILIGHT2
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2.rgb, vLightSpecular2, vLightGround2, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #if defined(POINTLIGHT2) || defined(DIRLIGHT2)
                    info = computeLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2.rgb, vLightSpecular2, vLightDiffuse2.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
            #else
                #ifdef SPOTLIGHT2
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData2, vLightDirection2, vLightDiffuse2.rgb, vLightSpecular2, vLightDiffuse2.a, glossiness);
                #endif
                #ifdef HEMILIGHT2
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2.rgb, vLightSpecular2, vLightGround2, glossiness);
                #endif
                #if defined(POINTLIGHT2) || defined(DIRLIGHT2)
                    info = computeLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2.rgb, vLightSpecular2, vLightDiffuse2.a, glossiness);
                #endif
            #endif
        #endif
        #ifdef SHADOW2
            #ifdef SHADOWCLOSEESM2
                #if defined(SHADOWCUBE2)
                    shadow = computeShadowWithCloseESMCube(vLightData2.xyz, shadowSampler2, shadowsInfo2.x, shadowsInfo2.z, depthValues2);
                #else
                    shadow = computeShadowWithCloseESM(vPositionFromLight2, vDepthMetric2, shadowSampler2, shadowsInfo2.x, shadowsInfo2.z, shadowsInfo2.w);
                #endif
            #else
                #ifdef SHADOWESM2
                    #if defined(SHADOWCUBE2)
                        shadow = computeShadowWithESMCube(vLightData2.xyz, shadowSampler2, shadowsInfo2.x, shadowsInfo2.z, depthValues2);
                    #else
                        shadow = computeShadowWithESM(vPositionFromLight2, vDepthMetric2, shadowSampler2, shadowsInfo2.x, shadowsInfo2.z, shadowsInfo2.w);
                    #endif
                #else 
                    #ifdef SHADOWPCF2
                        #if defined(SHADOWCUBE2)
                            shadow = computeShadowWithPCFCube(vLightData2.xyz, shadowSampler2, shadowsInfo2.y, shadowsInfo2.x, depthValues2);
                        #else
                            shadow = computeShadowWithPCF(vPositionFromLight2, vDepthMetric2, shadowSampler2, shadowsInfo2.y, shadowsInfo2.x, shadowsInfo2.w);
                        #endif
                    #else
                        #if defined(SHADOWCUBE2)
                            shadow = computeShadowCube(vLightData2.xyz, shadowSampler2, shadowsInfo2.x, depthValues2);
                        #else
                            shadow = computeShadow(vPositionFromLight2, vDepthMetric2, shadowSampler2, shadowsInfo2.x, shadowsInfo2.w);
                        #endif
                    #endif
                #endif
            #endif
        #else
            shadow = 1.;
        #endif
        #ifdef CUSTOMUSERLIGHTING
            diffuseBase += computeCustomDiffuseLighting(info, diffuseBase, shadow);
            #ifdef SPECULARTERM
                specularBase += computeCustomSpecularLighting(info, specularBase, shadow);
            #endif
            #elif defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED2)
            diffuseBase += lightmapColor*shadow;
            #ifdef SPECULARTERM
                #ifndef LIGHTMAPNOSPECULAR2
                    specularBase += info.specular*shadow*lightmapColor;
                #endif
            #endif
        #else
            diffuseBase += info.diffuse*shadow;
            #ifdef SPECULARTERM
                specularBase += info.specular*shadow;
            #endif
        #endif
    #endif
    #ifdef LIGHT3
        #if defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED3) && defined(LIGHTMAPNOSPECULAR3)
            
        #else
            #ifdef PBR
                #ifdef SPOTLIGHT3
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData3, vLightDirection3, vLightDiffuse3.rgb, vLightSpecular3, vLightDiffuse3.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #ifdef HEMILIGHT3
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3.rgb, vLightSpecular3, vLightGround3, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
                #if defined(POINTLIGHT3) || defined(DIRLIGHT3)
                    info = computeLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3.rgb, vLightSpecular3, vLightDiffuse3.a, roughness, NdotV, specularEnvironmentR0, specularEnvironmentR90, NdotL);
                #endif
            #else
                #ifdef SPOTLIGHT3
                    info = computeSpotLighting(viewDirectionW, normalW, vLightData3, vLightDirection3, vLightDiffuse3.rgb, vLightSpecular3, vLightDiffuse3.a, glossiness);
                #endif
                #ifdef HEMILIGHT3
                    info = computeHemisphericLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3.rgb, vLightSpecular3, vLightGround3, glossiness);
                #endif
                #if defined(POINTLIGHT3) || defined(DIRLIGHT3)
                    info = computeLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3.rgb, vLightSpecular3, vLightDiffuse3.a, glossiness);
                #endif
            #endif
        #endif
        #ifdef SHADOW3
            #ifdef SHADOWCLOSEESM3
                #if defined(SHADOWCUBE3)
                    shadow = computeShadowWithCloseESMCube(vLightData3.xyz, shadowSampler3, shadowsInfo3.x, shadowsInfo3.z, depthValues3);
                #else
                    shadow = computeShadowWithCloseESM(vPositionFromLight3, vDepthMetric3, shadowSampler3, shadowsInfo3.x, shadowsInfo3.z, shadowsInfo3.w);
                #endif
            #else
                #ifdef SHADOWESM3
                    #if defined(SHADOWCUBE3)
                        shadow = computeShadowWithESMCube(vLightData3.xyz, shadowSampler3, shadowsInfo3.x, shadowsInfo3.z, depthValues3);
                    #else
                        shadow = computeShadowWithESM(vPositionFromLight3, vDepthMetric3, shadowSampler3, shadowsInfo3.x, shadowsInfo3.z, shadowsInfo3.w);
                    #endif
                #else 
                    #ifdef SHADOWPCF3
                        #if defined(SHADOWCUBE3)
                            shadow = computeShadowWithPCFCube(vLightData3.xyz, shadowSampler3, shadowsInfo3.y, shadowsInfo3.x, depthValues3);
                        #else
                            shadow = computeShadowWithPCF(vPositionFromLight3, vDepthMetric3, shadowSampler3, shadowsInfo3.y, shadowsInfo3.x, shadowsInfo3.w);
                        #endif
                    #else
                        #if defined(SHADOWCUBE3)
                            shadow = computeShadowCube(vLightData3.xyz, shadowSampler3, shadowsInfo3.x, depthValues3);
                        #else
                            shadow = computeShadow(vPositionFromLight3, vDepthMetric3, shadowSampler3, shadowsInfo3.x, shadowsInfo3.w);
                        #endif
                    #endif
                #endif
            #endif
        #else
            shadow = 1.;
        #endif
        #ifdef CUSTOMUSERLIGHTING
            diffuseBase += computeCustomDiffuseLighting(info, diffuseBase, shadow);
            #ifdef SPECULARTERM
                specularBase += computeCustomSpecularLighting(info, specularBase, shadow);
            #endif
            #elif defined(LIGHTMAP) && defined(LIGHTMAPEXCLUDED3)
            diffuseBase += lightmapColor*shadow;
            #ifdef SPECULARTERM
                #ifndef LIGHTMAPNOSPECULAR3
                    specularBase += info.specular*shadow*lightmapColor;
                #endif
            #endif
        #else
            diffuseBase += info.diffuse*shadow;
            #ifdef SPECULARTERM
                specularBase += info.specular*shadow;
            #endif
        #endif
    #endif
    
    
    #if defined(ENVIRONMENTBRDF) && !defined(REFLECTIONMAP_SKYBOX)
        
        vec2 brdfSamplerUV = vec2(NdotV, roughness);
        vec4 environmentBrdf = texture2D(environmentBrdfSampler, brdfSamplerUV);
        vec3 specularEnvironmentReflectance = specularEnvironmentR0*environmentBrdf.x+environmentBrdf.y;
        #ifdef AMBIENTINGRAYSCALE
            float ambientMonochrome = ambientOcclusionColor.r;
        #else
            float ambientMonochrome = getLuminance(ambientOcclusionColor);
        #endif
        float seo = environmentRadianceOcclusion(ambientMonochrome, NdotVUnclamped);
        specularEnvironmentReflectance *= seo;
        #ifdef BUMP
            #ifdef REFLECTIONMAP_3D
                float eho = environmentHorizonOcclusion(reflectionCoords, normalW);
                specularEnvironmentReflectance *= eho;
            #endif
        #endif
    #else
        
        vec3 specularEnvironmentReflectance = fresnelSchlickEnvironmentGGX(NdotV, specularEnvironmentR0, specularEnvironmentR90, sqrt(microSurface));
    #endif
    
    #ifdef REFRACTION
        vec3 refractance = vec3(0.0, 0.0, 0.0);
        vec3 transmission = vec3(1.0, 1.0, 1.0);
        #ifdef LINKREFRACTIONTOTRANSPARENCY
            
            transmission *= (1.0-alpha);
            vec3 mixedAlbedo = surfaceAlbedo;
            float maxChannel = max(max(mixedAlbedo.r, mixedAlbedo.g), mixedAlbedo.b);
            vec3 tint = clamp(maxChannel*mixedAlbedo, 0.0, 1.0);
            surfaceAlbedo *= alpha;
            environmentIrradiance *= alpha;
            environmentRefraction *= tint;
            alpha = 1.0;
        #endif
        
        vec3 bounceSpecularEnvironmentReflectance = (2.0*specularEnvironmentReflectance)/(1.0+specularEnvironmentReflectance);
        specularEnvironmentReflectance = mix(bounceSpecularEnvironmentReflectance, specularEnvironmentReflectance, alpha);
        transmission *= 1.0-specularEnvironmentReflectance;
        refractance = transmission;
    #endif
    
    
    
    
    surfaceAlbedo.rgb = (1.-reflectance)*surfaceAlbedo.rgb;
    vec3 finalDiffuse = diffuseBase;
    finalDiffuse.rgb += vAmbientColor;
    finalDiffuse *= surfaceAlbedo.rgb;
    finalDiffuse = max(finalDiffuse, 0.0);
    #ifdef REFLECTION
        vec3 finalIrradiance = environmentIrradiance;
        finalIrradiance *= surfaceAlbedo.rgb;
    #endif
    
    #ifdef SPECULARTERM
        vec3 finalSpecular = specularBase;
        finalSpecular = max(finalSpecular, 0.0);
        vec3 finalSpecularScaled = finalSpecular*vLightingIntensity.x*vLightingIntensity.w;
    #endif
    
    #ifdef REFLECTION
        vec3 finalRadiance = environmentRadiance;
        finalRadiance *= specularEnvironmentReflectance;
        vec3 finalRadianceScaled = finalRadiance*vLightingIntensity.z;
    #endif
    
    #ifdef REFRACTION
        vec3 finalRefraction = environmentRefraction;
        finalRefraction *= refractance;
    #endif
    
    vec3 finalEmissive = vEmissiveColor;
    #ifdef EMISSIVE
        vec3 emissiveColorTex = texture2D(emissiveSampler, vEmissiveUV+uvOffset).rgb;
        finalEmissive *= toLinearSpace(emissiveColorTex.rgb);
        finalEmissive *= vEmissiveInfos.y;
    #endif
    
    #ifdef ALPHABLEND
        float luminanceOverAlpha = 0.0;
        #if defined(REFLECTION) && defined(RADIANCEOVERALPHA)
            luminanceOverAlpha += getLuminance(finalRadianceScaled);
        #endif
        #if defined(SPECULARTERM) && defined(SPECULAROVERALPHA)
            luminanceOverAlpha += getLuminance(finalSpecularScaled);
        #endif
        #if defined(RADIANCEOVERALPHA) || defined(SPECULAROVERALPHA)
            alpha = clamp(alpha+luminanceOverAlpha*luminanceOverAlpha, 0., 1.);
        #endif
    #endif
    
    
    
    vec4 finalColor = vec4(finalDiffuse*ambientOcclusionColor*vLightingIntensity.x +
    #ifdef REFLECTION
        finalIrradiance*ambientOcclusionColor*vLightingIntensity.z +
    #endif
    #ifdef SPECULARTERM
        
        
        finalSpecularScaled +
    #endif
    #ifdef REFLECTION
        
        
        finalRadianceScaled +
    #endif
    #ifdef REFRACTION
        finalRefraction*vLightingIntensity.z +
    #endif
    finalEmissive*vLightingIntensity.y, alpha);
    #ifdef LIGHTMAP
        #ifndef LIGHTMAPEXCLUDED
            #ifdef USELIGHTMAPASSHADOWMAP
                finalColor.rgb *= lightmapColor;
            #else
                finalColor.rgb += lightmapColor;
            #endif
        #endif
    #endif
    
    finalColor = max(finalColor, 0.0);
    #ifdef LOGARITHMICDEPTH
        gl_FragDepthEXT = log2(vFragmentDepth)*logarithmicDepthConstant*0.5;
    #endif
    #ifdef FOG
        float fog = CalcFogFactor();
        finalColor.rgb = fog*finalColor.rgb+(1.0-fog)*vFogColor;
    #endif
    #ifdef IMAGEPROCESSINGPOSTPROCESS
        
        
        finalColor.rgb = clamp(finalColor.rgb, 0., 30.0);
    #else
        
        finalColor = applyImageProcessing(finalColor);
    #endif
    #ifdef PREMULTIPLYALPHA
        
        finalColor.rgb *= finalColor.a;
    #endif
    gl_FragColor = finalColor;
}
