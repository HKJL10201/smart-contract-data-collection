// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Voting {

    address owner;

    struct Candidate{
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public voted;

    uint256 public votingStart;
    uint256 public votingEnd;

    constructor(string[] memory _candidate, uint256 votingTime){
        for(uint i=0; i < _candidate.length; i++){
            Candidate memory newCadidate = Candidate({
                name: _candidate[i],
                voteCount: 0
            });
            candidates.push(newCadidate);
        }
        owner = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (votingTime * 1 minutes);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only Onwer can use this");
        _;
    }

    function addCandidate(string memory _name) public onlyOwner {
        Candidate memory newCadidate = Candidate({
                name: _name,
                voteCount: 0
            });
        candidates.push(newCadidate);
    }

    function vote(uint _index) public {
        require(!voted[msg.sender], "You have already voted");
        require(_index < candidates.length, "Invalid index");
        require(block.timestamp >= votingStart && block.timestamp < votingEnd);

        candidates[_index].voteCount++;
        voted[msg.sender] = true;
    }

    function getCandidates() public view returns (Candidate[] memory){
        return candidates;
    }

    function getVotingStatus() public view returns (bool) {
        return(block.timestamp >= votingStart && block.timestamp < votingEnd);
    }

    function getRemainingTime() public view returns (uint256) {
        require(block.timestamp >= votingStart, "Voting has not started yet");
        if(block.timestamp >= votingEnd){
            return 0;
        }
        return votingEnd - block.timestamp;
    }
    

}
