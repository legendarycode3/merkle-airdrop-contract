# Merkle Airdrop Smart Contract
A Solidity-based Merkle Airdrop system , that enables eligible users to claim ERC-20 tokens using Merkle proofs and EIP-712 Signatures. </br>
Build with `Solidity`, `Foundry`, `OpenZeppelin`, `Murky` and `Foundry DevOps`, the project demonstrates a gas-effecient approach to verifying a large whitelist on-chain without storing every eligible address in contract storage.



## Project Overview
The `Merkle Airdrop` is a soidity based token destribution system that allows ERC-20 tokens to be claimed by a predefined set of eligible addresses. </br>
Instead of storing the complete waitlist and individual token allocations directly onchain, the project uses a `Merkle tree` to effectively represent and verify claim eligibility. </br>
The resulting `Merkle root` is stored in the `MerkleAirdrop` contract , while users provide a merkle proof to cryptographically prove that their address and allocated token amount are included in the distribution. </br>
The claim process is secured with `EIP-712 typed structure data` and and `ECDSA signature`, allowing the contract to verify that the provided claim  authorization was signed by the eligible account.  </br>
Once all verification checks pass, the contract marks the account as claimed, emits a `Claim` event , and securely transfers the allocated ERC-20 tokens to the recipient using openzeppelin's `SafeERC20` implementation. </br>
The project also includes Foundry scripts for generating Merkle tree data, deploying and funding the airdrop contracts, and interacting with the deployed airdrop system.  </br>

**Core Claim Flow** 

```shell

Whitelist Data
     │
     ▼
GenerateInput.s.sol
     │
     ▼
input.json
     │
     ▼
MakeMerkle.s.sol
     │
     ├── Merkle Leaves
     ├── Merkle Proofs
     └── Merkle Root
     │
     ▼
DeployMerkleAirdrop.s.sol
     │
     ├── Deploy BagelToken
     ├── Deploy MerkleAirdrop
     └── Fund Airdrop Contract
     │
     ▼
User Claim
     │
     ├── EIP-712 Signature
     ├── Merkle Proof
     └── Claim Amount
     │
     ▼
MerkleAirdrop.claim()
     │
     ▼
ERC-20 Tokens Transferred
```



## Features
* **Merkle Tree-Based Eligibility Verification:** Uses a `Merkle tree` to represent eligible addresses and their token allocations without storing the complete whitelist directly on-chain.
* **Gas-Effecient On-Chain Verification:** Stores only the `Merkle root` on-chain while users provide their individual Merkle proofs during claims, significantly reducing on-chain storage requirements.
* **ERC-20 Token Distribution:** Distributes ERC-20 tokens to eligible users based on the allocation encoded in their Merkle leaf.
* **ERC-712 Typed-Data Signing:** Uses `ERC-712 structure data` to create a standardized and domain-separated 
 message for claim authoriization.
* **ECDSA Signature Verification:** Recovers the signer from the provided signature and verifies that it matches the eligible claiming account.
* **Duplicate Claim Potection:** Tracks successful claims using a mapping to ensure that an eligble address can not claim thesame allocation more than once.
* **Secure ERC-20 Transfers:** Uses Openzeppelin's `SafeERC20` implementation to safely transfer tokens to successful claimants.
* **Common Errors:** Uses Solidity `custom errors` instead of traditional revert strings to provide clearer failure conditions while reducing revert data overhead.
* **Immutable Configuration:** Stores the `Merkle root` and airdrop token s immutable values, preventing them from been changed after deployment.
* **Third-Party Gas Player Support:** Allows an account other than the eligible user to submit the claim transaction and pay the gas while the allocated tokens are sent directly to the eligible account.
* **Automated Merkle Tee Generation:** Provides foundry scripts that generates merkle leaves, proofs, and the Merkle root from predefined claim data.
* **JSON-Based Claim Data:** Generates and store Merkle input and output data in JSON file, making claim allocations  and proofs easier to inspect and manage.
* **Automated Contract Deployment:** Includes Foundry deployment scripts for deploying the ERC-20 token , Merkle Airdrop contract and funding the airdrop with the required token allocations.
* **Foundry-Based Testing:** Includes Automated Foundry tests, covering the core claim flow, including EIP-712 signing. Merkle Proof Verification, Token distibution and third party gas payment.
* **zksync-Aware Testing:** Includes chain-aware deployment logic that supports testing the airdrop flow across standard EVM environments and zksync-compatible environments.
* **Open-Zeppelin Security Primitives:** Leverages battle-tested Openzeppelin implementations for `ERC-20 , Ownable, MerkleProof,  EIP-712, ECDSA, SafeERC20` functionality.



## Smart Contracts
**MerkleAirdrop.sol - Airdrop Distribution and Claim Verification** 
The core contract responsible for claim eligibiity, validating EIP-712 signatures, preventing duplicate  claims, and distributing ERC-20 tokens to eligible accounts. 
The contract combines `Merkle proof verification,  EIP-712 typed-data hashing, and ECDSA signature recovery` 



## Security Consideration
* **Merkle Root Integrity:** The Merkle root acts as the cryptographic source of truth for eligible addresses and their token allocations. An incorrect or malicious root could result in invalid eligibility rules, so the root should be generated from trusted claim data and independently verified before deployment.
* **Merkle Proof Verification:** Each claim must include a valid Merkle proof that connects the clainment's address and allocated amount to be stored Merkle root. This prevents users from modifying their claim amount or claiming  an allocation that is not included in the configured distribution.
* **:EIP-712 Signature Verification** Claims use EIP-712 `typed-data hashing` to produce a domain-separated claim message. The contract uses OpenZeppelin's `ECDSA` implementation to recover the signer and verifies that the recovered address matches the supplied claiming account. 
* **Claimant Signature Requirement:** The signature verification ensures that the eligible account controls the private key associated with the address included in the claim. A third-party may submit the transaction and pay the gas, but they cannot substitute another account's signature for the eligible claiment.
* **Double-Claim Protection:** The contract maintains a `_hasClaimed` mapping to track successfu claims. Once an account has completed a valid claim, subsequent attempts from thesame account are rejected with `MerkleAirdrop__AlreadyClaimed`.
* **Safe ERC-20 Transfers:** Token distributions use OpenZeppelin's `SafeERC20` library to provide safer ERC-20 transfer handling and compatibility with tokens that may not strictly follow the expected ERC-20  return-value behavior.
* **Immutable Airdrop Configuration:** The Merkle root and airdrop token are stored as immutable values and cannot be modified after deployment. This prevent the eligibility configuration or token address from being changed after the contract has been deployed.
* **Checks Before State Changes:** The `claim()` function performs its validation checks before making the account as claimed or transfering tokens. The contact verifies the claim status, signature, and Merkle proof before executing the successful claim state changes.
* **Claim Amount Integrity:** The claimed token amount is included in the Merkle leaf together with the claiment's address. A user therefore cannot simply request a larger allocation without possessing a valid merkle proof coressponding to that address and amount.
* **Reply Protection Through Claim Tracking:** Even when a valid signature and Merkle  proof are reused, the `s_hasClaimed` mapping prevents thesame account from successfully claiming claiming multiple times from thesame deployed airdrop contract.
* **EIP-712 Domain Separation:** The contract uses an EIP-712 domain with a name `MerkleAirdrop` , helping ensure that signed claim messages are associated with intended signing domain , rather than being treated as generic signature.
* **Trusted Off-Chain Merkle Generation:** The security of the distribution depends partly on the correctness of the off-chain Merkle tree generation process. The generated leaves, proofs, allocations, and final root should be verified before the root is deployed.
* **Airdrop Funding Requirement:** Thecontract must holda sufficient balance of the configured ERC-20 token to fulfil the valid claims. If the contract is underfunded , otherwise valid claims can fail when the token transfer is attempted.
* **Trusted Off-Chain Merkle Generation**: The security of the distribution depends partly on the correctness of the off-chain Merkle tree generation process. The generated leaves , proofs, allocations, and final root should be verified before the root is deployed.
* **Secure Development Credentials**: Development scripts may contain test addresses , signatures and configuration values. Production deployment should use secure key management and must never expose private keys or sensitive credentials in source code or version control.
* **Production Security Review:** Although the implementation uses established Openzeppelin cryptograhic and token-handling primitives,  the contract should undergo appropiate testing and an independent security review before being used to distribute valuable assets in production.



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
