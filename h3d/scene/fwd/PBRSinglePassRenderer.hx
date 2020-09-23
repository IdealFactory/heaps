package h3d.scene.fwd;

class PBRSinglePassRenderer extends h3d.scene.fwd.Renderer {

    public var pbrPass:h3d.pass.PBRSinglePass;

	public function new() {
        super();
        
		defaultPass = pbrPass = new h3d.pass.PBRSinglePass("default");
		allPasses = [defaultPass, depth, normal, shadow];
    }
}