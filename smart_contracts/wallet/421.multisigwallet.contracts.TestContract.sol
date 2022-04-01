// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Test contract.
/// @author Esteban Hugo Somma.
/// 
/// @notice Helper contract to test the multisig wallet. It have a function to 
/// execut and another function to get de bytes of this function to be sended as 
/// a tranaction data.
contract TestContract {
    uint public value;

    // Function to test.
    function callMe(uint valueToAdd) external {
        value += valueToAdd;
    }

    // Helper function to get de bytes of the callMe() function.
    function getData() external pure returns (bytes memory) {
        return abi.encodeWithSignature("callMe(uint256)", 10);
    }
}
