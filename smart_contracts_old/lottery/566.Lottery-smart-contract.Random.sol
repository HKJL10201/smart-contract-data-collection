//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Randomness {
    
    function number() internal view returns (uint) {
        uint random = uint(
            keccak256(
            abi.encodePacked
            (
                block.timestamp * 9999,
                msg.sender,
                block.number + 1
            )
        )
        );
        return random % 100;
    }
}
