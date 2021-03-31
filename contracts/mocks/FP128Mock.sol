//SPDX-License-Identifier: MIT
/*
 * FP128 Smart Contract Library.
 * Author: Lohann Paterno Coutinho Ferreira <developer@lohann.dev>
 */
pragma solidity >= 0.5.5;

import "../FP128.sol";

contract FP128Mock {
    function fixed1() public pure returns(int256) {
        return FP128.fixed1();
    }

    function fromInt (int256 x) public pure returns (int256) {
        return FP128.fromInt(x);
    }

    function toInt (int256 x) public pure returns (int128) {
        return FP128.toInt(x);
    }

    function fromUInt (uint256 x) public pure returns (int256) {
        return FP128.fromUInt(x);
    }

    function toUInt (int256 x) public pure returns (uint128) {
        return FP128.toUInt(x);
    }

    function add (int256 a, int256 b) public pure returns (int256) {
        return FP128.add(a, b);
    }

    function sub (int256 a, int256 b) public pure returns (int256) {
        return FP128.sub(a, b);
    }

    function muli(int256 x, int256 y) public pure returns (int256) {
        return FP128.muli(x, y);
    }

    function muluu(uint256 x, uint256 y, uint8 flags) public pure returns (uint256) {
        return FP128.muluu(x, y, flags);
    }

    function pow2 (int256 x) public pure returns (int256) {
        return FP128.pow2(x);
    }

    function mul (int256 x, int256 y) public pure returns (int256) {
        return FP128.mul(x, y);
    }

    function mul (int256 x, int256 y, uint8 flags) public pure returns (int256) {
        return FP128.mul(x, y, flags);
    }

    function divuu(uint256 x, uint256 y, uint8 flags) public pure returns (uint256)  {
        return FP128.divuu(x, y, flags);
    }

    function div (int256 x, int256 y) public pure returns (int256) {
        return FP128.div(x, y);
    }

    function div (int256 x, int256 y, uint8 flags) public pure returns (int256) {
        return FP128.div(x, y, flags);
    }

    function divi(int256 a, int256 b) public pure returns (int256) {
        return FP128.divi(a, b);
    }

    function divi(int256 a, int256 b, uint8 flags) public pure returns (int256) {
        return FP128.divi(a, b, flags);
    }

    function neg (int256 x) public pure returns (int256) {
        return FP128.neg(x);
    }


    function abs (int256 x) public pure returns (int256) {
        return FP128.abs(x);
    }

    function ceil(int256 x) public pure returns (int256) {
        return FP128.ceil(x);
    }

    function sqrt (int256 x) public pure returns (int256) {
        return FP128.sqrt(x);
    }

    function sqrtu(uint256 n) public pure returns (uint256) {
        return FP128.sqrtu(n);
    }

    function leadingZeros(uint256 x) public pure returns (uint16) {
        return FP128.leadingZeros(x);
    }

    function trailingZeros(uint256 x) public pure returns (uint16) {
        return FP128.trailingZeros(x);
    }
}
