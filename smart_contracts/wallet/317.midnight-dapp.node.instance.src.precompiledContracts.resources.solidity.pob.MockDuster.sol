pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./IDuster.sol";

contract MockDuster is IDuster {

    function toDust(uint8, uint tokens) override view external returns (uint burned, address recipient) {
        return (tokens, msg.sender);
    }

    function toDustFrom(uint8, address from, uint256 tokens) override pure external returns (uint burned, address recipient) {
        return  (tokens, from);
    }

}