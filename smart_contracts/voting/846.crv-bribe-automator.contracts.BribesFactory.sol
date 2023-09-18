// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BribesManager.sol";

contract BribesFactory {
    
    event NewManager(address bribesManager, address token, address gauge, uint tokensPerVote);

    /// @dev Deploys a new BribesManager Contract
    /// @param token Address of the reward/incentive token
    /// @param gauge address of the curve gauge
    /// @param tokensPerVote number of tokens to add as incentives per vote
    function deployManager(address token, address gauge, uint tokensPerVote) public returns (BribesManager) {
        BribesManager b = new BribesManager(token, gauge, tokensPerVote); 
        emit NewManager(address(b), token, gauge, tokensPerVote);
        return b;
    }
}