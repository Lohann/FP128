//SPDX-License-Identifier: MIT
/*
 * FP128 Smart Contract Library.
 * Author: Lohann Paterno Coutinho Ferreira <developer@lohann.dev>
 */
pragma solidity >= 0.5.5;

/**
 * Workaround for sharing FP128 constants with contracts
 * https://ethereum.stackexchange.com/questions/16082/solidity-accessing-a-library-constant-in-a-contract-that-imports-the-library
 */
contract FP128Constants {
    /**
     * Fixed value 1 in 128x128.
     */
    int256 constant internal M128_FIXED_ONE = 1 << 128;

    /**
     * Flags
     */
    uint8 constant internal M128_ROUND_UP                = 1;
    uint8 constant internal M128_IGNORE_DECIMAL_OVERFLOW = 1 << 1;
}

library FP128 {
    int256 constant private INT256_MAX = 2 ** 255 - 1;

    int256 constant private INT256_MIN = -2 ** 255;

    /**
     * Minimum value signed 128.128-bit fixed point number may have.
     */
    int256 constant private MIN_128x128 = -0x80000000000000000000000000000000;

    /**
     * Maximum value signed 128.128-bit fixed point number may have.
     */
    int256 constant private MAX_128x128 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int256 private constant MIN_64x64 = -0x8000000000000000;

    /**
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int256 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFF;

    /**
     * Fixed value 1 in 128x128.
     */
    int256 constant private M128_FIXED_ONE = 1 << 128;

    uint256 constant private BITS = 128;
    uint256 constant private BASE = 1 << BITS;
    uint256 constant private MASK = BASE - 1;

    /**
     * Flags
     */
    uint8 constant private M128_ROUND_UP = 1;
    uint8 constant private M128_IGNORE_DECIMAL_OVERFLOW = 1 << 1;

    /**
     * @notice This is 1 in the fixed point units used in this library.
     * @dev Test fixed1() equals 1 << 128
     */
    function fixed1() internal pure returns(int256) {
        return M128_FIXED_ONE;
    }

    /**
     * Convert signed 256-bit integer number into signed 128.128-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 128.128-bit fixed point number
     */
    function fromInt (int256 x) internal pure returns (int256) {
        require(x >= MIN_128x128, "Math128x128: Cannot convert int to 128x128, the value is too small");
        require(x <= MAX_128x128, "Math128x128: Cannot convert int to 128x128, the value is too big");
        return x << 128;
    }

    /**
     * Convert signed 128.128 fixed point number into signed 128-bit integer number
     * rounding down.
     *
     * @param x signed 128.128-bit fixed point number
     * @return signed 128-bit integer number
     */
    function toInt (int256 x) internal pure returns (int128) {
        return int128(x >> 128);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt (uint256 x) internal pure returns (int256) {
        require (x <= uint256(MAX_128x128), "Math128x128: Cannot convert uint to 128x128, the value is too big");
        return int256(x << 128);
    }

    /**
     * Convert signed 128.128 fixed point number into unsigned 128-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 128.128-bit fixed point number
     * @return unsigned 128-bit integer number
     */
    function toUInt (int256 x) internal pure returns (uint128) {
        require (x >= 0, "Math128x128: Cannot convert x to uint, the value must be zero or positive");
        return uint128(x >> 128);
    }

    /**
     * Calculate a + b.  Revert on overflow.
     *
     * @param a signed 128.128-bit fixed point number
     * @param b signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function add (int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "Math128x128: addition overflow");
        return c;
    }

    /**
     * Calculate a - b.  Revert on overflow.
     *
     * @param a signed 128.128-bit fixed point number
     * @param b signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function sub (int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "Math128x128: subtraction overflow");
        return c;
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * reference:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0-rc.1/contracts/math/SignedSafeMath.sol
     *
     * @param x signed 128.128-bit fixed point number
     * @param y signed 256-bit integer number
     * @return signed signed 128.128-bit fixed point number
     */
    function muli(int256 x, int256 y) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (x == 0) {
            return 0;
        }

        require(!(x == -1 && y == INT256_MIN), "Math128x128: multiplication overflow");

        int256 result = x * y;
        require(result / x == y, "Math128x128: multiplication overflow");

        return result;
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * This implementations was based in this article:
     * https://silentmatt.com/blog/2011/10/how-bigintegers-work-part-2-multiplication/
     * With some adjustments and optimizations for fixed 512bit result
     *
     * @param x unsigned 128.128-bit fixed point number
     * @param y unsigned 128.128-bit fixed point number
     * @param flags rouding and validation options
     * @return unsigned signed 128.128-bit fixed point number
     */
    function muluu(uint256 x, uint256 y, uint8 flags) internal pure returns (uint256) {
        uint256 rhi;
        uint256 rlo;
        {
            uint256 xhi = x >> BITS; // x integer bits
            uint256 xlo = x & MASK;  // x decimal bits
            uint256 yhi = y >> BITS; // y integer bits
            uint256 ylo = y & MASK;  // y decimal bits
            uint256 v1  = ylo * xlo;
            uint256 v2  = (v1 >> BITS) + yhi * xlo;
            uint256 v3  = (v2 &  MASK) + ylo * xhi;
            uint256 v4  = (v3 >> BITS) + ((v2 >> BITS) & MASK) + yhi * xhi;
            rhi = (v4 & MASK) + (((v4 >> BITS) &  MASK) << BITS); // result integer bits
            rlo = (v1 & MASK) + (( v3 &  MASK) << BITS);          // result decimal bits
        }

        require(rhi < uint256(MAX_128x128), "Math128x128: multiplication overflow");

        uint256 result;
        result  = (rhi & MASK) << BITS;
        result |= ((rlo >> BITS) & MASK);

        // Validate decimals overflow
        // x * y == 0 when x > 0 and y > 0
        if (flags & M128_IGNORE_DECIMAL_OVERFLOW == 0 && x > 0 && y > 0) {
            require(result > 0, "Math128x128: multiplication decimals overflow");
        }

        // Round up
        if (flags & M128_ROUND_UP > 0 && (rlo << BITS) > 0 && result < uint256(INT256_MAX)) {
            result += 1;
        }

        return result;
    }

    /**
     * Calculate x^2, where x is signed 128.128 fixed point number
     *
     * @param x signed 128.128-bit fixed point number
     * @return  signed 128.128-bit fixed point number
     */
    function pow2 (int256 x) internal pure returns (int256) {
        return mul(x, x);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bit fixed point number
     * @param y signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function mul (int256 x, int256 y) internal pure returns (int256) {
        return mul(x, y, 0x0);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bit fixed point number
     * @param y signed 128.128-bit fixed point number
     * @param flags rouding and validation options
     * @return signed 128.128-bit fixed point number
     */
    function mul (int256 x, int256 y, uint8 flags) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }

        bool negativeResult = false;
        if (x < 0) {
            x = abs(x);
            negativeResult = true;
        }
        if (y < 0) {
            y = abs(y);
            negativeResult = !negativeResult;
        }

        uint256 c = muluu(uint256(x), uint256(y), flags);
        int256 result = int256(c);
        require(c == uint256(result), "Math128x128: multiplication overflow");
        if (negativeResult) {
            result = neg(result);
        }
        return result;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x unsigned 128.128-bit fixed point number
     * @param y unsigned 128.128-bit fixed point number
     * @param flags rouding and validation options
     * @return unsigned 128.128-bit fixed point number
     */
    function divuu(uint256 x, uint256 y, uint8 flags) internal pure returns (uint256)  {
        require(y > 0, "Math128x128: Division by zero");

        if (x == 0) {
            return 0;
        }

        uint16 xShift = leadingZeros(x);
        uint16 yShift = trailingZeros(y);
        uint16 precision = xShift + yShift;

        // Limits minimum decimal precision to 64 bits
        require(precision >= 64, "Math128x128: division precision less than 64");

        x = x << xShift;
        y = y >> yShift;
        uint256 result = x / y;

        if (precision > 128) {
            result = result >> (precision - 128);
        } else {
            result = result << (128 - precision);
        }

        // Round up
        if (flags & M128_ROUND_UP > 0 && (x % y) > 0 && result < uint256(INT256_MAX)) {
            result += 1;
        }

        // Validate decimal overflow
        if (flags & M128_IGNORE_DECIMAL_OVERFLOW == 0) {
            require(result > 0, "Math128x128: division decimals overflow");
        }

        return result;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 128.128-bit fixed point number
     * @param y signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function div (int256 x, int256 y) internal pure returns (int256) {
        return div(x, y, 0x0);
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 128.128-bit fixed point number
     * @param y signed 128.128-bit fixed point number
     * @param flags rouding and validation options
     * @return signed 128.128-bit fixed point number
     */
    function div (int256 x, int256 y, uint8 flags) internal pure returns (int256) {
        // TODO: Doesn't fully support 128x128 yet
        bool negativeResult = false;
        if (x < 0) {
            x = abs(x);
            negativeResult = true;
        }
        if (y < 0) {
            y = abs(y);
            negativeResult = !negativeResult;
        }

        uint256 c = divuu(uint256(x), uint256(y), flags);
        int256 result = int256(c);
        require(c == uint256(result), "Math128x128: division overflow");
        if (negativeResult) {
            result = neg(result);
        }
        return result;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param a signed 128.128-bit fixed point number
     * @param b signed 256-bit integer number
     * @return signed 128.128-bit fixed point number
     */
    function divi(int256 a, int256 b) internal pure returns (int256) {
        return divi(a, b, 0x0);
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * reference:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0-rc.1/contracts/math/SignedSafeMath.sol#L32
     *
     * @param a signed 128.128-bit fixed point number
     * @param b signed 256-bit integer number
     * @return signed 128.128-bit fixed point number
     */
    function divi(int256 a, int256 b, uint8 flags) internal pure returns (int256) {
        require(b != 0, "Math128x128: division by zero");
        require(!(b == -1 && a == INT256_MIN), "Math128x128: division overflow");

        int256 c = a / b;

        // Round up
        if (flags & M128_ROUND_UP > 0 && (a % b) != 0 && c < INT256_MAX) {
            c += 1;
        }

        // Validate decimal overflow
        if (flags & M128_IGNORE_DECIMAL_OVERFLOW == 0 && a > 0) {
            require(c > 0, "Math128x128: division decimals overflow");
        }

        return c;
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function neg (int256 x) internal pure returns (int256) {
        require (x != -1 << 255, "Math128x128: negation overflow");
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function abs (int256 x) internal pure returns (int256) {
        require (x != -1 << 255, "Math128x128: absolute overflow");
        return x < 0 ? -x : x;
    }

    /**
     * Round up |x|.  Revert on overflow.
     *
     * @param x signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function ceil(int256 x) internal pure returns (int256) {
        int256 decimal = x << 128;
        if (decimal != 0) {
            require (x < (1 << 254), "Math128x128: ceil overflow");
            return ((x >> 128) + 1) << 128;
        }
        return x;
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 128.128-bit fixed point number
     * @return signed 128.128-bit fixed point number
     */
    function sqrt (int256 x) internal pure returns (int256) {
        // TODO: This method only have 64bit decimal precision
        require (x >= 0);
        uint256 result = sqrtu(uint256(x));
        require(result > 0, "Math128x128: sqrt precision overflow");
        result = result << 64;
        return int256(result);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param n unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 n) internal pure returns (uint256) {
        uint256 x = n;
        uint256 y = 1;
        while (x > y) {
            x = (x + y) >> 1;
            y = n / x;
        }
        return x;
    }

    // Returns the number of leading zeros in the binary representation
    function leadingZeros(uint256 x) internal pure returns (uint16) {
        if (x == 0) {
            return 256;
        }
        uint256 n = 256;
        uint256 y;
        y = x >>128; if (y > 0) {n -=128; x = y;}
        y = x >> 64; if (y > 0) {n -= 64; x = y;}
        y = x >> 32; if (y > 0) {n -= 32; x = y;}
        y = x >> 16; if (y > 0) {n -= 16; x = y;}
        y = x >>  8; if (y > 0) {n -=  8; x = y;}
        y = x >>  4; if (y > 0) {n -=  4; x = y;}
        y = x >>  2; if (y > 0) {n -=  2; x = y;}
        y = x >>  1; if (y > 0) {n -=  1; x = y;}
        return uint8(n-1);
    }

    // Returns the number of trailing zeros in the binary representation
    function trailingZeros(uint256 x) internal pure returns (uint16) {
        // TODO: Optmize this code based on this article:
        // http://graphics.stanford.edu/~seander/bithacks.html#IntegerLogObvious
        uint16 n = 256;
        x = x & (~x + 1);
        if (x > 0) n--;
        if (x & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF > 0) n -= 128;
        if (x & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF > 0) n -= 64;
        if (x & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF > 0) n -= 32;
        if (x & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF > 0) n -= 16;
        if (x & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF > 0) n -= 8;
        if (x & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F > 0) n -= 4;
        if (x & 0x3333333333333333333333333333333333333333333333333333333333333333 > 0) n -= 2;
        if (x & 0x5555555555555555555555555555555555555555555555555555555555555555 > 0) n -= 1;
        return n;
    }
}
