pragma solidity ^0.4.4;

contract Voting {

    bytes32[] public proposals;
    uint256[] public votes;
    address owner;

    event NewProposal(bytes32 proposal);
    event NewVote(uint256 votesCount, uint256 index, bytes32 proposal);

    function Voting() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function getProposals() public constant returns (bytes32[]) {
        return proposals;
    }

    function getVotes() public constant returns (uint256[]) {
        return votes;
    }

    function addProposal(bytes32 _proposal) public onlyOwner returns (bool) {
        proposals.push(_proposal);
        votes.push(0);
        NewProposal(_proposal);
        return true;
    }

    function voteProposal(uint256 _index) public returns(bool) {
        votes[_index] = votes[_index] + 1;
        NewVote(votes[_index], _index, proposals[_index]);
        return true;
    }

}