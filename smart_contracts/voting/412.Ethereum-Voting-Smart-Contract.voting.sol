//SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Voting {
    //event which is called when a candidate is added
    event AddedCandidate(uint256 CandidateId);

    //a voter has its own id and the Id of the candidate they voted for

    address owner;

    constructor() {
        owner = msg.sender;
    }

    // function Voting() public {
    //     owner = msg.sender;
    // }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Voter {
        string uid;
        uint256 candidateIdVote;
        uint256 voterId;
        bool hasVoted;
    }
    
    struct Candidate {
        string name;
        string party;
        bool doesExist;
        uint256 candidateId;
        uint256 total_votes;
    }
    //stores the number of candidates
    uint256 numCandidates;
    //stores the number of voters
    uint256 numVoters;

    //tables with key = uint and value = candidate/voter
    mapping(uint256 => Candidate) candidates;
    mapping(uint256 => Voter) voters;
    mapping(string => Voter) people;

    function addCandidate(string memory name, string memory party) public onlyOwner {
        uint256 candidateId = numCandidates++;
        //inserting the candidate in our table
        uint256 votes = 0;
        candidates[candidateId] = Candidate(
            name,
            party,
            true,
            candidateId,
            votes
        );
        //emitting the event since a candidate is added
        emit AddedCandidate(candidateId);
    }

    function Vote(string  memory uid, uint256 candidateId) public returns(string memory){
        //checking if the voter has already voted
        if (people[uid].hasVoted == true) {
            return "You have already voted!";
        }
        if (candidates[candidateId].doesExist == true) {
            uint256 voterId = numVoters++;
            voters[voterId] = Voter(uid, candidateId, voterId, true);
            candidates[candidateId].total_votes++;
        }
        return "Vote Successful";

    }

    //function to get the total votes for a candidate
    function numOfVotes(uint256 candidateId) public view returns (uint256) {
        //checking if the candidate exists
        if (candidates[candidateId].doesExist == true) {
            return candidates[candidateId].total_votes;
        }
    }

    function getNumOfCandidates() public view returns (uint256) {
        return numCandidates;
    }

    function getNumOfVoters() public view returns (uint256) {
        return numVoters;
    }

    // returns candidate information, including its ID, name, party, and number of votes
    function getCandidate(uint256 candidateID)
        public
        view
        returns (
            uint256,
            string memory ,
             string memory,
            uint256
        )
    {
        return (candidateID,candidates[candidateID].name,candidates[candidateID].party,candidates[candidateID].total_votes);
    }


    function getAllCandidates()
    public
    view
     returns(uint [] memory)
     {
        uint[] memory id = new uint[](numCandidates+1);
        id[0] = 0;
        for(uint i=1;i<=numCandidates;i++){
            id[i] = candidates[i].total_votes;
        }

        return id;
    }

}