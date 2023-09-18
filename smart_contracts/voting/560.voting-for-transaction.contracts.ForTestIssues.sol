// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Test {
    uint256 public x = 5;

    function changeTo24() external {
        x = 24;
    }

    function changeToWhatYouWant(uint256 newX) external {
        x = newX;
    }

    function changeToWhatYouWantWithArray(uint256[] calldata newX) external {
        x = newX[1];
    }

    function reentrancy() external payable returns (bool) {
        (bool success, ) = msg.sender.call(abi.encodeWithSignature("makeTransaction()"));
        return success;
    }
}