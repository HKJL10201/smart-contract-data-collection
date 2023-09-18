// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './AllVoter.sol';
import './Candidates.sol';
contract Voting is AllVoter, Candidates{
    address private admin;
    mapping(address=>uint) votes;
    address[] public voted_persons;
    mapping(address=> bool) public isVoted;
    bool public isVotingStarted = false;
    uint public endTime;
    
    event VoteEvent(address indexed candidate);
    event VotingStartedEvent(uint indexed endTime);

    constructor(){
        admin = msg.sender;
        
    }

    function startVoting() external {
        require(msg.sender == admin, "Only admin can start voting");
        isVotingStarted = true;
        endTime = block.timestamp + 30 minutes;
        emit VotingStartedEvent(endTime);
    }



    function Vote(address candidate, string memory NID) external{
        require(isVotingStarted == true, 'Voting is not started');
        require(block.timestamp<=endTime, 'Can not vote');
        require(isVoted[msg.sender] == false, 'Already voted');
        require(endTime >= block.timestamp, 'Voting is over');

        Voter storage voter = voters[msg.sender];
        if(keccak256(abi.encodePacked(voter.id))  == keccak256(abi.encodePacked(NID)) == false){
            revert('You are not a voter');
        }
        uint count;
        for(uint i;i<candidatesCount;i++){
             if(candidate != candidateList[i]){
                 count++;
            }
        }

        if(count==4){
            revert('Not known candidate !');
        }
        isVoted[msg.sender] = true;
        voted_persons.push(msg.sender);

        votes[candidate] = votes[candidate]+1;

        emit VoteEvent(candidate);

    }

    function VotesToCandidate(address _candidate) external view returns(uint){
        return votes[_candidate];
    }

    function Winner() external view returns(address winner){
        // require(block.timestamp>=endTime, 'Voting not finished yet.');
        uint highest_vote;
        
        for(uint i; i<candidatesCount;i++){
            
            if(votes[candidateList[i]]>highest_vote){
                highest_vote = votes[candidateList[i]];
                winner = candidateList[i];
            }
        }
    }



}