pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
library CallPrecompiledContract {

    // Only works for calls that return 32 bytes
    function callPrecompiledContract(address precompiledContractAddress, bytes memory encodedInputData, string memory errorMsg) internal returns (bytes32 result) {
        bool decodingSuccessful;
        assembly {
            // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let resultPointer := mload(0x40)
            // First 32 bytes are the length of the encode abi
            let inputDataPointer := add(encodedInputData, 0x20)
            let inputDataLength := mload(encodedInputData)

            // Invoke the precompiled contract with params https://solidity.readthedocs.io/en/v0.5.3/assembly.html
            // call(g, a, v, in, insize, out, outsize)
            // - g: send all the remaining gasleft
            // - a: verifier precompiled contract
            // - v: zero value
            // - in: pointer to input data
            // - insize: size of input data
            // - out: pointer to output data
            // - outsize: size of output data
            decodingSuccessful := call(not(0), precompiledContractAddress, 0, inputDataPointer, inputDataLength, resultPointer, 0x20)
            result := mload(resultPointer)
        }
        require(decodingSuccessful, errorMsg);
  }

}