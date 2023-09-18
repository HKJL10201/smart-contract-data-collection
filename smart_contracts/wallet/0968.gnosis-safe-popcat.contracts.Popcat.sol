// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Popcat {
    string champion;

    function updateChampion(string calldata _champion) external {
        champion = _champion;
    }

    function getChampion() external view returns (string memory) {
        return champion;
    }
}
