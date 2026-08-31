// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { IERC20, SafeERC20 } from  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract MerkleAirdrop is EIP712  {

    using SafeERC20 for IERC20;


     /*//////////////////////////////////////////////////////////////
                              ERRORS 
    //////////////////////////////////////////////////////////////*/ 
    /// @notice Thrown when the provided Merkle proof is invalid or does not match the root.
    error MerkleAirdrop__InvalidProof();

    /// @notice Thrown when the account has already claimed their airdrop allocation.
    error MerkleAirdrop__AlreadyClaimed();

    /// @notice Thrown when the provided cryptographic signature is invalid or forged.
    error MerkleAirdrop__InvalidSignature();



     /*//////////////////////////////////////////////////////////////
                              STATE VARIABLES 
    //////////////////////////////////////////////////////////////*/ 

    /// @notice List of all addresses that have successfully claimed the airdrop.
    address[] claimers;

    /// @notice The Merkle root used to verify airdrop eligibility.
    bytes32 private immutable i_merkleRoot;

    /// @notice The ERC20 token distributed through this airdrop contract.
    IERC20 private immutable i_airdropToken;

    /// @notice Tracks whether a specific address has already claimed its tokens.
    mapping(address claimer => bool claimed) private s_hasClaimed; 

    /// @notice Typehash for EIP-712 typed structured data signing of claims.
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");



     /*//////////////////////////////////////////////////////////////
                              STRUCT 
    //////////////////////////////////////////////////////////////*/ 
    
    /// @notice Represents a single user's allocation for an airdrop claim. 
    struct AirdropClaim{
        // The Ethereum address eligible to claim tokens
        address account; 

        // The exact token amount (in wei) allocated to the account
        uint256 amount;
    }



    /*//////////////////////////////////////////////////////////////
                              EVENTS 
    //////////////////////////////////////////////////////////////*/ 
    /**
     * @notice Emitted when a user successfully withdraws or claims tokens.
     * @dev    Tracked by off-chain indexers to update user balances.
     * @param account   The address of the user who triggered the claim.
     * @param amount    amount The total number of tokens transferred to the account.
     */
    event Claim(address account, uint256 amount);



     /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR 
    //////////////////////////////////////////////////////////////*/ 
    /**
     * @notice Initializes the contract with the Merkle root and the distribution token
     * @dev Sets immutable variables to save gas during future claim verifications
     * @param merkleRoot    The 32-byte cryptographic root containing the eligible whitelist *                      accounts
     * @param airdropToken  The ERC20 token contract address that will be distributed
     */
    constructor( bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        // Assign the cryptographic root for verification
        i_merkleRoot = merkleRoot;

        // Assign the token contract address to be used for claims
        i_airdropToken = airdropToken;
    }



     /*//////////////////////////////////////////////////////////////
                             EXTERNAL / PUBLIC FUNCTIONS 
    //////////////////////////////////////////////////////////////*/ 

    /**
     * @notice Allows a user to claim their airdrop token allocation.
     * @dev Verifies that the user has not claimed yet, checks the ECDSA signature validity, 
     * and validates the Merkle proof against the stored root before transferring tokens.
     * @param account The address of the user claiming the airdrop.
     * @param amount The amount of tokens the user is eligible to claim.
     * @param merkleProof The Merkle proof array proving the inclusion of the account and amount.
     * @param v The recovery byte of the cryptographic signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        
        // Check if the user has already claimed their tokens
        if(s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Verify that the signature matches the account and message hash
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature(); 
        }

        // Recreate the leaf node hash matching the off-chain Merkle tree generation
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // Validate the leaf against the Merkle root using OpenZeppelin's MerkleProof
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        // Mark the account as claimed to prevent re-entrancy or double claims
        s_hasClaimed[account] = true; 

        // Emit the claim event for indexing and tracking
        emit Claim(account, amount);

        // Transfer the airdrop tokens safely to the recipient
        i_airdropToken.safeTransfer(account, amount);
    }


    /**
     * @notice Hashes an airdrop claim according to the EIP-712 standard.
     * @dev Combines the type hash, struct data, and domain separator via _hashTypedDataV4.
     * @param account The address of the user eligible to claim the tokens.
     * @param amount The total number of tokens allocated to the user.
     * @return The EIP-712 compliant 32-byte hash to be verified against a signature.
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        
        // Encode struct data with its typehash and pass it to the EIP-712 helper
        return _hashTypedDataV4(
            keccak256(
                abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))
            )
        );
    } 




     /*//////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS 
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Verifies if a cryptographic signature matches the expected signer account
     * @dev Utilizes OpenZeppelin's ECDSA.tryRecover to safely extract the signer address without *      reverting
     * @param account   The expected Ethereum address that signed the message 
     * @param digest    The 32-byte Keccak-256 hash of the signed message data
     * @param v         The recovery byte of the signature
     * @param r         The first 32 bytes of the ECDSA signature
     * @param s         The second 32 bytes of the ECDSA signature
     * @return bool True if the recovered address matches the provided account, false otherwise
     */
    function _isValidSignature(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
       // Recover the signer address using the digest and the v, r, s signature components
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);

        // Compare the recovered signer address against the expected account and return the result
        return actualSigner ==  account;

    }




     /*//////////////////////////////////////////////////////////////
                              GETTER (view) FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the cryptographic Merkle root used for airdrop verification
     * @dev Returns a 32-byte hash stored as an immutable variable
     * @return The bytes32 Merkle root hash
     */
    function getMerkleRoot() external view returns(bytes32) {

        // Returns the pre-calculated tree root for whitelist validation
        return i_merkleRoot;
    }

    
    /**
     * @notice Gets the address of the ERC20 token distributed in this airdrop
     * @dev Returns the contract instance conforming to the IERC20 interface
     * @return The IERC20 token contract interface
     */
    function getAirdropTokens() external view returns(IERC20) {
        
        // Returns the immutable token contract reference
        return i_airdropToken;
    }


}