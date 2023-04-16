//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "contracts/C.sol"; 
import "contracts/Tokens/X.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/Libraries/Interfaces/IX.sol";

    // ** INSTRUCTIONS **
    // This is the protocol owned liquidity contract, this holds LP tokens that back X
    // This contract receives at positive carry, just like the walletContract
    // This contract solves Beanstalk's reliance on a credit facility

contract protocolContract {

    address poolAddress;
    IERC20 public Xaddress;

    constructor(address _poolAddress, address _Xaddress) {
        poolAddress = _poolAddress;
        Xaddress = IERC20(_Xaddress);
    }

    // ABOVE PEG MAINTENANCE
    function deposit(uint256 Xp) public {
        // take amount that was minted to this contract and deposit as Curve LP
        uint256 lpTokensReceived = ICurvePool(poolAddress).add_liquidity([Xp, 0], 0); // not sure if _min_mint_amount is right
    }
    
    
    // BELOW PEG MAINTENANCE:
    function remove(uint256 db) public {
        // calc number of LP Tokens we need for removing db amount from pool
        uint256 lpTokensToWithdraw = ICurvePool(poolAddress).calc_token_amount([db, 0], false);
        // expected amount of X to receive for given amount of lp tokens
        uint256 coinsExpected = ICurvePool(poolAddress).calc_withdraw_one_coin(lpTokensToWithdraw, 0); // i=0 --> BEAN
        // Send this contract's lp tokens to Curve and get back X
        uint256 coinsReceived = ICurvePool(poolAddress).remove_liquidity_one_coin(lpTokensToWithdraw, 0, coinsExpected);
    }
    
    function burn() public {
        // amountToBurn may differ slightly from db due to slippage
        uint256 amountToBurn = Xaddress.balanceOf(address(this));

        if (amountToBurn > 0) {
            Xaddress.burn(amountToBurn);
        }
    }

}