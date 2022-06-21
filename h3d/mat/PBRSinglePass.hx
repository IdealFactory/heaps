package h3d.mat;


class PBRSinglePass extends Material {

	public var pbrshader : h3d.shader.PBRSinglePass;
	public var baseColor : h3d.shader.pbrsinglepass.BaseColor;
	public var baseColorUV : h3d.shader.pbrsinglepass.BaseColorUV;
	// public var normal : h3d.shader.pbrsinglepass.Normal;
	public var normalMapping : h3d.shader.pbrsinglepass.NormalMap;
	public var tangent : h3d.shader.pbrsinglepass.Tangent;
	public var uv1 : h3d.shader.pbrsinglepass.UV1;
	public var surface : h3d.shader.pbrsinglepass.Surface;
	public var surfaceMap : h3d.shader.pbrsinglepass.SurfaceMap;
	public var irradiance : h3d.shader.pbrsinglepass.Irradiance;
    public var irradianceMap : h3d.shader.pbrsinglepass.IrradianceMap;
    public var envLighting : h3d.shader.pbrsinglepass.EnvLighting;
	public var ambientMonochrome : h3d.shader.pbrsinglepass.AmbientMonochrome;
	public var ambientMonochromeLum : h3d.shader.pbrsinglepass.AmbientMonochromeLum;
	public var specEnvReflect : h3d.shader.pbrsinglepass.SpecEnvReflect;
    public var specEnvReflectMap : h3d.shader.pbrsinglepass.SpecEnvReflectMap;
    public var sheen : h3d.shader.pbrsinglepass.Sheen;
    public var clearCoat : h3d.shader.pbrsinglepass.Clearcoat;
	public var finalCombination : h3d.shader.pbrsinglepass.FinalCombination;
	public var emissive : h3d.shader.pbrsinglepass.Emissive;
	public var emissiveMap : h3d.shader.pbrsinglepass.EmissiveMap;
	public var ambientOcclusion : h3d.shader.pbrsinglepass.AmbientOcclusion;
	public var ambientOcclusionMap : h3d.shader.pbrsinglepass.AmbientOcclusionMap;
    public var output : h3d.shader.pbrsinglepass.Output;
    public var debug : h3d.shader.pbrsinglepass.Debug;
    public var colorTransform : h3d.shader.ColorTransform;

    public var hasTangentBuffer(default, set):Bool;

    public var metalnessFactor(default, set):Float;
    public var roughnessFactor(default, set):Float;
    public var sheenColor(default, set):Array<Float>;
    public var sheenIntensity(default, set):Float;
    public var sheenRoughness(default, set):Float;
    public var clearCoatIntensity(default, set):Float;
    public var clearCoatRoughness(default, set):Float;
    public var clearCoatIndexOfRefraction(default, set):Float;

    private var baseMeshOffset:Int = 1;

    public function new() {

		super();

        pbrshader = new h3d.shader.PBRSinglePass();
        envLighting = new h3d.shader.pbrsinglepass.EnvLighting();
        finalCombination = new h3d.shader.pbrsinglepass.FinalCombination();
        output = new h3d.shader.pbrsinglepass.Output();
        debug = new h3d.shader.pbrsinglepass.Debug();
        colorTransform = new h3d.shader.ColorTransform();
         
        var bm = mainPass.getShader( h3d.shader.BaseMesh );
        if (bm != null) {
            mainPass.removeShader( bm );
            baseMeshOffset = 0;
        }

        clearCoatIndexOfRefraction = 1.5;

        mainPass.addShaderAtIndex(pbrshader, baseMeshOffset);
        baseMeshOffset--;
        addBaseColor();
        addSurface();
        addAmbientOcculsion();
        addIrradiance();
        mainPass.addShaderAtIndex(envLighting, 8 + baseMeshOffset);
        addAmbientMonochrome();
        addSpecEnvReflect();
        addSheen([1, 1, 1], 0, 0);
        addClearCoat( 0, 0 );
        addEmissive();
        mainPass.addShaderAtIndex(finalCombination, mainPass.shaders.count);
        mainPass.addShaderAtIndex(debug, mainPass.shaders.count);
        mainPass.addShaderAtIndex(output, mainPass.shaders.count);
        mainPass.addShaderAtIndex(colorTransform, mainPass.shaders.count);
        dumpShaders("Shaders after init");
    }

    function dumpShaders(hdr:String){
        trace(hdr+":");
        for (s in mainPass.getShaders())
            trace(" s="+s);
    }

	public var reflectivityMap(get, set) : h3d.mat.Texture;
	public var emissiveLightMap(get, set) : h3d.mat.Texture;
	public var occlusionMap(get, set) : h3d.mat.Texture;

    override function get_texture() {
        if( uv1 == null ) return null;
        // if( pbrshader == null ) return null;
		return uv1.albedoSampler;
	}

	override function set_texture(t) {
        if( t != null && uv1 == null ) addUV1();
        if( uv1 == null ) return null;
        uv1.albedoSampler = t;
        // if (pbrshader==null) return null;
        // pbrshader.albedoSampler = t;
		return t;
	}

    override function get_normalMap() {
        if( normalMapping != null ) return normalMapping.bumpSampler;
        if( tangent != null ) return tangent.bumpSampler;
        return null;
	}

	override function set_normalMap(t) {
        if( t != null) {
            trace("NORMALMAP: Setting: hasTangentBuffer="+this.hasTangentBuffer);
            if (this.hasTangentBuffer) {
                if (tangent==null) addTangent();
                tangent.bumpSampler = t;
            } else {
                if (normalMapping==null) addNormalMap();
                normalMapping.bumpSampler = t;
            }
        }
		return t;
    }
    
    function set_hasTangentBuffer( val:Bool ):Bool {
        this.hasTangentBuffer = val;
        if (val) {
            if (tangent==null) addTangent();
        }
        return val;
    }


    function set_metalnessFactor( val:Float ):Float {
        this.metalnessFactor = val;
        if (surface!=null) {
            surface.uReflectivityColor.x = val;
        };
        if (surfaceMap!=null) {
            surfaceMap.uReflectivityColor.x = val;
        };
        return val;
    }

    function set_roughnessFactor( val:Float ):Float {
        this.roughnessFactor = val;
        if (surface!=null) {
            surface.uReflectivityColor.y = val;
        };
        if (surfaceMap!=null) {
            surfaceMap.uReflectivityColor.y = val;
        };
        return val;
    }

    function set_clearCoatIntensity( val:Float ):Float {
        this.clearCoatIntensity = val;
        if (clearCoat!=null) {
            clearCoat.vClearCoatParams.x = val;
        };
       return val;
    }

    function set_clearCoatRoughness( val:Float ):Float {
        this.clearCoatRoughness = val;
        if (clearCoat!=null) {
            clearCoat.vClearCoatParams.y = val;
        };
        return val;
    }

    function set_clearCoatIndexOfRefraction( val:Float ):Float {
        this.clearCoatIndexOfRefraction = val;
        if (clearCoat!=null) {
            var a = 1 - clearCoatIndexOfRefraction;
            var b = 1 + clearCoatIndexOfRefraction;
            var f0 = Math.pow((-a / b), 2); // Schlicks approx: (ior1 - ior2) / (ior1 + ior2) where ior2 for air is close to vacuum = 1.
            var eta = 1 / clearCoatIndexOfRefraction;
            clearCoat.vClearCoatRefractionParams.set(f0, eta, a, b);
            trace("CC.RefractionParams:"+clearCoat.vClearCoatRefractionParams);
        };
        return val;
    }

    function set_sheenColor( val:Array<Float> ):Array<Float> {
        this.sheenColor = val;
        if (sheen!=null) {
            sheen.vSheenColor.r = val[0];
            sheen.vSheenColor.g = val[1];
            sheen.vSheenColor.b = val[2];
        };
       return val;
    }

    function set_sheenIntensity( val:Float ):Float {
        this.sheenIntensity = val;
        if (sheen!=null) {
            sheen.vSheenColor.a = val;
        };
       return val;
    }

    function set_sheenRoughness( val:Float ):Float {
        this.sheenRoughness = val;
        if (sheen!=null) {
            sheen.vSheenRoughness = val;
        };
        return val;
    }

    function get_reflectivityMap() {
        if( surfaceMap == null ) return null;
        return surfaceMap.reflectivitySampler;
	}

	function set_reflectivityMap(t) {
        if( t != null && surfaceMap == null ) addSurfaceMap();
        if( surfaceMap == null ) return null;
        surfaceMap.reflectivitySampler = t;
		return t;
	}

    function get_emissiveLightMap() {
		if( emissiveMap == null ) return null;
        return emissiveMap.emissiveSampler;
	}

	function set_emissiveLightMap(t) {
        if( t != null && emissiveMap == null ) addEmissiveMap();
        if( emissiveMap == null ) return null;
        emissiveMap.emissiveSampler = t;
		return t;
	}

    function get_occlusionMap() {
		if( ambientOcclusionMap == null ) return null;
        return ambientOcclusionMap.ambientSampler;
	}

	function set_occlusionMap(t) {
        if( t != null && ambientOcclusionMap == null ) addAmbientOcculsionMap();
        if( ambientOcclusionMap == null ) return null;
        ambientOcclusionMap.ambientSampler = t;
		return t;
	}
    
	public function setColorRGBA(r, g, b, a) {
        if( baseColor != null )
            baseColor.uAlbedoColor.set(r, g, b, a);

        if( uv1 != null )
            uv1.uAlbedoColor.set(r, g, b, a);
    }
   
    function shaderList(sl:hxsl.ShaderList, ind:Int=0){
        if (sl!=null) {
            var txt = [ for (i in 0...ind) "  " ].join('');
            trace(txt+" - :"+Type.getClassName(Type.getClass(sl.s)));
            if (sl.next!=null)
                shaderList( sl.next, ind+1 );
        }
    }
    function addBaseColor() {
        baseColor = new h3d.shader.pbrsinglepass.BaseColor();
        mainPass.addShaderAtIndex(baseColor, 2+baseMeshOffset);
        dumpShaders("BaseColor added");
    }

    function addBaseColorUV() {
        var oldBC = mainPass.getShader( h3d.shader.pbrsinglepass.BaseColor );
        if (oldBC != null) {
            mainPass.removeShader( oldBC );
        }
        if (baseColorUV==null) {
            baseColorUV = new h3d.shader.pbrsinglepass.BaseColorUV();
        }
        mainPass.addShaderAtIndex(baseColorUV, 2+baseMeshOffset);
        dumpShaders("BaseColorUV added");
    }

    function addUV1() {
        var oldBC = mainPass.getShader( h3d.shader.pbrsinglepass.BaseColor );
        if (oldBC != null) {
            mainPass.removeShader( oldBC );
        }
        var oldBCUV = mainPass.getShader( h3d.shader.pbrsinglepass.BaseColorUV );
        if (oldBCUV != null) {
            mainPass.removeShader( oldBCUV );
        }
       if (uv1 == null) {
            uv1 = new h3d.shader.pbrsinglepass.UV1();
        }
        mainPass.addShaderAtIndex(uv1, 2+baseMeshOffset);
        dumpShaders("UV1 added");
    }

    function addNormalMap() {
        if (uv1 == null) addBaseColorUV();
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.Normal );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (normalMapping == null) {
            normalMapping = new h3d.shader.pbrsinglepass.NormalMap();
        }
        mainPass.addShaderAtIndex(normalMapping, 1+baseMeshOffset);
        dumpShaders("NormalMap added");
    }

    function addTangent() {
        if (uv1 == null) addBaseColorUV();
        var oldN = mainPass.getShader( h3d.shader.pbrsinglepass.Normal );
        var oldNM = mainPass.getShader( h3d.shader.pbrsinglepass.NormalMap );
        if (oldN != null) {
            mainPass.removeShader( oldN ); // Remove old Normal shader
        }
        if (oldNM != null) {
            mainPass.removeShader( oldNM ); // Remove old NormalMap shader
        }
        if (tangent == null) {
            tangent = new h3d.shader.pbrsinglepass.Tangent();
            if (oldNM != null) {
                tangent.bumpSampler = oldNM.bumpSampler;
            }
        }
        mainPass.addShaderAtIndex(tangent, 2+baseMeshOffset);
        dumpShaders("Tangent added");
    }

    function addAmbientOcculsion() {
        ambientOcclusion = new h3d.shader.pbrsinglepass.AmbientOcclusion();
        mainPass.addShaderAtIndex(ambientOcclusion, 3+baseMeshOffset);
        dumpShaders("AmbientOcclusion added");
    }

    function addAmbientMonochrome() {
        ambientMonochrome = new h3d.shader.pbrsinglepass.AmbientMonochrome();
        mainPass.addShaderAtIndex(ambientMonochrome, 6+baseMeshOffset);
        dumpShaders("AmbientMonochrome added");
    }

    function addAmbientOcculsionMap() {
        if (uv1 == null) addBaseColorUV();
        var oldAO = mainPass.getShader( h3d.shader.pbrsinglepass.AmbientOcclusion );
        if (oldAO != null) {
            mainPass.removeShader( oldAO );
        }
        ambientOcclusionMap = new h3d.shader.pbrsinglepass.AmbientOcclusionMap();
        mainPass.addShaderAtIndex(ambientOcclusionMap, 3+baseMeshOffset);

        var oldAM = mainPass.getShader( h3d.shader.pbrsinglepass.AmbientMonochrome );
        if (oldAM != null) {
            mainPass.removeShader( oldAM );
        }
        ambientMonochromeLum = new h3d.shader.pbrsinglepass.AmbientMonochromeLum();
        mainPass.addShaderAtIndex(ambientMonochromeLum, 5+baseMeshOffset);
        dumpShaders("AmbientMonochromeLum added");
    }

    function addSurface() {
        surface = new h3d.shader.pbrsinglepass.Surface();
        mainPass.addShaderAtIndex(surface, 4+baseMeshOffset);
        dumpShaders("Surface added");
    }

    function addSurfaceMap() {
        if (uv1 == null) addBaseColorUV();
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.Surface );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (surfaceMap == null) {
            surfaceMap = new h3d.shader.pbrsinglepass.SurfaceMap();
            if (old != null)
                surfaceMap.uReflectivityColor.set( old.uReflectivityColor.x, old.uReflectivityColor.y, old.uReflectivityColor.z, old.uReflectivityColor.w ); 
        }
        mainPass.addShaderAtIndex(surfaceMap, 4+baseMeshOffset);
        dumpShaders("SurfaceMap added");
    }

    function addIrradiance() {
        irradiance = new h3d.shader.pbrsinglepass.Irradiance();
        mainPass.addShaderAtIndex(irradiance, 5+baseMeshOffset);
        dumpShaders("Irradiance added");
    }

    function addIrradianceMap() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.Irradiance );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (irradianceMap == null) {
            irradianceMap = new h3d.shader.pbrsinglepass.IrradianceMap();
        }
        mainPass.addShaderAtIndex(irradianceMap, 5+baseMeshOffset);
        dumpShaders("IrradianceMap added");
    }

    function addSpecEnvReflect() {
        specEnvReflect = new h3d.shader.pbrsinglepass.SpecEnvReflect();
        mainPass.addShaderAtIndex(specEnvReflect, 7+baseMeshOffset);
        dumpShaders("SpecEnvReflect added");
    }

    function addSpecEnvReflectMap() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.SpecEnvReflect );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (specEnvReflectMap == null) {
            specEnvReflectMap = new h3d.shader.pbrsinglepass.SpecEnvReflectMap();
        }
        mainPass.addShaderAtIndex(specEnvReflectMap, 7+baseMeshOffset);
        dumpShaders("SpecEnvReflectMap added");
    }

    function addEmissive() {
        emissive = new h3d.shader.pbrsinglepass.Emissive();
        mainPass.addShaderAtIndex(emissive, 11+baseMeshOffset);
        dumpShaders("Emissive added");
    }

    function addEmissiveMap() {
        if (uv1 == null) addBaseColorUV();
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.Emissive );
        if (old != null) {
            mainPass.removeShader( old );
        }
         if (emissiveMap == null) {
            emissiveMap = new h3d.shader.pbrsinglepass.EmissiveMap();
        }
        mainPass.addShaderAtIndex(emissiveMap, 11+baseMeshOffset);
        dumpShaders("EmissiveMap added");
    }

    public var sphericalHarmonics(default, set):hxd.fmt.env.SphericalHarmonics;
    function set_sphericalHarmonics(value:hxd.fmt.env.SphericalHarmonics):hxd.fmt.env.SphericalHarmonics {
        this.sphericalHarmonics = value;
        vSphL00( value.l00.x, value.l00.y, value.l00.z ); 
        vSphL10( value.l10.x, value.l10.y, value.l10.z ); 
        vSphL20( value.l20.x, value.l20.y, value.l20.z ); 
        vSphL11( value.l11.x, value.l11.y, value.l11.z ); 
        vSphL21( value.l21.x, value.l21.y, value.l21.z ); 
        vSphL22( value.l22.x, value.l22.y, value.l22.z ); 
        vSphL1_1( value.l1_1.x, value.l1_1.y, value.l1_1.z ); 
        vSphL2_1( value.l2_1.x, value.l2_1.y, value.l2_1.z ); 
        vSphL2_2( value.l2_2.x, value.l2_2.y, value.l2_2.z );
        return value;
    }

    public function vSphL00(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL00.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL00.set(vx, vy, vz); 
    }

    public function vSphL10(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL10.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL10.set(vx, vy, vz); 
    }

    public function vSphL20(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL20.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL20.set(vx, vy, vz); 
    }

    public function vSphL11(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL11.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL11.set(vx, vy, vz); 
    }

    public function vSphL21(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL21.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL21.set(vx, vy, vz); 
    }

    public function vSphL22(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL22.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL22.set(vx, vy, vz); 
    }

    public function vSphL1_1(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL1_1.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL1_1.set(vx, vy, vz); 
    }

    public function vSphL2_1(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL2_1.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL2_1.set(vx, vy, vz); 
    }

    public function vSphL2_2(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphL2_2.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphL2_2.set(vx, vy, vz); 
    }

    public function vLightData( vx, vy, vz ) {
        envLighting.uLightData0.set( vx, vy, vz, 0 );
    }

    public function vLightDiffuse( vx, vy, vz ) {
        envLighting.uLightDiffuse0.set( vx, vy, vz, 1 );
    }

    public function vLightingIntensity( vx, vy, vz, vw ) {
        envLighting.uLightingIntensity.set( vx, vy, vz, vw );
    }

    public function addSheen( sheenColor:Array<Float>, sheenIntensity:Float, sheenRoughness:Float, sheenTexture:h3d.mat.Texture = null ) {
        if (sheen == null) sheen = new h3d.shader.pbrsinglepass.Sheen();

        this.sheenColor = sheenColor;
        this.sheenIntensity = sheenIntensity;
        this.sheenRoughness = sheenRoughness;

        if (sheenTexture != null) {
            // sheen.sheenSampler = sheenTexture;
        }

        mainPass.addShaderAtIndex(sheen, 9+baseMeshOffset);
        dumpShaders("Sheen added");
    }

    public function addClearCoat( ccFactor:Float, ccRoughnessFactor:Float, ccTexture:h3d.mat.Texture = null, ccRoughnessTexture:h3d.mat.Texture = null, ccNormalTexture:h3d.mat.Texture = null ) {
        if (clearCoat == null) clearCoat = new h3d.shader.pbrsinglepass.Clearcoat();

        clearCoatIntensity = ccFactor;
        clearCoatRoughness = ccRoughnessFactor;

        if (ccTexture != null) {
            // clearCoat.clearCoatSampler = ccTexture;
        }
        if (ccRoughnessTexture != null) {
            // clearCoat.reflectivitySampler = ccRoughnessTexture;
        }
        if (ccNormalTexture != null) {
            // clearCoat.reflectivitySampler = ccNormalTexture;
        }

        mainPass.addShaderAtIndex(clearCoat, 9+baseMeshOffset);
        dumpShaders("Clearcoat added");
    }
}