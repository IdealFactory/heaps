package h3d.mat;


class PBRSinglePass extends Material {

	var pbrshader : h3d.shader.PBRSinglePass;

    public function new() {
		super();
        if( pbrshader == null ) {
            pbrshader = new h3d.shader.PBRSinglePass();
            var col = h3d.mat.Texture.fromColor(0xFFFFFFFF);
            normalMap = col;
            environmentBRDF = col;
            reflectivityMap = col;
            emissiveMap = col;
            occlusionMap = col;
            reflectionCubeMap = h3d.mat.Texture.defaultCubeTexture();
            
            mainPass.addShader(pbrshader);
        }
    }

    public var environmentBRDF(get, set) : h3d.mat.Texture;
	public var reflectivityMap(get, set) : h3d.mat.Texture;
	public var emissiveMap(get, set) : h3d.mat.Texture;
	public var reflectionCubeMap(get, set) : h3d.mat.Texture;
	public var occlusionMap(get, set) : h3d.mat.Texture;

    override function get_texture() {
        if( pbrshader == null ) return null;
		return pbrshader.albedoSampler;
	}

	override function set_texture(t) {
        if( pbrshader == null ) return null;
        pbrshader.albedoSampler = t;
		return t;
	}

    override function get_normalMap() {
        if( pbrshader == null ) return null;
        return pbrshader.bumpSampler;
	}

	override function set_normalMap(t) {
        if( pbrshader == null ) return null;
        pbrshader.bumpSampler = t;
		return t;
	}

    function get_environmentBRDF() {
		if( pbrshader == null ) return null;
        return pbrshader.environmentBrdfSampler;
	}

	function set_environmentBRDF(t) {
        if( pbrshader == null ) return null;
        pbrshader.environmentBrdfSampler = t;
		return t;
	}

    function get_reflectivityMap() {
		if( pbrshader == null ) return null;
        return pbrshader.reflectivitySampler;
	}

	function set_reflectivityMap(t) {
        if( pbrshader == null ) return null;
        pbrshader.reflectivitySampler = t;
		return t;
	}

    function get_emissiveMap() {
		if( pbrshader == null ) return null;
        return pbrshader.emissiveSampler;
	}

	function set_emissiveMap(t) {
        if( pbrshader == null ) return null;
        pbrshader.emissiveSampler = t;
		return t;
	}

    function get_reflectionCubeMap() {
		if( pbrshader == null ) return null;
        return pbrshader.reflectionSampler;
	}

	function set_reflectionCubeMap(t) {
        if( pbrshader == null ) return null;
        pbrshader.reflectionSampler = t;
		return t;
	}

    function get_occlusionMap() {
		if( pbrshader == null ) return null;
        return pbrshader.ambientSampler;
	}

	function set_occlusionMap(t) {
        if( pbrshader == null ) return null;
        pbrshader.ambientSampler = t;
		return t;
	}
    
    override function refreshProps() {
        // pbrshader.vEyePosition.set( [] );
    }
}