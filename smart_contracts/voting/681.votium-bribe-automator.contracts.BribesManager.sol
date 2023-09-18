// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/token/IERC20.sol";
import "./library/BribesLogic.sol";

contract BribesManager {
    address immutable TOKEN;
    uint immutable GAUGE_INDEX;
    uint immutable TOKENS_PER_VOTE;
    bytes32 _lastProposal;
    address constant VOTIUM_BRIBE = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;

    /// @param token Address of the reward/incentive token
    /// @param gaugeIndex index of the gauge in the voting proposal choices
    /// @param tokensPerVote number of tokens to add as incentives per vote
    constructor(address token, uint gaugeIndex, uint tokensPerVote) {
        TOKEN = token;
        GAUGE_INDEX = gaugeIndex;
        TOKENS_PER_VOTE = tokensPerVote;
    }

    /// @param _proposal bytes32 of snapshot IPFS hash id for a given proposal
    function sendBribe(bytes32 _proposal) external {
        IERC20(TOKEN).approve(VOTIUM_BRIBE, TOKENS_PER_VOTE);
        BribesLogic.sendBribe(TOKEN, _proposal, TOKENS_PER_VOTE, GAUGE_INDEX, _lastProposal, VOTIUM_BRIBE);
        _lastProposal = _proposal;
    }
}