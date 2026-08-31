// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";

import { ZkSyncChainChecker } from "foundry-devops/src/ZkSyncChainChecker.sol"; 
import { DeployMerkleAirdrop } from "../script/DeployMerkleAirdrop.s.sol";



/**
 * @title  MerkleAidropTest
 * @author LegendaryCode
 * @notice Test suite for the MerkleAirdrop contract.
 * 
 * @dev
 *      Verifies that an eligible user can successfully claim their allocated
 *      tokens using a valid Merkle proof and ECDSA signature.
 * 
 *      The test supports different deployment environments:
 *      - Standard EVM chains: deploys the contracts using DeployMerkleAirdrop.
 *      - zkSync: deploys the contracts directly because the deployment script 
 *          is not used in the same way on zkSync.
 * 
 *      The test also verifies that a third-party account can pay the gas for
 *      a user's claim while the tokens are still transferred to the user.
 */
contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    
    MerkleAirdrop public airdrop;

    /// @notice ERC-20 token distributed by the MerkleAirdrop contract.
    BagelToken public token;

    /// @notice Merkle root used by the airdrop contract to verify claims.
    bytes32 public ROOT =  0x474d994c58e37b12085fdb7bc6bbcd046cf1907b90de3b7fb083cf3636c8ebfb;
    
    /// @notice Amount of tokens an eligible user is entitled to claim.
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;

    /// @notice Total number of tokens required to fund the four eligible claims.
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;


    /// @notice First element of the user's Merkle proof.
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;

    /// @notice Second element of the user's Merkle proof.
    bytes32 proofTwo = 0x46f4c7c1c21e8a90c03949beda51d2d02d1ec75b55dd97a999d3edbafa5a1e2f;

    /// @notice Merkle proof used to prove the user's eligibility.
    bytes32[] public PROOF = [
        proofOne, 
        proofTwo
    ]; 

    ///  @notice Address of the user receiving the airdrop.
    address user;

    ///  @notice Private key used to generate the user's ECDSA signature.
    uint256 userPrivKey; 

    ///  @notice Address that submits the claim transaction and pays the gas.
    address public gasPayer;
    

    
    /**
     * @notice Deploys and funds the Merkle Airdrop system before each test.
     * 
     * @dev
     *      Uses the deployment script on standard EVM chains and direct contract
     *      deployment on zkSync. A test user and separate gas payer are then created.
     */
    function setUp() public {

        if(!isZkSyncChain()){

            // Use the deployment script on standard EVM-compatible chains.
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token ) = deployer.deployMerkleAirdrop();
        }else {
            // Deploy directly on zkSync because the deployment script
            // follows a different execution path on that network.
            token = new BagelToken();
            airdrop = new MerkleAirdrop(ROOT, token);

            // Mint the required airdrop allocation and fund the contract.
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }

        // Create a deterministic test user and retrieve its private key
        // for signing the claim authorization.
        (user, userPrivKey)  = makeAddrAndKey("user");

        // Create a separate account that will submit the transaction
        // and pay the gas on behalf of the user.
        gasPayer = makeAddr("gasPayer");
        //
    }



    /**
     * @notice Verifies that an eligible user can successfully claim their tokens.
     * @dev 
     *      The Test:
     *       1. Records the user's initial token balance.
     *       2. Generates the message hash required by the airdrop contract.
     *       3. Signs the message using the user's private key.
     *       4. Has a separate gas payer submit the claim transaction.
     *       5. Verifies that the user's balance increased by the expected amount.
     */
    function testUsersCanClaim() public {
       // Record the user's token balance before claiming.
       uint256 startingBalance = token.balanceOf(user);

       // Generate the EIP-712-style message digest used for claim authorization.
       bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

       //    vm.prank(user); 
       // Sign the claim authorization with the user's private key.
       (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

       // Execute the claim from the gas payer's address.
       // The user remains the beneficiary of the claimed tokens.
       vm.prank(gasPayer);
       airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

       // Record the user's token balance after the claim.
       uint256 endingBalance = token.balanceOf(user);

       console.log("Ending Balance:", endingBalance); 

        // Verify that the user received exactly the amount allocated by the airdrop.
       assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}