// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Standards
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ** INSTRUCTIONS **
// Used to keep track of equity in the Curve LP Tokens held by walletContract

contract CLAIM is ERC20, ERC20Burnable, Ownable {

    constructor() ERC20("CLAIM Coin", "CLAIM") {
    }
    
    // Make this only callable by walletContract
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
