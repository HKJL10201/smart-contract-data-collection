// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IExternal {
    struct VoterData {
        string name;
        uint256 value;
    }
    function vote(VoterData[] calldata voteData, uint256 weight) external returns(bool);
    
}