// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Candidate{
   string name;
   uint age;
   uint voteCount;
}

struct Voter{
    uint vote;
    bool voted;
}

contract Election{

    address public owner;
    string public electionName;
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public totalVotes;
    string public winner;

    modifier ownerOnly{
        require(msg.sender == owner,"You dont have rights to perform this operation !");
        _;
    }


    function startElection(string memory _electionName) public {
        owner = msg.sender;
        electionName=_electionName;
    }

    function addCandidate(string memory _name,uint _age) ownerOnly public {
         candidates.push(Candidate(_name,_age,0));
    }

    function getAllCandidate() public returns(Candidate[] memory){
       return candidates;
    }

    function vote(uint _voteIndex) public {
        require(!voters[msg.sender].voted,"You are alredy voted !");

        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].voted = true;
        candidates[_voteIndex].voteCount += 1; 
        totalVotes +=1;
    }


    function selectWinner() public view returns (uint selectWinner_){
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                selectWinner_ = p;
            }
        }
    }

    function winnerName() public returns(string memory winnerName_){
        winner = candidates[selectWinner()].name;
        winnerName_ = candidates[selectWinner()].name;
    }

}

