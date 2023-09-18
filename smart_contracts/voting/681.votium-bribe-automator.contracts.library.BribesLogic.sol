// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/votium/IVotiumBribe.sol";
import "../../interfaces/token/IERC20.sol";

library BribesLogic {
    /// @dev sends the token incentives to curve gauge votes for the next vote cycle/period
    function sendBribe(address _token, bytes32 _proposal, uint _tokensPerVote, uint _choiceIndex,  bytes32 _lastProposal, address _votiumBribe) public {
        uint balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "No tokens");

        if (_tokensPerVote > balance) {
            _tokensPerVote = balance;
        }

        // this makes sure that the token incentives can be sent only once per proposal
        require(_proposal != _lastProposal, "Bribe already sent");

        IVotiumBribe.Proposal memory proposal = IVotiumBribe(_votiumBribe).proposalInfo(_proposal);

        require(block.timestamp < proposal.deadline, "Proposal Expired"); // make sure the proposal exists
        require(_choiceIndex <= proposal.maxIndex, "Gauge doesnt exist"); // make sure the gauge index exists in the proposal

        IVotiumBribe(_votiumBribe).depositBribe(_token, _tokensPerVote, _proposal, _choiceIndex);
    }
}