// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   DeployMerkleAirdrop 
 * @author  LegendaryCode
 * @notice  Deploys the BagelToken and MerkleAirdrop contracts and funds the airdrop contract.
 * 
 * @dev     
 *          The deployment process:
 *          1. Deploys a new `BagelToken` contract.
 *          2. Deploys `MerkleAirdrop` with the configured Merkle root and token address.
 *          3. Mints the total amount required for the airdrop.
 *          4. Transfers the tokens to the `MerkleAirdrop` contract so claims can be fulfilled.
 */
contract DeployMerkleAirdrop is Script {

    /// @notice Merkle root used to verify eligible airdrop claims.
    bytes32 private s_merkleRoot = 0x474d994c58e37b12085fdb7bc6bbcd046cf1907b90de3b7fb083cf3636c8ebfb;

    /**
     * @notice Total number of tokens required to fund all airdrop claims.
     * @dev Four eligible addresses receive 25 tokens each.
     */
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;



    /**
     * @notice  Deploys and initializes the Merkle Airdrop system.
     * 
     * @dev 
     *      Deploys the `BagelToken` and `MerkleAirdrop` contracts, mints the required
     *      token supply, and transfers the airdrop allocation to the MerkleAirdrop
     *      contract.
     * 
     * @return airdrop The newly deployed MerkleAirdrop contract.
     * @return token The newly deployed BagelToken contract.
     */
    function deployMerkleAirdrop() public returns(MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
       
       // Deploy the ERC-20 token that will be distributed through the airdrop.
        BagelToken token = new BagelToken();

        // Deploy the airdrop contract with the Merkle root and token address.
        MerkleAirdrop airdrop = new MerkleAirdrop(s_merkleRoot, IERC20(address(token)));

        // Mint enough tokens to cover every eligible claim.
        token.mint(token.owner(), s_amountToTransfer);

        // Fund the airdrop contract so it can transfer tokens to successful claimants.
        token.transfer(address(airdrop), s_amountToTransfer);

        vm.stopBroadcast();

        return (airdrop, token);
    }


    /**
     * @notice Entry point used by Foundry to execute the deployment script.
     * @dev Returns the addresses of both deployed contracts.
     * @return airdrop The deployed MerkleAirdrop contract.
     * @return token The deployed BagelToken contract.
     */
    function run() external returns(MerkleAirdrop ,BagelToken) {
        return deployMerkleAirdrop();
    }
}