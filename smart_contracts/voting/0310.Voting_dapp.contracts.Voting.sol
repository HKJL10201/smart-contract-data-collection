pragma solidity 0.5.16;

contract Voting {
    event AddedCandidate(uint candidateID);

    address owner;
    constructor() public {
        owner=msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    /*struct Voter {
        bytes32 uid; // bytes32 type are basically strings
        uint candidateIDVote;
    }*/
    struct Candidate {
        bytes32 name;
        bytes32 party; 
        uint votecount;
        bool doesExist; 
    }

    uint numCandidates; 
    //uint numVoters;

    mapping (uint => Candidate) candidates;
    mapping (bytes32 => uint) voters;

    function addCandidate(bytes32 name, bytes32 party) onlyOwner public {
        uint candidateID = numCandidates++;
        candidates[candidateID] = Candidate(name,party,0,true);
        emit AddedCandidate(candidateID);
    }

    function vote(bytes32 uid, uint candidateID) public{
        if (candidates[candidateID].doesExist == true && voters[uid]==0) {
            //uint voterID = numVoters++;
            voters[uid] = 1;
            candidates[candidateID].votecount+=1;
            //return true;
        }
        else{
            //return false;
            revert("Already Voted");
        }
    }
   
    function totalVotes(uint candidateID) view public returns (uint) {
        return candidates[candidateID].votecount; 
    }

    function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

    /*function getNumOfVoters() public view returns(uint) {
        return numVoters;
    }*/
    function getCandidate(uint candidateID) public view returns (uint,bytes32, bytes32) {
        return (candidateID,candidates[candidateID].name,candidates[candidateID].party);
    }
}
