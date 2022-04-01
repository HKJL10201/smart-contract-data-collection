pragma solidity ^0.4.18;
// written for Solidity version 0.4.18 and above that doesn't break functionality

contract Voting {
    event VoteResult(string message);

    // describes a Voter, which has an id and the ID of the candidate they voted for
    address owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    struct Voter {
        bytes32 voterID; // bytes32 type are basically strings
        bool doesExist;
        mapping (uint => bool) votedPosts; // postId => true/false
    }

    // describes a Candidate
    struct Candidate {
        bytes32 name;
        uint votes;
        uint postID;
        bool doesExist;
    }

    // These state variables are used keep track of the number of Candidates/Voters
    // and used to as a way to index them
    uint numCandidates; // declares a state variable - number Of Candidates
    uint numVoters;
	uint numPosts;

    // Think of these as a hash table, with the key as a uint and value of
    // the struct Candidate/Voter. These mappings will be used in the majority
    // of our transactions/calls
    // These mappings will hold all the candidates and Voters respectively
    mapping (uint => Candidate) candidates;
    mapping (bytes32 => Voter) voters;
    mapping (uint => bytes32) posts;


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *  These functions perform transactions, editing the mappings *
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function addCandidate(bytes32 name, uint postID) onlyOwner public {
        // candidateID is effectively the index of the struct
        uint candidateID = numCandidates++;
        // Create new Candidate struct with name and saves it to storage.
        candidates[candidateID] = Candidate(name, 0, postID, true);
    }

	function dropCandidate(uint candidateID) onlyOwner public {
        candidates[candidateID].doesExist = false;
    }

    function enableCandidate(uint candidateID) onlyOwner public {
        candidates[candidateID].doesExist = true;
    }

    function addPost(bytes32 postName) onlyOwner public {
        uint postID = numPosts++;
        posts[postID] = postName;
    }

    function vote(bytes32 voterID, uint candidateID) public {
        // checks if the struct exists for that voter
        if (candidates[candidateID].doesExist == true) {
        	// if doesn't exist, set new struct
        	// and increment count
        	if (voters[voterID].doesExist == false) {
        		voters[voterID] = Voter(voterID, true);
				numVoters++;
        	}
        	// mark that post as voted if not already
        	if (voters[voterID].votedPosts[candidates[candidateID].postID]) {
        		emit VoteResult("You have already voted for this post.");
        	} else {
        		voters[voterID].votedPosts[candidates[candidateID].postID] = true;
        		candidates[candidateID].votes++;
                emit VoteResult("Voted successfully for current post!");
        	}
        } else {
            // should never occur
        	emit VoteResult("Candidate does not exist.");
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * *
     *  Getter Functions, marked by the key word "view" *
     * * * * * * * * * * * * * * * * * * * * * * * * * */

    // finds the total amount of votes for a specific candidate by looping
    // through voters
    function totalVotes(uint candidateID) view public returns (uint) {
        return candidates[candidateID].votes;
    }

    function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

    function getNumOfVoters() public view returns(uint) {
        return numVoters;
    }

    function getNumOfPosts() public view returns(uint) {
        return numPosts;
    }

    function getPost(uint postID) public view returns (uint, bytes32) {
        return (postID,posts[postID]);

    }

    // returns candidate information, including its ID, name, and party
    function getCandidate(uint candidateID) public view returns (uint, bytes32, uint, uint, bytes32) {
        return (candidateID, candidates[candidateID].name, candidates[candidateID].votes, candidates[candidateID].postID, posts[candidates[candidateID].postID]);
    }
}
