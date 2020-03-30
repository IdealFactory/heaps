package h3d.shader.pbrsinglepass;        

class BaseColor extends hxsl.Shader {

	static var SRC = {

        @var var vNormalW : Vec3;                       // varying vec3 vNormalW;

        @var var vEnvironmentIrradiance : Vec3;         // varying vec3 vEnvironmentIrradiance;

        @param var vSphericalL00 : Vec3;                // uniform vec3 vSphericalL00;
        @param var vSphericalL1_1 : Vec3;               // uniform vec3 vSphericalL1_1;
        @param var vSphericalL10 : Vec3;                // uniform vec3 vSphericalL10;
        @param var vSphericalL11 : Vec3;                // uniform vec3 vSphericalL11;
        @param var vSphericalL2_2 : Vec3;               // uniform vec3 vSphericalL2_2;
        @param var vSphericalL2_1 : Vec3;               // uniform vec3 vSphericalL2_1;
        @param var vSphericalL20 : Vec3;                // uniform vec3 vSphericalL20;
        @param var vSphericalL21 : Vec3;                // uniform vec3 vSphericalL21;
        @param var vSphericalL22 : Vec3;                // uniform vec3 vSphericalL22;
        
        @param var reflectionMatrix : Mat4;             // uniform mat4 reflectionMatrix;
        
        @param var vAlbedoColor : Vec4;                 // uniform vec4 vAlbedoColor;

        var normalW:Vec3;

        function computeEnvironmentIrradiance( normal:Vec3 ):Vec3 {
            return vSphericalL00 +
                vSphericalL1_1 * (normal.y) +
                vSphericalL10 * (normal.z) +
                vSphericalL11 * (normal.x) +
                vSphericalL2_2 * (normal.y * normal.x) +
                vSphericalL2_1 * (normal.y * normal.z) +
                vSphericalL20 * ((3.0 * normal.z * normal.z) - 1.0) +
                vSphericalL21 * (normal.z * normal.x) +
                vSphericalL22 * (normal.x * normal.x - (normal.y * normal.y));
        }

        function vertex() {
            var reflectionVector = (reflectionMatrix * vec4(vNormalW, 0)).xyz;
            reflectionVector.z *= -1.0;
            vEnvironmentIrradiance = computeEnvironmentIrradiance(reflectionVector);
            var uvUpdated = vec2(0., 0.);
        }

        var surfaceAlbedo:Vec3;
        var alpha:Float;
        var ambientOcclusionColor:Vec3;

        function fragment() {
            normalW = normalize(vNormalW);
            surfaceAlbedo = vAlbedoColor.rgb; //vec3
            alpha = vAlbedoColor.a; //float

            ambientOcclusionColor = vec3(1., 1., 1.); //vec3            
        }
    }

    public function new() {
        super();

        this.vAlbedoColor.set( 1., 1., 1, 1 );

        this.vSphericalL10.set( 0.0979, 0.0495, 0.0295 );
        this.vSphericalL22.set( 0.0093, -0.0337, -0.1483 );
        this.vSphericalL11.set( 0.0867, 0.1087, 0.1688 );
        this.vSphericalL00.set( 0.5444, 0.4836, 0.6262 );
        this.vSphericalL20.set( 0.0062, -0.0018, -0.0101 );
        this.vSphericalL21.set( 0.0408, 0.0495, 0.0935 );
        this.vSphericalL2_2.set( 0.0154, 0.0403, 0.1151 );
        this.vSphericalL2_1.set( 0.0442, 0.0330, 0.0402 );

        this.reflectionMatrix.loadValues([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

    }
}
        