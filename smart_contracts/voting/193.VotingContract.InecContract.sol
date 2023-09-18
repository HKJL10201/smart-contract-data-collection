// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */


interface IVotingContract{

//only one address should be able to add candidates
    function addCandidate(string memory name, uint _candidateId) external returns(bool);

    
    function voteCandidate(uint candidateId) external returns(bool);

    //getWinner returns the name of the winner
    function getWinner() external returns(string memory winnerName_);
}

contract Inec is IVotingContract{
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
        Candidate choice; //who was voted for
        uint timeVoted; //time voted
    }

    enum Status {
        WithinTime,
        PastTime
    }
    struct Candidate {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
        uint _candidateId;
    }

    constructor() {
        chairperson = msg.sender;
        timeCreated = block.timestamp;
    }

    uint public timeCreated;     
    address public chairperson;
    uint public  timeAfterAdd;
    Status public stage;

    mapping(address => Voter) public voters;

    Candidate[] private candidates;

// testing Time feature
    function seeTime() public view returns(uint){
        return timeCreated;
    }
    // changing status based on creation of contract
    // function Voting() private view returns (bool) {
    //     require(block.timestamp <= (timeCreated + 200), "please wait for 30 seconds");
    //     return stage == Status.PastTime;
    // }

    function Registration() private view returns(bool) {
        require(block.timestamp <= (timeCreated + 180), "3 minutes has past. Go to vote");
        return stage == Status.WithinTime;
    }

    // return stage
    function checkStatus() public view returns(string memory state) {
        if (block.timestamp <= timeCreated + 180 ){
            return "Registration";
        }
        if (block.timestamp >= timeCreated + 180 && block.timestamp <= timeCreated + (180 * 2)){
            return "Voting";
        }
            return "No phase yet";
    }

// implementing the interface addCandidate
    function addCandidate(string memory newCand, uint candidateId) public override returns(bool){
        // chairperson = msg.sender;
        require(Registration(), "3 minutes has past. Go to vote");
        // stage = Status.WithinTime;
        require(chairperson == msg.sender, "Only an admin can add candidate");
        for (uint i; i < candidates.length; i++){
            require(candidates[i]._candidateId != candidateId, "Candidate with that ID exists");

        }
        candidates.push(Candidate({
            name: newCand,
            voteCount: 0,
            _candidateId: candidateId
        }));
       
        return true;
    }

    function seeCand() public view returns(Candidate[] memory _candidates){
        return candidates;
    }

    // function checkCandId(uint candidateId) public view returns (string memory){
    //     for (uint i; i <candidates.length; i++){
    //         // if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(candidates[i].name))){
    //         //     return candidates[i].candidateId;
    //         // }
    //         if(candidateId == candidates[i]._candidateId){
    //             return candidates[i].name;
    //         }
    //     }
    // }

    // see voters
    function seeVote(address _add) public view returns (Voter memory){
        require(msg.sender == chairperson, "only Admin can see voter");
        require(_add != address(0), "please enter valid address");

        return voters[_add];
    }

    function voteCandidate(uint candidateId) public override returns(bool){
        require(msg.sender != address(0));
        // check time of 3 minutes
        require(block.timestamp >= timeCreated + 180 && block.timestamp <= timeCreated + (180 * 2));
        stage == Status.PastTime;
        Voter storage newVoter = voters[msg.sender];
        newVoter.delegate = msg.sender;
        require(candidates.length>=1, "candidates have not been added");
        require(chairperson != newVoter.delegate, "you are INEC, why vote?");
        require(!newVoter.voted, "You already voted. Do you steal for a living?");
        // require(block.timestamp >= timeCreated +180, "3 minutes is over")

        // Candidate storage votedFor = candidates[candidateId];
        for(uint i; i < candidates.length;i++) {
            // require(candidateId == candidates[i]._candidateId, "No candidate as such");
            if(candidateId == candidates[i]._candidateId){
                candidates[i].voteCount += 1;
                newVoter.choice = candidates[i];
                newVoter.voted = true;
                newVoter.timeVoted= block.timestamp;
                newVoter.vote = 1;
            }
        }
        return true;
    }

 function getWinningCandidate() private view returns (uint winningCandidate_){
          
        uint winningVoteCount = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidate_ = i;
            }
        }


    }

    //getWinner returns the name of the winner (address with most votes)
    function getWinner() external override view returns(string memory winnerName_){
        
        winnerName_ = candidates[getWinningCandidate()].name;
      

    }
}
