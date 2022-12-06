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

    public var reflectivityMap(get, set) : h3d.mat.Texture;
	public var emissiveLightMap(get, set) : h3d.mat.Texture;
	public var occlusionMap(get, set) : h3d.mat.Texture;

    private var baseMeshOffset:Int = 1;

    public function new() {

		super();

        pbrshader = new h3d.shader.PBRSinglePass();
        envLighting = new h3d.shader.pbrsinglepass.EnvLighting();
        finalCombination = new h3d.shader.pbrsinglepass.FinalCombination();
        output = new h3d.shader.pbrsinglepass.Output();
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
        addAmbientOcculsion();
        addSurface();
        addIrradiance();
        mainPass.addShaderAtIndex(envLighting, 5 + baseMeshOffset);
        addAmbientMonochrome();
        addSpecEnvReflect();
        mainPass.addShaderAtIndex(finalCombination, 8 + baseMeshOffset);
        addSheen([1, 1, 1], 0, 0);
        addClearCoat( 0, 0 );
        addEmissive();
        mainPass.addShaderAtIndex(output, 10 + baseMeshOffset);
        mainPass.addShaderAtIndex(colorTransform, 11 + baseMeshOffset);
    }

	override function clone( ?m : BaseMaterial ) : BaseMaterial {
        var m = m == null ? new PBRSinglePass() : cast m;
		super.clone(m);

        m.pbrshader = this.pbrshader;
        m.baseColor = this.baseColor;
        m.baseColorUV = this.baseColorUV;
        m.normalMapping = this.normalMapping;
        m.tangent = this.tangent;
        m.uv1 = this.uv1;
        m.surface = this.surface;
        m.surfaceMap = this.surfaceMap;
        m.irradiance = this.irradiance;
        m.irradianceMap = this.irradianceMap;
        m.envLighting = this.envLighting;
        m.ambientMonochrome = this.ambientMonochrome;
        m.ambientMonochromeLum = this.ambientMonochromeLum;
        m.specEnvReflect = this.specEnvReflect;
        m.specEnvReflectMap = this.specEnvReflectMap;
        m.sheen = this.sheen;
        m.clearCoat = this.clearCoat;
        m.finalCombination = this.finalCombination;
        m.emissive = this.emissive;
        m.emissiveMap = this.emissiveMap;
        m.ambientOcclusion = this.ambientOcclusion;
        m.ambientOcclusionMap = this.ambientOcclusionMap;
        m.output = this.output;
        m.colorTransform = this.colorTransform;
    
        m.hasTangentBuffer = this.hasTangentBuffer;
    
        m.metalnessFactor = this.metalnessFactor;
        m.roughnessFactor = this.roughnessFactor;
        m.sheenColor = this.sheenColor;
        m.sheenIntensity = this.sheenIntensity;
        m.sheenRoughness = this.sheenRoughness;
        m.clearCoatIntensity = this.clearCoatIntensity;
        m.clearCoatRoughness = this.clearCoatRoughness;
        m.clearCoatIndexOfRefraction = this.clearCoatIndexOfRefraction;

        m.reflectivityMap = this.reflectivityMap;
        m.emissiveLightMap = this.emissiveLightMap;
        m.occlusionMap = this.occlusionMap;
    
        m.baseMeshOffset = this.baseMeshOffset;

        var pIdx = 0;
        @:privateAccess m.passes = this.mainPass.clone();
        m.mainPass.load( this.mainPass );

        return m;
	}

    override function get_texture() {
        if( uv1 == null ) return null;
		return uv1.albedoSampler;
	}

	override function set_texture(t) {
        if( t != null && uv1 == null ) addUV1();
        if( uv1 == null ) return null;
        uv1.albedoSampler = t;
		return t;
	}

    override function get_normalMap() {
        if( normalMapping != null ) return normalMapping.bumpSampler;
        if( tangent != null ) return tangent.bumpSampler;
        return null;
	}

	override function set_normalMap(t) {
        if( t != null) {
            // if (this.hasTangentBuffer) {
            //     if (tangent==null) addTangent();
            //     tangent.bumpSampler = t;
            // } else {
                if (normalMapping==null) addNormalMap();
                normalMapping.bumpSampler = t;
            // }
        }
		return t;
    }
    
    function set_hasTangentBuffer( val:Bool ):Bool {
        // this.hasTangentBuffer = val;
        // if (val) {
        //     if (tangent==null) addTangent();
        // }
        return false;//val;
    }


    function set_metalnessFactor( val:Float ):Float {
        this.metalnessFactor = val;
        if (surface!=null) {
            surface.vReflectivityColor.x = val;
        };
        if (surfaceMap!=null) {
            surfaceMap.vReflectivityColor.x = val;
        };
        return val;
    }

    function set_roughnessFactor( val:Float ):Float {
        this.roughnessFactor = val;
        if (surface!=null) {
            surface.vReflectivityColor.y = val;
        };
        if (surfaceMap!=null) {
            surfaceMap.vReflectivityColor.y = val;
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
            baseColor.vAlbedoColor.set(r, g, b, a);

        if( uv1 != null )
            uv1.vAlbedoColor.set(r, g, b, a);
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
    }

    function addTangent() {
        // if (uv1 == null) addBaseColorUV();
        // var oldN = mainPass.getShader( h3d.shader.pbrsinglepass.Normal );
        // var oldNM = mainPass.getShader( h3d.shader.pbrsinglepass.NormalMap );
        // if (oldN != null) {
        //     mainPass.removeShader( oldN ); // Remove old Normal shader
        // }
        // if (oldNM != null) {
        //     mainPass.removeShader( oldNM ); // Remove old NormalMap shader
        // }
        // if (tangent == null) {
        //     tangent = new h3d.shader.pbrsinglepass.Tangent();
        //     if (oldNM != null) {
        //         tangent.bumpSampler = oldNM.bumpSampler;
        //     }
        // }
        // mainPass.addShaderAtIndex(tangent, 1+baseMeshOffset);
    }

    function addAmbientOcculsion() {
        ambientOcclusion = new h3d.shader.pbrsinglepass.AmbientOcclusion();
        mainPass.addShaderAtIndex(ambientOcclusion, 3+baseMeshOffset);
    }

    function addAmbientMonochrome() {
        ambientMonochrome = new h3d.shader.pbrsinglepass.AmbientMonochrome();
        mainPass.addShaderAtIndex(ambientMonochrome, 5+baseMeshOffset);
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
    }

    function addSurface() {
        surface = new h3d.shader.pbrsinglepass.Surface();
        mainPass.addShaderAtIndex(surface, 4+baseMeshOffset);
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
                surfaceMap.vReflectivityColor.set( old.vReflectivityColor.x, old.vReflectivityColor.y, old.vReflectivityColor.z, old.vReflectivityColor.w ); 
        }
        mainPass.addShaderAtIndex(surfaceMap, 4+baseMeshOffset);
    }

    function addIrradiance() {
        irradiance = new h3d.shader.pbrsinglepass.Irradiance();
        mainPass.addShaderAtIndex(irradiance, 5+baseMeshOffset);
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

    }

    function addSpecEnvReflect() {
        specEnvReflect = new h3d.shader.pbrsinglepass.SpecEnvReflect();
        mainPass.addShaderAtIndex(specEnvReflect, 6+baseMeshOffset);
    }

    function addSpecEnvReflectMap() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.SpecEnvReflect );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (specEnvReflectMap == null) {
            specEnvReflectMap = new h3d.shader.pbrsinglepass.SpecEnvReflectMap();
        }
        mainPass.addShaderAtIndex(specEnvReflectMap, 6+baseMeshOffset);
    }

    function addEmissive() {
        emissive = new h3d.shader.pbrsinglepass.Emissive();
        mainPass.addShaderAtIndex(emissive, 11+baseMeshOffset);
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
    }

    public var sphericalHarmonics(default, set):hxd.fmt.env.SphericalHarmonics;
    function set_sphericalHarmonics(value:hxd.fmt.env.SphericalHarmonics):hxd.fmt.env.SphericalHarmonics {
        this.sphericalHarmonics = value;
        vSphericalL00( value.l00.x, value.l00.y, value.l00.z ); 
        vSphericalL10( value.l10.x, value.l10.y, value.l10.z ); 
        vSphericalL20( value.l20.x, value.l20.y, value.l20.z ); 
        vSphericalL11( value.l11.x, value.l11.y, value.l11.z ); 
        vSphericalL21( value.l21.x, value.l21.y, value.l21.z ); 
        vSphericalL22( value.l22.x, value.l22.y, value.l22.z ); 
        vSphericalL1_1( value.l1_1.x, value.l1_1.y, value.l1_1.z ); 
        vSphericalL2_1( value.l2_1.x, value.l2_1.y, value.l2_1.z ); 
        vSphericalL2_2( value.l2_2.x, value.l2_2.y, value.l2_2.z );
        return value;
    }

    public function vSphericalL00(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL00.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL00.set(vx, vy, vz); 
    }

    public function vSphericalL10(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL10.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL10.set(vx, vy, vz); 
    }

    public function vSphericalL20(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL20.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL20.set(vx, vy, vz); 
    }

    public function vSphericalL11(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL11.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL11.set(vx, vy, vz); 
    }

    public function vSphericalL21(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL21.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL21.set(vx, vy, vz); 
    }

    public function vSphericalL22(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL22.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL22.set(vx, vy, vz); 
    }

    public function vSphericalL1_1(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL1_1.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL1_1.set(vx, vy, vz); 
    }

    public function vSphericalL2_1(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL2_1.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL2_1.set(vx, vy, vz); 
    }

    public function vSphericalL2_2(vx:Float, vy:Float, vz:Float) {
        if (irradiance!=null) irradiance.vSphericalL2_2.set(vx, vy, vz); 
        if (irradianceMap!=null) irradianceMap.vSphericalL2_2.set(vx, vy, vz); 
    }

    public function vLightData( vx, vy, vz ) {
        envLighting.vLightData0.set( vx, vy, vz, 0 );
    }

    public function vLightDiffuse( vx, vy, vz ) {
        envLighting.vLightDiffuse0.set( vx, vy, vz, 1 );
    }

    public function vLightingIntensity( vx, vy, vz, vw ) {
        envLighting.vLightingIntensity.set( vx, vy, vz, vw );
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

        mainPass.addShaderAtIndex(clearCoat, 10+baseMeshOffset);
    }
}