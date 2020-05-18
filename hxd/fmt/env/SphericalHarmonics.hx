package hxd.fmt.env;

/* 
    https://github.com/BabylonJS/Babylon.js  /src/Math/sphericalPolynomial.ts
    https://github.com/BabylonJS/Babylon.js/blob/master/license.md
*/

import h3d.Vector;

class SphericalHarmonics {

    static var SHCosKernelConvolution = [
        Math.PI,
    
        2 * Math.PI / 3,
        2 * Math.PI / 3,
        2 * Math.PI / 3,
    
        Math.PI / 4,
        Math.PI / 4,
        Math.PI / 4,
        Math.PI / 4,
        Math.PI / 4,
    ];

    static var SH3ylmBasisConstants = [
        Math.sqrt(1 / (4 * Math.PI)), // l00
    
        -Math.sqrt(3 / (4 * Math.PI)), // l1_1
        Math.sqrt(3 / (4 * Math.PI)), // l10
        -Math.sqrt(3 / (4 * Math.PI)), // l11
    
        Math.sqrt(15 / (4 * Math.PI)), // l2_2
        -Math.sqrt(15 / (4 * Math.PI)), // l2_1
        Math.sqrt(5 / (16 * Math.PI)), // l20
        -Math.sqrt(15 / (4 * Math.PI)), // l21
        Math.sqrt(15 / (16 * Math.PI)), // l22
    ];
    
    public function new() {}

    /**
     * Defines whether or not the harmonics have been prescaled for rendering.
     */
    public var preScaled = false;

    /**
     * The l0,0 coefficients of the spherical harmonics
     */
    public var l00:Vector = new Vector();

    /**
     * The l1,-1 coefficients of the spherical harmonics
     */
    public var l1_1:Vector = new Vector();

    /**
     * The l1,0 coefficients of the spherical harmonics
     */
    public var l10:Vector = new Vector();

    /**
     * The l1,1 coefficients of the spherical harmonics
     */
    public var l11:Vector = new Vector();

    /**
     * The l2,-2 coefficients of the spherical harmonics
     */
    public var l2_2:Vector = new Vector();

    /**
     * The l2,-1 coefficients of the spherical harmonics
     */
    public var l2_1:Vector = new Vector();

    /**
     * The l2,0 coefficients of the spherical harmonics
     */
    public var l20:Vector = new Vector();

    /**
     * The l2,1 coefficients of the spherical harmonics
     */
    public var l21:Vector = new Vector();

    /**
     * The l2,2 coefficients of the spherical harmonics
     */
    public var l22:Vector = new Vector();

    // inline function applySH3(lm:Float, direction:Vector) {
    //     return SH3ylmBasisConstants[lm] * SH3ylmBasisTrigonometricTerms[lm](direction);
    // };

    /**
     * Adds a light to the spherical harmonics
     * @param direction the direction of the light
     * @param color the color of the light
     * @param deltaSolidAngle the delta solid angle of the light
     */
    // public function addLight(direction:Vector, colorR:Float, colorG:Float, colorB:Float, deltaSolidAngle:Float) {
    //     var colorVector = new Vector(colorR, colorG, colorB);
    //     var c = colorVector.scale3(deltaSolidAngle);

    //     this.l00 = this.l00.add(c.scale3(applySH3(0, direction)));

    //     this.l1_1 = this.l1_1.add(c.scale3(applySH3(1, direction)));
    //     this.l10 = this.l10.add(c.scale3(applySH3(2, direction)));
    //     this.l11 = this.l11.add(c.scale3(applySH3(3, direction)));

    //     this.l2_2 = this.l2_2.add(c.scale3(applySH3(4, direction)));
    //     this.l2_1 = this.l2_1.add(c.scale3(applySH3(5, direction)));
    //     this.l20 = this.l20.add(c.scale3(applySH3(6, direction)));
    //     this.l21 = this.l21.add(c.scale3(applySH3(7, direction)));
    //     this.l22 = this.l22.add(c.scale3(applySH3(8, direction)));
    // }

    /**
     * Scales the spherical harmonics by the given amount
     * @param scale the amount to scale
     */
    public function scale3(scale:Float) {
        this.l00.scale3(scale);
        this.l1_1.scale3(scale);
        this.l10.scale3(scale);
        this.l11.scale3(scale);
        this.l2_2.scale3(scale);
        this.l2_1.scale3(scale);
        this.l20.scale3(scale);
        this.l21.scale3(scale);
        this.l22.scale3(scale);
    }

    /**
     * Convert from incident radiance (Li) to irradiance (E) by applying convolution with the cosine-weighted hemisphere.
     *
     * ```
     * E_lm = A_l * L_lm
     * ```
     *
     * In spherical harmonics this convolution amounts to scaling factors for each frequency band.
     * This corresponds to equation 5 in "An Efficient Representation for Irradiance Environment Maps", where
     * the scaling factors are given in equation 9.
     */
    public function convertIncidentRadianceToIrradiance() {
        // Constant (Band 0)
        this.l00.scale3(SHCosKernelConvolution[0]);

        // Linear (Band 1)
        this.l1_1.scale3(SHCosKernelConvolution[1]);
        this.l10.scale3(SHCosKernelConvolution[2]);
        this.l11.scale3(SHCosKernelConvolution[3]);

        // Quadratic (Band 2)
        this.l2_2.scale3(SHCosKernelConvolution[4]);
        this.l2_1.scale3(SHCosKernelConvolution[5]);
        this.l20.scale3(SHCosKernelConvolution[6]);
        this.l21.scale3(SHCosKernelConvolution[7]);
        this.l22.scale3(SHCosKernelConvolution[8]);
    }

    /**
     * Convert from irradiance to outgoing radiance for Lambertian BDRF, suitable for efficient shader evaluation.
     *
     * ```
     * L = (1/pi) * E * rho
     * ```
     *
     * This is done by an additional scale by 1/pi, so is a fairly trivial operation but important conceptually.
     */
    public function convertIrradianceToLambertianRadiance() {
        this.scale3(1.0 / Math.PI);

        // The resultant SH now represents outgoing radiance, so includes the Lambert 1/pi normalisation factor but without albedo (rho) applied
        // (The pixel shader must apply albedo after texture fetches, etc).
    }

    /**
     * Integrates the reconstruction coefficients directly in to the SH preventing further
     * required operations at run time.
     *
     * This is simply done by scaling back the SH with Ylm constants parameter.
     * The trigonometric part being applied by the shader at run time.
     */
    public function preScaleForRendering() {
        this.preScaled = true;

        this.l00.scale3(SH3ylmBasisConstants[0]);

        this.l1_1.scale3(SH3ylmBasisConstants[1]);
        this.l10.scale3(SH3ylmBasisConstants[2]);
        this.l11.scale3(SH3ylmBasisConstants[3]);

        this.l2_2.scale3(SH3ylmBasisConstants[4]);
        this.l2_1.scale3(SH3ylmBasisConstants[5]);
        this.l20.scale3(SH3ylmBasisConstants[6]);
        this.l21.scale3(SH3ylmBasisConstants[7]);
        this.l22.scale3(SH3ylmBasisConstants[8]);
    }

    /**
     * Constructs a spherical harmonics from an array.
     * @param data defines the 9x3 coefficients (l00, l1-1, l10, l11, l2-2, l2-1, l20, l21, l22)
     * @returns the spherical harmonics
     */
    public static function fromArray(data: Array<Array<Float>>): SphericalHarmonics {
        var sh = new SphericalHarmonics();
        sh.l00 = Vector.fromArray( data[0] );
        sh.l1_1 = Vector.fromArray( data[1] );
        sh.l10 = Vector.fromArray( data[2] );
        sh.l11 = Vector.fromArray( data[3] );
        sh.l2_2 = Vector.fromArray( data[4] );
        sh.l2_1 = Vector.fromArray( data[5] );
        sh.l20 = Vector.fromArray( data[6] );
        sh.l21 = Vector.fromArray( data[7] );
        sh.l22 = Vector.fromArray( data[8] );
        return sh;
    }

    // Keep for references.
    /**
     * Gets the spherical harmonics from polynomial
     * @param polynomial the spherical polynomial
     * @returns the spherical harmonics
     */
    public static function fromPolynomial(polynomial: SphericalPolynomial): SphericalHarmonics {
        var result = new SphericalHarmonics();

        var v0d376127 = new Vector(0.376127, 0.376127, 0.376127, 0);
        var v0d376126 = new Vector(0.376126, 0.376126, 0.376126, 0);
        var v0d672834 = new Vector(0.672834, 0.672834, 0.672834, 0);
        var v0d977204 = new Vector(0.977204, 0.977204, 0.977204, 0);
        var v1d16538 = new Vector(1.16538, 1.16538, 1.16538, 0);
        var v1d34567 = new Vector(1.34567, 1.34567, 1.34567, 0);
        result.l00 = polynomial.xx.mult(v0d376127).add(polynomial.yy.mult(v0d376127)).add(polynomial.zz.mult(v0d376126));
        result.l1_1 = polynomial.y.mult(v0d977204);
        result.l10 = polynomial.z.mult(v0d977204);
        result.l11 = polynomial.x.mult(v0d977204);
        result.l2_2 = polynomial.xy.mult(v1d16538);
        result.l2_1 = polynomial.yz.mult(v1d16538);
        result.l20 = polynomial.zz.mult(v1d34567).sub(polynomial.xx.mult(v0d672834)).sub(polynomial.yy.mult(v0d672834));
        result.l21 = polynomial.zx.mult(v1d16538);
        result.l22 = polynomial.xx.mult(v1d16538).sub(polynomial.yy.mult(v1d16538));

        result.l1_1.scale3(-1);
        result.l11.scale3(-1);
        result.l2_1.scale3(-1);
        result.l21.scale3(-1);

        result.scale3(Math.PI);

        return result;
    }
}