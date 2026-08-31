// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";




/**      
 * @author LegendaryCode
 * @notice Foundry script for claiming a Merkle-based token airdrop.
 * @dev This script:
 *      1. Finds the most recently deployed `MerkleAirdrop` contract on the current chain.
 *      2. Splits the ECDSA signature into its `v`, `r`, and `s` components.
 *      3. Submits the claim using the recipient address, claim amount, Merkle proof, and 
 *         signature.
 *      The claim data in this script is intended for local/development testing.
 */
contract  ClaimAirdrop is Script {
        
    /// @notice Address eligible to receive the airdrop.
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @notice Amount of tokens to claim, denominated in the token's smallest unit.
    uint256 CLAIMING_AMOUNT  = 25 *  1e18;

    /// @notice First Merkle proof element used to verify the claim.
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;

    /// @notice Second Merkle proof element used to verify the claim.
    bytes32 PROOF_TWO = 0x46f4c7c1c21e8a90c03949beda51d2d02d1ec75b55dd97a999d3edbafa5a1e2f; 

    /// @notice Merkle proof used to verify the claiming address and amount.
    bytes32[] proof = [PROOF_ONE , PROOF_TWO];

 
    /// @notice ECDSA signature authorizing the airdrop claim.
    bytes private SIGNATURE = hex"fbd2270e6f23fb5fe9248480c0f4be8a4e9bd77c3ad0b1333cc60b5debc511602a2a06c24085d8d7c038bad84edc53664c8ce0346caeaa3570afec0e61144dc11c";
   
    /// @notice Thrown when the provided signature is not exactly 65 bytes.
    error __CliamAirdropScript_InvalidSignatureLength();
    

    /**
     * @notice Submits a Merkle airdrop claim to the specified contract.
     * @dev The signature is split into its ECDSA components before being passed
     *      to the `MerkleAirdrop.claim()` function.
     * @param airdrop Address of the deployed MerkleAirdrop contract.
    */
    function claimAirdrop(address airdrop) public {

        vm.startBroadcast();

        // Decompose the 65-byte ECDSA signature into v, r, and s.
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        
        // Submit the claim with the recipient, amount, Merkle proof, and signature.
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);

        vm.stopBroadcast();
    }



    /**
     * @notice Splits a standard 65-byte ECDSA signature into its components.
     * 
     * @dev
     *      A standard Ethereum ECDSA signature is encoded as:
     *      - `r`: 32 bytes
     *      - `s`: 32 bytes
     *      - `v`: 1 byte
     * 
     *      Inline assembly is used to efficiently read each component directly 
     *      from the signature's memory representation.
     * 
     * @param sig The 65-byte encoded ECDSA signature.
     * @return v Recovery identifier used for ECDSA signature recovery.
     * @return r First 32-byte component of the signature.
     * @return s Second 32-byte component of the signature.
     */
    function splitSignature(bytes memory sig ) public pure returns(uint8 v, bytes32 r, bytes32 s) {
        
        if (sig.length != 65 ) {
            revert __CliamAirdropScript_InvalidSignatureLength();
        }

        
        assembly {
            // Skip the first 32 bytes containing the dynamic bytes length.
            // Read the next 32 bytes as `r`.
            r := mload(add(sig, 32))

            // Read the following 32 bytes as `s`.
            s := mload(add(sig, 64))

            // Read the first byte of the final 32-byte word as `v`.
            v := byte(0, mload(add(sig, 96)))
        }
    }



    /**
     * @notice Finds the latest MerkleAirdrop deployment and executes the claim.
     * @dev
     *      `DevOpsTools` retrieves the most recently deployed contract address
     *      for the current chain ID, allowing the script to work across deployments
     *       without manually specifying the contract address.
     */
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);

        claimAirdrop(mostRecentlyDeployed);
    }
}