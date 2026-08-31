// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";



/**
 * @title    BagelToken - A basic mintable ERC20 token  
 * @author   LegendaryCode
 * @notice   This contract is used for testing mintable ERC20 token functionality
 * @dev      Inherits standard ERC20 and Ownable behavior from OpenZeppelin
 */

contract BagelToken is ERC20, Ownable {

    /**
     * @notice Initializes the token name, symbol, and sets the contract deployer as the owner
     * @dev Passes parameters to the inherited ERC20 and Ownable constructors
     */
    constructor() 
        ERC20("Bagel", "BAGEL") 
        Ownable(msg.sender)     //msg.sender is explicitly set as the initial owner 
    {} 


    /**
     *  @notice Mints new BAGEL tokens to a specified address
     *  @dev Only executable by the contract owner via the onlyOwner modifier
     *  @param to The wallet or contract address that will receive the minted tokens
     *  @param amount The quantity of tokens to mint (expressed in wei)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}