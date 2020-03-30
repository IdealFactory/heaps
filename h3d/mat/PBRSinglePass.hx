package h3d.mat;


class PBRSinglePass extends Material {

	public var pbrshader : h3d.shader.PBRSinglePass;
	public var baseColor : h3d.shader.pbrsinglepass.BaseColor;
	public var normal : h3d.shader.pbrsinglepass.Normal;
	public var normalMapping : h3d.shader.pbrsinglepass.NormalMap;
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
	public var finalCombination : h3d.shader.pbrsinglepass.FinalCombination;
	public var emissive : h3d.shader.pbrsinglepass.Emissive;
	public var emissiveMap : h3d.shader.pbrsinglepass.EmissiveMap;
	public var ambientOcclusion : h3d.shader.pbrsinglepass.AmbientOcclusion;
	public var ambientOcclusionMap : h3d.shader.pbrsinglepass.AmbientOcclusionMap;
    public var output : h3d.shader.pbrsinglepass.Output;

    private var baseMeshOffset:Int = 1;

    public function new() {

		super();

        trace("AfterConstructorSuper:");
        traceSL();

        pbrshader = new h3d.shader.PBRSinglePass();
        envLighting = new h3d.shader.pbrsinglepass.EnvLighting();
        finalCombination = new h3d.shader.pbrsinglepass.FinalCombination();
        output = new h3d.shader.pbrsinglepass.Output();
        
        // var col = h3d.mat.Texture.fromColor(0xFFFFFFFF);
        // normalMap = col;
        // environmentBRDF = col;
        // reflectivityMap = col;
        // emissiveMap = col;
        // occlusionMap = col;
        // reflectionCubeMap = h3d.mat.Texture.defaultCubeTexture();
            
        var bm = mainPass.getShader( h3d.shader.BaseMesh );
        if (bm != null) {
            mainPass.removeShader( bm );
            baseMeshOffset = 0;
        }

        mainPass.addShaderAtIndex(pbrshader, baseMeshOffset); // 1
        addNormal();// mainPass.addShader(baseColor); 20 
        addBaseColor();// mainPass.addShader(baseColor); 20 
        addAmbientOcculsion();// mainPass.addShader(ambientOcclusion or ambientOcclusionMap); 30 
        addSurface();// mainPass.addShader(surface or surfaceMap); 40 
        addIrradiance();// mainPass.addShader(irradiance or irradianceMap); 50
        mainPass.addShaderAtIndex(envLighting, 5 + baseMeshOffset); // 60
        addAmbientMonochrome();// mainPass.addShader(ambientMonochrome or ambientMonochromeLum); 70
        addSpecEnvReflect();// mainPass.addShader(specEnvReflect or specEnvReflectMap); 80
        mainPass.addShaderAtIndex(finalCombination, 8 + baseMeshOffset); // 90
        addEmissive(); // 110
        mainPass.addShaderAtIndex(output, 10 + baseMeshOffset); // 110
        
        // mainPass.addShaderAtIndex( new h3d.shader.pbrsinglepass.Debug(), 11 ); // 110
        

        // if (normal!=null) addNormal();
        // if (uv1==null) addBaseColor(); else addUV1();
        // if (ambientOcclusionMap==null) addAmbientOcculsion(); else addAmbientOcculsionMap();
        // if (surfaceMap==null) addSurface(); else addSurfaceMap();
        // if (irradianceMap==null) addIrradiance(); else addIrradianceMap();
        // addSpecEnvReflectMap();
        // if (emissive!=null) addEmissiveMap();

        trace("EndOfContructor:");
        traceSL();
    }

    public var environmentBRDF(get, set) : h3d.mat.Texture;
	public var reflectivityMap(get, set) : h3d.mat.Texture;
	public var emissiveLightMap(get, set) : h3d.mat.Texture;
	public var reflectionCubeMap(get, set) : h3d.mat.Texture;
	public var occlusionMap(get, set) : h3d.mat.Texture;

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
        if( normalMapping == null ) return null;
        return normalMapping.bumpSampler;
	}

	override function set_normalMap(t) {
        if( t != null && normalMapping == null ) addNormalMap();
        if( normalMapping == null ) return null;
        normalMapping.bumpSampler = t;
		return t;
	}

    function get_environmentBRDF() {
		if( envLighting == null ) return null;
        return envLighting.environmentBrdfSampler;
	}

	function set_environmentBRDF(t) {
        if( envLighting == null ) return null;
        envLighting.environmentBrdfSampler = t;
		return t;
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

    function get_reflectionCubeMap() {
		if( irradianceMap == null ) return null;
        return irradianceMap.reflectionSampler;
	}

	function set_reflectionCubeMap(t) {
        if( t != null && irradianceMap == null ) addIrradianceMap();
        if( irradianceMap == null ) return null;
        irradianceMap.reflectionSampler = t;
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

    function traceSL() {
        @:privateAccess shaderList( mainPass.shaders );
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
        trace("addBaseColor:");
        traceSL();
    }

    function addUV1() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.BaseColor );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (uv1 == null) {
            uv1 = new h3d.shader.pbrsinglepass.UV1();
        }
        mainPass.addShaderAtIndex(uv1, 2+baseMeshOffset);
        trace("addUV1:");
        traceSL();
    }

    function addNormal() {
        normal = new h3d.shader.pbrsinglepass.Normal();
        mainPass.addShaderAtIndex(normal, 1+baseMeshOffset);
        trace("addNormal:");
        traceSL();
    }

    function addNormalMap() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.NormalMap );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (normalMapping == null) {
            normalMapping = new h3d.shader.pbrsinglepass.NormalMap();
        }
        mainPass.addShaderAtIndex(normalMapping, 1+baseMeshOffset);
        trace("addNormalMap:");
        traceSL();
    }

    function addAmbientOcculsion() {
        ambientOcclusion = new h3d.shader.pbrsinglepass.AmbientOcclusion();
        mainPass.addShaderAtIndex(ambientOcclusion, 3+baseMeshOffset);
        trace("addAmbientOcculsion:");
        traceSL();
    }

    function addAmbientMonochrome() {
        ambientMonochrome = new h3d.shader.pbrsinglepass.AmbientMonochrome();
        mainPass.addShaderAtIndex(ambientMonochrome, 7+baseMeshOffset);
        trace("addAmbientMonochrome:");
        traceSL();
    }

    function addAmbientOcculsionMap() {
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
        mainPass.addShaderAtIndex(ambientMonochromeLum, 7+baseMeshOffset);
        trace("addAmbientOcculsionMap:");
        traceSL();
    }

    function addSurface() {
        surface = new h3d.shader.pbrsinglepass.Surface();
        mainPass.addShaderAtIndex(surface, 4+baseMeshOffset);
        trace("addSurface:");
        traceSL();
    }

    function addSurfaceMap() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.Surface );
        if (old != null) {
            mainPass.removeShader( old );
        }
        if (surfaceMap == null) {
            surfaceMap = new h3d.shader.pbrsinglepass.SurfaceMap();
        }
        mainPass.addShaderAtIndex(surfaceMap, 4+baseMeshOffset);
        trace("addSurfaceMap:");
        traceSL();
    }

    function addIrradiance() {
        irradiance = new h3d.shader.pbrsinglepass.Irradiance();
        mainPass.addShaderAtIndex(irradiance, 5+baseMeshOffset);
        trace("addIrradiance:");
        traceSL();
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
        trace("addIrradianceMap:");
        traceSL();

    }

    function addSpecEnvReflect() {
        specEnvReflect = new h3d.shader.pbrsinglepass.SpecEnvReflect();
        mainPass.addShaderAtIndex(specEnvReflect, 6+baseMeshOffset);
        trace("addSpecEnvReflect:");
        traceSL();
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
        trace("addSpecEnvReflectMap:");
        traceSL();
    }

    function addEmissive() {
        emissive = new h3d.shader.pbrsinglepass.Emissive();
        mainPass.addShaderAtIndex(emissive, 10+baseMeshOffset);
        trace("addEmissive:");
        traceSL();
    }

    function addEmissiveMap() {
        var old = mainPass.getShader( h3d.shader.pbrsinglepass.Emissive );
        if (old != null) {
            mainPass.removeShader( old );
        }
         if (emissiveMap == null) {
            emissiveMap = new h3d.shader.pbrsinglepass.EmissiveMap();
        }
        mainPass.addShaderAtIndex(emissiveMap, 10+baseMeshOffset);
        trace("addEmissiveMap:");
        traceSL();
    }

    override function refreshProps() {
        // pbrshader.vEyePosition.set( [] );
    }
}