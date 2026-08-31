// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { ScriptHelper } from "murky/script/common/ScriptHelper.sol"; // Contains ltrim64



/**
 * @author Legendarycode
 * @notice Generates Merkle tree leaves, the Merkle root, and proofs from a JSON input file.
 * @dev This script reads claim data from `script/target/input.json`, hashes each entry
 *      into a Merkle leaf, generates a proof for every leaf, and writes the resulting
 *      root, leaves, proofs, and original inputs to `script/target/output.json`. 
 * 
 *      The generated output can be consumed by the Merkle airdrop contract and its
 *      corresponding tests or deployment scripts.
 */

contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string;

    /// @dev  Murky Merkle tree instance used to generate the Merkle root and proofs.
    Merkle private m = new Merkle();

    /// @notice Path to the JSON file containing the input claim data.
    string private inputPath = "/script/target/input.json";

    /// @notice Path to the JSON file where generated Merkle data is written.
    string private outputPath = "/script/target/output.json";

    /// @notice Raw JSON contents loaded from the input file.
    string private elements = vm.readFile(string.concat(vm.projectRoot(), inputPath));

    /// @notice Data types defined for each value in the input JSON.
    string[] private types = elements.readStringArray(".types");

    /// @notice Number of claims contained in the input JSON.
    uint256 private count = elements.readUint(".count");

    /// @notice Merkle leaves generated from the input claims.
    bytes32[] private leafs = new bytes32[](count);

    /// @notice JSON-formatted input values for each claim.
    string[] private inputs = new string[](count);

    ///  @notice JSON-formatted output entries containing each claim's proof data.
    string[] private outputs = new string[](count);

    ///  @notice Complete JSON string written to the output file.
    string private output;


    /**
     * @notice  Builds the JSON path for a specific value in the input data.
     * @param i Index of the claim.
     * @param j Index of the value within the claim.
     * @return JSON path pointing to the requested value.
     */
    function getValuesByIndex(uint256 i, uint256 j) internal pure returns (string memory) {
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    }


    /**
     * @notice Creates a JSON object containing a claim's input values and Merkle proof.
     * @param _inputs JSON-formatted claim values.
     * @param _proof  JSON-formatted Merkle proof.
     * @param _root Merkle root associated with the tree.
     * @param _leaf Merkle leaf generated from the claim.
     * @return result JSON-formatted entry containing the claim and its verification data.
     */
    /// @dev Generate the JSON entries for the output file
    function generateJsonEntries(string memory _inputs, string memory _proof, string memory _root, string memory _leaf)
        internal
        pure
        returns (string memory)
    {
        string memory result = string.concat(
            "{",
            "\"inputs\":",
            _inputs,
            ",",
            "\"proof\":",
            _proof,
            ",",
            "\"root\":\"",
            _root,
            "\",",
            "\"leaf\":\"",
            _leaf,
            "\"",
            "}"
        );

        return result;
    }


    /**
     *  @notice Generates the Merkle tree and proof data from the input JSON file.
     *  @dev Each claim is ABI-encoded, hashed into a Merkle leaf, and added to the tree.
     *       A proof is then generated for every leaf and written to the output JSON file.
     */
    function run() public {
        console.log("Generating Merkle Proof for %s", inputPath);

        for (uint256 i = 0; i < count; ++i) {
            string[] memory input = new string[](types.length);
            bytes32[] memory data = new bytes32[](types.length);

            for (uint256 j = 0; j < types.length; ++j) {
                if (compareStrings(types[j], "address")) {
                    address value = elements.readAddress(getValuesByIndex(i, j));
                    
                    // Convert the address to bytes32 using its 160-bit representation.
                    data[j] = bytes32(uint256(uint160(value)));
                    input[j] = vm.toString(value);
                } else if (compareStrings(types[j], "uint")) {
                    uint256 value = vm.parseUint(elements.readString(getValuesByIndex(i, j)));
                    
                    // Store the numeric value as bytes32 for deterministic hashing.
                    data[j] = bytes32(value);
                    input[j] = vm.toString(value);
                }
            }

            // Hash the encoded claim twice to produce the Merkle leaf.
            leafs[i] = keccak256(bytes.concat(keccak256(ltrim64(abi.encode(data)))));

            // Preserve the original claim values for the generated output JSON.
            inputs[i] = stringArrayToString(input);
        }

        for (uint256 i = 0; i < count; ++i) {
            string memory proof = bytes32ArrayToString(m.getProof(leafs, i));
            string memory root = vm.toString(m.getRoot(leafs));
            string memory leaf = vm.toString(leafs[i]);
            string memory input = inputs[i];

            // Combine the claim and its Merkle verification data into one JSON object.
            outputs[i] = generateJsonEntries(input, proof, root, leaf);
        }

        output = stringArrayToArrayString(outputs);

        // Write the generated Merkle data to the output JSON file.
        vm.writeFile(string.concat(vm.projectRoot(), outputPath), output);

        console.log("DONE: The output is found at %s", outputPath);
    }
}