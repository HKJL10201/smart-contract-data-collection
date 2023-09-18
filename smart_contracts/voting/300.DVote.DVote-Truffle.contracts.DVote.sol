// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DVote {
    mapping(uint8 => uint128) private votes;
    mapping(address => bool) private voted;

    function vote(uint8 x) public {
        address sender = msg.sender;

        if (!voted[sender]) {
            votes[x]++;
            voted[sender] = true;
        }
    }

    function get(uint8 x) public view returns (uint128) {
        return votes[x];
    }

    function getAll() public view returns (uint128[] memory) {
        uint128[] memory ret = new uint128[](3);

        for (uint8 i = 0; i < 3; ++i) {
            ret[i] = votes[i];
        }

        return ret;
    }
}