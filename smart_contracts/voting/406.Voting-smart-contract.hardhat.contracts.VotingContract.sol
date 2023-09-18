// SPDX-License-Identifier: GPL-3.0
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.7.0 <0.9.0;

// Use onlyOwner for chairperson

contract VotingContract is Ownable {

    address public contractOwner;

    struct Voter {

        uint dailyVote;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        //        string id;
        address ProposalOwner;
        string name;
        string description;
        uint voteCount;
        uint endTime;
        //        uint endTime; // set the end time by the chairperson
    }

    Proposal[] public proposals;
    uint proposalsLength;

    mapping(address => Voter) public voter;
    mapping(address => Proposal[]) public voterToProposals;


    // Check 3 conditions . TODO => improve dailyVote
    modifier canVote(Proposal memory _proposal, address _voterAddress) {
        require(checkIfVoterHasVoted(_voterAddress, _proposal));
        require(voter[_voterAddress].dailyVote <= 2);
        require(_proposal.endTime > block.timestamp);
        _;
    }

    function getProposals() external view returns (Proposal[] memory){
        return proposals;
    }

    function getProposalLeftTime(Proposal memory _proposal) external pure returns (uint timeLeft) {
        return _proposal.endTime;
    }
    // Check if the voter has already voted for a specific proposal.
    function checkIfVoterHasVoted(address _voter, Proposal memory _proposal) internal view returns (bool result) {
        for (uint i; i < voterToProposals[_voter].length; i++) {
            if (equals(_proposal, voterToProposals[_voter][i])) {
                return !result;
            }
        }
    }

    function equals(Proposal memory _first, Proposal storage _second) internal view returns (bool) {
        // Just compare the output of hashing all fields packed
        return (keccak256(abi.encodePacked(_first.name, _first.description, _first.ProposalOwner)) == keccak256(abi.encodePacked(_second.name, _second.description, _second.ProposalOwner)));
    }

    // Define the owner of the smart-contract.
    constructor(){
        contractOwner = msg.sender;
    }

    event ProposalCreated(Proposal _proposal);

    function createProposal(string memory _name, string memory _description, uint endTime) external {
        Proposal memory newProposal = Proposal(msg.sender, _name, _description, 0, 1663576187);
        proposals.push(newProposal);
        voterToProposals[msg.sender].push(newProposal);
        emit ProposalCreated(newProposal);
    }

    function vote(uint proposal) canVote(proposals[proposal], msg.sender) external {
        Voter memory sender = voter[msg.sender];
        voterToProposals[msg.sender].push(proposals[proposal]);
        //emit users information (vote list).
        proposals[proposal].voteCount += 1;
        sender.vote++;
    }


}
