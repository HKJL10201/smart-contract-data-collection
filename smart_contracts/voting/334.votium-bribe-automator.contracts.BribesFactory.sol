// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BribesManager.sol";

contract BribesFactory {
    
    event NewManager(address bribesManager, address token, uint gaugeIndex, uint tokensPerVote);

    function deployManager(address token, uint gaugeIndex, uint tokensPerVote) public returns (BribesManager) {
        BribesManager b = new BribesManager(token, gaugeIndex, tokensPerVote); 
        emit NewManager(address(b), token, gaugeIndex, tokensPerVote);
        return b;
    }
}