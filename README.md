# Merkle Airdrop Smart Contract
A Solidity-based Merkle Airdrop system , that enables eligible users to claim ERC-20 tokens using Merkle proofs and EIP-712 Signatures. </br>
Build with `Solidity`, `Foundry`, `OpenZeppelin`, `Murky` and `Foundry DevOps`, the project demonstrates a gas-effecient approach to verifying a large whitelist on-chain without storing every eligible address in contract storage.



## Project Overview
The `Merkle Airdrop` is a soidity based token destribution system that allows ERC-20 tokens to be claimed 



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
