//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Contracts
import "contracts/C.sol"; 
import "contracts/Tokens/X.sol";
import "contracts/Tokens/CLAIM.sol";

    // ** INSTRUCTIONS **
    // This is the "Silo" equivalent, users "own" equity in the Curve LP Tokens held by this contract
    // CLAIM tokens represent a user's share of this contract's LP Token balance
    // Users can deposit and withdraw LP Tokens, when deposited they earn positive carry

contract walletContract {

    IERC20 public poolAddress;
    IERC20 public Xaddress;
    IERC20 public lpTokenAddress;
    IERC20 public CLAIMAddress;

    constructor(address _poolAddress, address _Xaddress, address _lpTokenAddress, address _CLAIMAddress) {
        poolAddress = IERC20(_poolAddress);
        Xaddress = IERC20(_Xaddress);
        lpTokenAddress = IERC20(_lpTokenAddress);
        CLAIMAddress = IERC20(_CLAIMAddress);
    }

    // USER: GET CLAIM TOKENS FOR DEPOSITED LP TOKENS
    function depositLP(address account, uint256 lpAmount) external {
        // check user's balance of Curve LP Tokens
        require(lpTokenAddress.balanceOf(account) >= lpAmount, "Insufficient balance of LP Tokens");
        // take lp tokens from user
        lpTokenAddress.transferFrom(account, address(this), lpAmount);
        // mint same amount of claim tokens with 1 lp token = 1 CLAIM
        CLAIMAddress.mint(account, lpAmount);
    }

    // USER: GET LP TOKENS FOR CLAIM
    function withdrawLP(address account, uint256 claimAmount) external {
        // check user's balance of CLAIM
        require(claimAmount <= CLAIMAddress.balanceOf(account), "Insufficent balance of CLAIM"); 

        uint256 claimTotalSupplyBeforeBurn = CLAIMAddress.totalSupply();
        
        CLAIMAddress.transferFrom(account, address(this), claimAmount);
        // burn from this contract first to avoid looping attack
        CLAIMAddress.burn(claimAmount);
        // send back user's share of LP tokens
        lpTokenAddress.transfer((CLAIMAddress.balanceOf(account) / claimTotalSupplyBeforeBurn) * lpTokenAddress.balanceOf(address(this))); // decimals get fucked up here?
    }

    // ABOVE PEG MAINTENANCE
    function deposit(uint256 Xp) public {
        // take amount that was minted to this contract and deposit, giving this contact more LP Tokens
        uint256 lpTokensReceived = ICurvePool(poolAddress).add_liquidity([Xp, 0], 0); // not sure if _min_mint_amount is right
    }
    
    // BELOW PEG MAINTENANCE:
    function remove(uint256 db) public {
        // now we get db which is excess X in pool, so now we need to withdraw this many X for our LP token

        // calc number of LP Tokens we need for removing "250" X from pool (250 = db)        
        uint256 lpTokensToWithdraw = ICurvePool(poolAddress).calc_token_amount([db, 0], false);
        // expected amount of X to receive for given amount of lp tokens
        uint256 coinsExpected = ICurvePool(poolAddress).calc_withdraw_one_coin(lpTokensToWithdraw, 0); // i=0 --> BEAN
        // remove LP Token amount and send X to this contract
        uint256 coinsReceived = ICurvePool(poolAddress).remove_liquidity_one_coin(lpTokensToWithdraw, 0, coinsExpected);
    }
    
    function burn() public {
        // amountToBurn may differ slightly from db due to slippage
        uint256 amountToBurn = X.balanceOf(address(this));

        if (amountToBurn > 0) {
            X.burn(amountToBurn);
        }
    }

}