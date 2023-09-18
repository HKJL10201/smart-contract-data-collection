pragma solidity >=0.4.22 < 0.9.0;

contract Elections{
    //create a candidate structure.
    struct Candidate{
        uint id;
        string name;
        string party;
        uint voteCount;
    }

    //Candidate counter
    uint public candidateCount;

    //mappings 
    //1. candidates ; 2. hasVoted (for particualr accounts, to check have they voted already.)
    
    mapping(uint => Candidate) public Candidates;
    mapping(address => bool) public hasVoted;

    //creating an event to keep the logs after the voting process.
    event electionsUpdated(
        uint id,
        string name,
        string party,
        uint voteCount
        );
    
    //defining the constructor.
    constructor() public {
        addCandidate("Narendra D Modi", "BJP");
        addCandidate("Rahul Gandhi", "INC");
        addCandidate("Arvind Kejriwal","AAP");
    }
    
    // defining a function to add the candidates. shouldn't be a public function
    //memory keyword specifies storing data temporarily
    function addCandidate(string memory name, string memory party) private {
        candidateCount++;
        // populating Candidates mapping with a real candidate information on particular index (candidateCount).
        Candidates[candidateCount] = Candidate(candidateCount,name,party,0);
        //initial votes for every candidate is set as 0 by default.

    }


    //definig a function for casting vote
    function Vote(uint _id) public{
        
        //puttting a condition before the process. If the particulare account has already voted, it can't vote further.
        // msg is a global variable. msg.sender will return the particular address of the voter.
        require(!hasVoted[msg.sender],'You have voted Already!');
        
        //checking the vote is casted for a valid candidate id
        require(Candidates[_id].id !=0, "id dosen't exist");

        //if all conditions are passed,
        //incrementing vote count of candidate with respective id, voter has voted to.  
        Candidates[_id].voteCount+=1;

        //after the vote has been casted successfully, mark hasVoted bool flag for the particular account as 'true'.
        hasVoted[msg.sender] = true ;

        //logging the voting details
        emit  electionsUpdated(_id, Candidates[_id].name, Candidates[_id].party, Candidates[_id].voteCount);
    
    }

}