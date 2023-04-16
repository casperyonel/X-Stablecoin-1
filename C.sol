//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "contracts/Libraries/Interfaces/ICurve.sol";

// ** INSTRUCTIONS ** 
// Holds addresses of 3CRV pool contract and X:3CRV contract

library C {

    address private constant CURVE_3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; // 3CRV
    address private constant CURVE_BEAN_METAPOOL = 0xc9C32cd16Bf7eFB85Ff14e0c8603cc90F6F2eE49; // X:3CRV

    function curve3Pool() public pure returns (I3Curve) {
        return I3Curve(CURVE_3_POOL);
    }

    function curveMetapoolAddress() internal pure returns (address) {
        return CURVE_BEAN_METAPOOL;
    }

    function curveMetapool() internal pure returns (ICurvePool) {
        return ICurvePool(CURVE_BEAN_METAPOOL);
    }
}