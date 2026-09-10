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
