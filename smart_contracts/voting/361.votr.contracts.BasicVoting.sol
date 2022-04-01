// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BasicVoting {
  event ProposalSubmitted(uint proposalId, string proposalName, address submittedBy);

  struct Proposal {
    string name;
    uint passCount;
    uint rejectCount;
    uint expirationTime;
    address submittedBy;
  }

  struct ProposalInfo {
    string name;
    string status;
    uint passCount;
    uint rejectCount;
    uint expirationTime;
    address submittedBy;
  }

  struct Voter {
    bool hasVoted;
    bool votedToPass;
    uint voteWeight;
    address delegatedTo;
  }

  Proposal[] public proposals;
  mapping(uint => Voter) public voters;
  mapping(address => address) public delegations;

  function submitProposal(string calldata proposalName, uint duration) external {
    proposals.push(Proposal(
      proposalName,
      0,
      0,
      block.timestamp + duration,
      msg.sender
    ));

    emit ProposalSubmitted(proposals.length - 1, proposalName, msg.sender);
  }

  function getProposalInfo(uint proposalId) external view returns (ProposalInfo memory) {
    Proposal memory proposal = proposals[proposalId];

    string memory status = "Tied";

    if(proposal.expirationTime > block.timestamp) {
      status = "Pending";
    } else if(proposal.passCount > proposal.rejectCount) {
      status = "Passed";
    } else if(proposal.passCount < proposal.rejectCount) {
      status = "Rejected";
    }

    return ProposalInfo(
      proposal.name,
      status,
      proposal.passCount,
      proposal.rejectCount,
      proposal.expirationTime,
      proposal.submittedBy
    );
  }

  function getProposalStatus(uint proposalId) public view returns (string memory) {
    Proposal memory proposal = proposals[proposalId];

    if(proposal.expirationTime > block.timestamp) {
      return "Pending";
    } else if(proposal.passCount > proposal.rejectCount) {
      return "Passed";
    } else if(proposal.passCount < proposal.rejectCount) {
      return "Rejected";
    } else {
      return "Tied";
    }
  }

  function vote(uint proposalId, bool shouldPass) public isVotingOngoing(proposalId) senderHasNotVoted(proposalId) {
    uint voterId = _getVoterId(proposalId, msg.sender);

    Voter storage voter = voters[voterId];

    voter.hasVoted = true;

    if(shouldPass) {
      voter.votedToPass = true;
      //+1 because default weight should be 1 and it defaults to 0
      proposals[proposalId].passCount += voter.voteWeight + 1;
    } else {
      //+1 because default weight should be 1 and it defaults to 0
      proposals[proposalId].rejectCount += voter.voteWeight + 1;
    }
  }

  function delegate(uint proposalId, address delegateAddress) public isVotingOngoing(proposalId) senderHasNotVoted(proposalId)  {
    _delegate(proposalId, delegateAddress, msg.sender);
  }

  function _delegate(uint proposalId, address delegateAddress, address voterAddress) internal isVotingOngoing(proposalId) {
    require(voterAddress != delegateAddress, "Delegating to self is not allowed!");

    while (voters[_getVoterId(proposalId, delegateAddress)].delegatedTo != address(0)) {
      delegateAddress = voters[_getVoterId(proposalId, delegateAddress)].delegatedTo;

      require(voterAddress != delegateAddress, "Delegation loops are not allowed!");
    }

    uint voterId = _getVoterId(proposalId, voterAddress);

    Voter storage voter = voters[voterId];

    require(!voter.hasVoted, "Voter has already voted!");

    voter.hasVoted = true;
    voter.delegatedTo = delegateAddress;

    delegations[voterAddress] = delegateAddress;

    uint delegateVoterId = _getVoterId(proposalId, delegateAddress);
    Voter storage delegateVoter = voters[delegateVoterId];

    if (delegateVoter.hasVoted) {
      if(delegateVoter.votedToPass) {
        //+1 because default weight should be 1 and it defaults to 0
        proposals[proposalId].passCount += voter.voteWeight + 1;
      } else {
        //+1 because default weight should be 1 and it defaults to 0
        proposals[proposalId].rejectCount += voter.voteWeight + 1;
      }
    } else {
      //+1 because default weight should be 1 and it defaults to 0
      delegateVoter.voteWeight += voter.voteWeight + 1;
    }
  }

  modifier isVotingOngoing(uint proposalId) {
    require(proposals[proposalId].expirationTime > block.timestamp, "Voting has ended!");
    _;
  }

  modifier senderHasNotVoted(uint proposalId) {
    require(!_hasVoted(proposalId, msg.sender), "Already voted on this proposal!");
    _;
  }

  function _getVoterId(uint proposalId, address voterAddress) internal pure returns (uint) {
    return uint(keccak256(abi.encodePacked(proposalId, voterAddress)));
  }

  function _hasVoted(uint proposalId, address voterAddress) internal view returns (bool) {
    uint voterId = _getVoterId(proposalId, voterAddress);

    return voters[voterId].hasVoted;
  }
}