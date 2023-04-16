// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Standards
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contracts
import "contracts/protocolContract.sol";
import "contracts/walletContract.sol";
import "contracts/deltaB.sol";
import "contracts/C.sol";

// Libraries
import "contracts/Libraries/LibBeanMetaCurve.sol";

// Interfaces
import "contracts/Libraries/Interfaces/IX.sol";

/*
    ** INSTRUCTIONS **
        1. Figure out Db (amount needed to burn or mint) - (from beanstalk) 
        2. Plp + Xp >= Wlp + Wh + (Db - Xp) --> plug inputs in and solve for Xp
        3. Db = Xp + Xw --> Then add Xp input to solve for Xw
        
        Db = from beanstalk
        Plp = LPtoken.balanceOf(protocolContract) - this looks good 
        Wlp = LPtoken.totalSupply() - LPtoken.balanceOf(protocolContract) - this as well
        Wh = X held NOT in pool --> X.totalSupply() - X.balanceOf(liquidityPoolContract)
        Xp = what we're solving for!
        Xw = what we're solving for!
*/

contract X is ERC20, ERC20Burnable, Ownable {

    constructor(address _deltaB, address _liquidtypoolcontract, address _protocolContract, address _walletContract, address _lpTokenAddress) ERC20("X Coin", "X") {
        address deltaB = _deltaB;  
        address liquidtypoolcontract = _liquidtypoolcontract; 
        address protocolContract = _protocolContract; 
        address walletContract = _walletContract;  
        address lpTokenAddress = _lpTokenAddress; // does this need to be IERC20?
    }
    
    // Inputs
    uint256 db;
    uint256 Plp;
    uint256 Wlp;
    uint256 Wh;

    // Outputs
    uint256 Xp;
    uint256 Xw;

    // Contracts
    address liquidtypoolcontract;
    // address protocolContract;
    // address walletContract;
    address lpTokenAddress;

    struct Pool {
        address pool;
        address[2] tokens;
        uint256[2] balances;
        uint256 price;
        uint256 liquidity;
        int256 deltaB;
        uint256 lpUsd;
        // uint256 lpBdv;/
    }
    
    // only this contract can mint positive carry, mints go to walletContract and protocolContract
    function mint(address to, uint256 amount) private {
        _mint(to, amount);
    }

    function updateFormula() internal returns (bool) {
    
        // TOTAL shortage or excess X in pool to mint or burn!
        int256 newBeans = LibBeanMetaCurve.getDeltaB();  
        db = uint256(newBeans);
        
        // Get share of LP
        Plp = IERC20(lpTokenAddress).balanceOf(protocolContract); // looks good, just need share of LP
        Wlp = IERC20(lpTokenAddress).totalSupply() - IERC20(lpTokenAddress).balanceOf(protocolContract); // looks good, just need share of LP
        Wh = totalSupply() - balanceOf(liquidtypoolcontract); // looks good, this is just the number of sell pressure X tokens out there

        // Calculate Plp + Xp >= Wlp + Wh + (Db - Xp)
        Xp = (Wlp + Wh + db - Plp) / 2; 
        Xw = db - Xp;

        return newBeans >= 0;
    }

    // Probably wouldn't make this public for future implementation (this is the Sunrise!)
    /*
        if above peg: 
            Mint() calculates the distribution of mints to protocol vs. wallets, and mints tokens to 1) protocol contract, which then deposits into LP as just USD.safe and gets LP tokens in return, 2) contract that represents wallet LPs
        if below peg:
            Burn() redeems protocol's LP tokens for USD.safe and burns USD.safe 
    */
    function rebalance() public {
        
        // update amounts and return if mint or burn
        bool mint_ = updateFormula(); 

        // update POL and Silo to rebalance amounts for latest deltaB
        if (mint_ == true) {

            // amount to mint to POL contract
            mint(protocolContract, Xp);
            // amount to mint to wallet/Silo contract
            mint(walletContract, Xw);
            
            // deposit into pool to get Curve LP tokens
            protocolContract.deposit(Xp);
            // deposit into pool to get Curve LP tokens
            walletContract.deposit(Xw);

        } else {
            
            // Withdraw the db amount of X from the Curve Pool
            protocolContract.remove(db);
            // Burn any X in protocolContract
            protocolContract.burn();
        }
    }
}
