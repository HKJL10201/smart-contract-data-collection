pragma solidity ^0.8.0;

import "https://github.com/CelloBlockchain/USD-Token/contracts/USD.sol";

contract Voting {
    mapping(address => bool) public voters;
    address payable public beneficiary;
    uint public totalVotes;
    USD public usd;

    event VotingEnded(bool winningProposal);

    constructor(address _usd) public {
        beneficiary = msg.sender;
        usd = USD(_usd);
    }

    function vote() public {
        require(!voters[msg.sender], "You have already voted.");
        require(usd.transferFrom(msg.sender, address(this), 1 usd), "You must vote with 1 USD.");
        voters[msg.sender] = true;
        totalVotes++;
    }

    function winningProposal() public view returns (bool) {
        if (totalVotes == 0) return false;
        uint yesVotes = 0;
        // Call external API to get the current vote count
        // for the issue being voted on
        // uint issueVotes = externalAPI.getVoteCount();
        for (address voter in voters) {
            if (voters[voter]) {
                yesVotes++;
            }
        }
        return yesVotes > totalVotes / 2;
    }

    function endVoting() public {
        require(msg.sender == beneficiary, "Only the beneficiary can end voting.");
        require(block.timestamp >= startTime + 1 days, "Voting must last for at least 1 day.");
        emit VotingEnded(winningProposal());
    }

    function payout() public {
        require(winningProposal(), "There is no winning proposal.");
        require(block.timestamp >= startTime + 1 days, "Voting must last for at least 1 day.");
        require(msg.sender == beneficiary, "Only the beneficiary can claim the payout.");
        usd.transfer(msg.sender, address(this).balance);
    }
}

