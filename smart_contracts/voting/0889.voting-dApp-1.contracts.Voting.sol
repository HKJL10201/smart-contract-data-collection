pragma solidity ^0.4.18;

contract Voting {

    // ensures candidate has the right id and is displayed appropriately on the front end
    event AddedCandidate(uint candidateID);

    // sets up a voter with an id string (bytes32) and ID of candidate they voted for
    struct Voter {
        bytes32 uid;
        uint candidateIDVote;
    }

    struct Candidate {
        bytes32 name;
        bytes32 party;
        // this allows us to keep track of candidates and does a check to ensure Struct exists
        bool doesExist;
    }

    // state variables to keep track of total candidates/voters
    uint numCandidates;
    uint numVoters;

    // similar to hash tables, uint is key to the entire struct for all voter/candidate
    // these will be used in most of the transactions/calls
    mapping (uint => Candidate) candidates;
    mapping (uint => Voter) voters;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Functions to perform transactions, editing the mapping  *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function addCandidate(bytes32 name, bytes32 party) public {
      // candidateID is the return variable
      uint candidateID = numCandidates++;
      // create new Candidate Struct with name and saves it to storage.
      candidates[candidateID] = Candidate(name,party,true);
      AddedCandidate(candidateID);
    }

    function vote(bytes32 uid, uint candidateID) public {
      // checks if the struct exists for candidate
      if (candidates[candidateID].doesExist == true) {
        // voterID is the return variable
        uint voterID = numVoters++;
        voters[voterID] = Voter(uid, candidateID);
      }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * *
     * Getter Functions, marked by the keyword 'view'  *
     * * * * * * * * * * * * * * * * * * * * * * * * * */

    // find total votes for a specific candidate by looping through voters
    function totalVotes(uint candidateID) view public returns (uint) {
        uint numOfVotes = 0;
        for (uint i = 0; i < numVotes; i++) {
          // if the voter votes for this candidate, increment totalVotes
            if (voters[i].candidateIDVote == candidateID) {
                numOfVotes++;
            }
        }
        return numOfVotes;
    }

    // returns state variable with is increased in the addCandidate function
    function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

    // returns state variable with is increased in the vote function
    function getNumOfVoters() public view returns(uint) {
        return numVoters;
    }

    // returns candidate information, including ID, name & party
    function getCandidate(uint candidateID) public view returns (uint,bytes32,bytes32) {
        return (candidateID, candidates[candidateID].name, candidates[candidateID].party);
    }


}