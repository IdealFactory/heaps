package hxd.fmt.env;

/* 
    https://github.com/BabylonJS/Babylon.js  /src/Math/sphericalPolynomial.ts
    https://github.com/BabylonJS/Babylon.js/blob/master/license.md
*/

import h3d.Vector;

class SphericalPolynomial {

    public function new() {}

    private var _harmonics: SphericalHarmonics;

    /**
     * The spherical harmonics used to create the polynomials.
     */
    public var preScaledHarmonics(get, null): SphericalHarmonics;
    function get_preScaledHarmonics(): SphericalHarmonics {
        if (_harmonics == null) {
            _harmonics = SphericalHarmonics.fromPolynomial(this);
        }
        if (!_harmonics.preScaled) {
            _harmonics.preScaleForRendering();
        }
        return _harmonics;
    }

    /**
     * The x coefficients of the spherical polynomial
     */
    public var x: Vector = new Vector();

    /**
     * The y coefficients of the spherical polynomial
     */
    public var y: Vector = new Vector();

    /**
     * The z coefficients of the spherical polynomial
     */
    public var z: Vector = new Vector();

    /**
     * The xx coefficients of the spherical polynomial
     */
    public var xx: Vector = new Vector();

    /**
     * The yy coefficients of the spherical polynomial
     */
    public var yy: Vector = new Vector();

    /**
     * The zz coefficients of the spherical polynomial
     */
    public var zz: Vector = new Vector();

    /**
     * The xy coefficients of the spherical polynomial
     */
    public var xy: Vector = new Vector();

    /**
     * The yz coefficients of the spherical polynomial
     */
    public var yz: Vector = new Vector();

    /**
     * The zx coefficients of the spherical polynomial
     */
    public var zx: Vector = new Vector();

    /**
     * Adds an ambient color to the spherical polynomial
     * @param color the color to add
     */
    public function addAmbient(r:Float, g:Float, b:Float) {
        var colorVector = new Vector(r, g, b);
        this.xx = this.xx.add(colorVector);
        this.yy = this.yy.add(colorVector);
        this.zz = this.zz.add(colorVector);
    }

    /**
     * Scales the spherical polynomial by the given amount
     * @param scale the amount to scale
     */
    public function scaleInPlace(scale:Float) {
        this.x.scale3(scale);
        this.y.scale3(scale);
        this.z.scale3(scale);
        this.xx.scale3(scale);
        this.yy.scale3(scale);
        this.zz.scale3(scale);
        this.yz.scale3(scale);
        this.zx.scale3(scale);
        this.xy.scale3(scale);
    }

    // /**
    //  * Gets the spherical polynomial from harmonics
    //  * @param harmonics the spherical harmonics
    //  * @returns the spherical polynomial
    //  */
    // public static FromHarmonics(harmonics: SphericalHarmonics): SphericalPolynomial {
    //     var result = new SphericalPolynomial();
    //     result._harmonics = harmonics;

    //     result.x = harmonics.l11.scale(1.02333).scale(-1);
    //     result.y = harmonics.l1_1.scale(1.02333).scale(-1);
    //     result.z = harmonics.l10.scale(1.02333);

    //     result.xx = harmonics.l00.scale(0.886277).subtract(harmonics.l20.scale(0.247708)).add(harmonics.l22.scale(0.429043));
    //     result.yy = harmonics.l00.scale(0.886277).subtract(harmonics.l20.scale(0.247708)).subtract(harmonics.l22.scale(0.429043));
    //     result.zz = harmonics.l00.scale(0.886277).add(harmonics.l20.scale(0.495417));

    //     result.yz = harmonics.l2_1.scale(0.858086).scale(-1);
    //     result.zx = harmonics.l21.scale(0.858086).scale(-1);
    //     result.xy = harmonics.l2_2.scale(0.858086);

    //     result.scaleInPlace(1.0 / Math.PI);

    //     return result;
    // }

    /**
     * Constructs a spherical polynomial from an array.
     * @param data defines the 9x3 coefficients (x, y, z, xx, yy, zz, yz, zx, xy)
     * @returns the spherical polynomial
     */
    public static function fromArray(data: Array<Array<Float>>): SphericalPolynomial {
        var sp = new SphericalPolynomial();
        sp.x = Vector.fromArray( data[0] );
        sp.y = Vector.fromArray( data[1] );
        sp.z = Vector.fromArray( data[2] );
        sp.xx = Vector.fromArray( data[3] );
        sp.yy = Vector.fromArray( data[4] );
        sp.zz = Vector.fromArray( data[5] );
        sp.yz = Vector.fromArray( data[6] );
        sp.zx = Vector.fromArray( data[7] );
        sp.xy = Vector.fromArray( data[8] );
        return sp;
    }
}