//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "contracts/deltaB.sol";

contract BeanstalkPrice is deltaB {

    struct Prices {
        uint256 price;
        uint256 liquidity;
        int deltaB;
        P.Pool[] ps;
    }

    function price() external view returns (Prices memory p) {
        p.ps = new P.Pool[](1);
        p.ps[0] = getCurve();

        for (uint256 i = 0; i < p.ps.length; i++) {
            p.price += p.ps[i].price * p.ps[i].liquidity;
            p.liquidity += p.ps[i].liquidity;
            p.deltaB += p.ps[i].deltaB;
        }
        p.price /= p.liquidity;
    }
}