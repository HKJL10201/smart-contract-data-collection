pragma solidity 0.8.4;

import "./VoteToken.sol";

contract VoteDApp {

    struct Proposal {
        string proposal;
        address[] addresses;
    }

    struct Vote {
        string topic;
        bool isFinished;
        uint256 result;
        address starterAddress;
        uint numProposals;
        mapping (uint => Proposal) proposals;
    }


    string public name = "Vote DApp";
    uint256 public voteID;
    address public owner;

    mapping(uint256 => Vote) public votes;

    function createVote(string memory _topic) public {
        voteID++;
        votes[voteID].starterAddress = msg.sender;
        votes[voteID].topic = _topic;
    }

    function addProposalToVote(uint256 _voteID, string memory _proposal) public {
        address[] memory emptyAddressArray;

        votes[_voteID].numProposals++;
        votes[_voteID].proposals[votes[_voteID].numProposals] = 
            Proposal({
                proposal: _proposal,
                addresses: emptyAddressArray
            });

    }

    function plusOne(uint256 _voteID,uint256 _proposalID) public {
        votes[_voteID].proposals[_proposalID].addresses.push(msg.sender);
    }

    function closeVote(uint256 _voteID) public {
        votes[_voteID].isFinished = true;
    }

  function getVote(uint256 _voteID) public view returns (string memory, bool, uint256, address, uint){
      return (votes[_voteID].topic,
      votes[_voteID].isFinished,
      votes[_voteID].result,
      votes[_voteID].starterAddress,
      votes[_voteID].numProposals);
  }

  function getVoteProposal(uint256 _voteID, uint256 _proposalID) public view returns (string memory, address[] memory) {
      return (votes[_voteID].proposals[_proposalID].proposal, votes[_voteID].proposals[_proposalID].addresses);
  }
}
