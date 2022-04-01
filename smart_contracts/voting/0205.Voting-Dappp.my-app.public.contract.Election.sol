pragma solidity ^0.8.0;


contract Election {
    // an event that is called whenever a Candidate is added so the frontend could
    // appropriately display the candidate with the right element id (it is used
    // to vote for the candidate, since it is the argument for the function "vote")
    event AddedCandidate(uint candidateID);
    

    address owner;
   
   
    // describes a Candidate
    struct Candidate {
        string  name;
        string  party;
        uint vote; 
        uint candidateID;
        
        // "bool doesExist" is to check if this Struct exists
        // This is so we can keep track of the candidates 
        bool doesExist; 
    }
    
    Candidate[] allCandidate;

    // These state variables are used keep track of the number of Candidates/Voters 
    // and used to as a way to index them     
    uint numCandidates  = 0; // declares a state variable - number Of Candidates


    
    // These mappings will be used in the majority
    // of our transactions/calls

    mapping (uint => Candidate) candidates;
    mapping(address => bool) newAdmin;
    
    // This mapping will be used to confirm that each voter can only vote once for each candidate. 
    mapping(address => mapping(uint => bool)) hasVotedFor;
    
    constructor () public {
        owner = msg.sender;
        newAdmin[msg.sender] = true;
    }
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *  These functions perform transactions, editing the mappings *
    
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
     function AllCandidate () view public returns(Candidate[] memory){
         
         return allCandidate;
     }
     
     // function addAdmin help to msg.sender to add mutiple admin address
function addAdmin (address _newOwner) public {
     require(msg.sender == owner, 'only owner can call this function'); 
     
    newAdmin[_newOwner] = true;
    
}

// this function is used to addCandidate to an election, it can only be called by msg.sender of added admin(s). 

   function addCandidate(string memory name, string memory party)  public returns(uint) {
         require(newAdmin[msg.sender] == true, 'only authorized address can call this function'); 
        // candidateID is the return variable
         numCandidates = numCandidates + 1;
         
        uint candidateID = numCandidates;
        
        // Create new Candidate Struct with name and saves it to storage.
        candidates[candidateID] = Candidate(name,party,0,candidateID,true);
       Candidate memory candidate = Candidate(name,party,0,candidateID,true);
       allCandidate.push(candidate);
        emit  AddedCandidate(candidateID);
       return candidateID;
        
    }

function vote(uint candidateID) public returns(uint) {
        // checks if the struct exists for that candidate
        require (candidates[candidateID].doesExist == true, 'candidate does not exist') ;
        require (hasVotedFor[msg.sender][candidateID] == false, 'You can not vote for a candidate twice');
        //Add a vote to the candidateID
        //update candidates mapping
           candidates[candidateID] =Candidate( candidates[candidateID].name,candidates[candidateID].party,candidates[candidateID].vote + 1,candidates[candidateID].candidateID,candidates[candidateID].doesExist);
            //update candidates array decremented the ID by one to get the position in the array beacuse array indexing start from zero
            allCandidate[candidateID - 1]= Candidate( candidates[candidateID].name,candidates[candidateID].party,candidates[candidateID].vote,candidates[candidateID].candidateID,candidates[candidateID].doesExist);
            hasVotedFor[msg.sender][candidateID] = true;
            
            return candidates[candidateID].vote;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * 
     *  Getter Functions, marked by the key word "view" *
     * * * * * * * * * * * * * * * * * * * * * * * * * */
    

    // finds the total amount of votes for a specific candidate by looping
    // through voters 
    function totalVotes(uint candidateID) view public returns (uint) {
    // check if the struct exists for the candidate
       require (candidates[candidateID].doesExist == true, 'candidate does not exist') ;
<<<<<<< HEAD
      //return the total number of voters for a candidate;
=======
     //  return the total number of voters for a candidate
>>>>>>> e4b3a0bddabb24998d5e550f96a09d24e0c28b7c
       return candidates[candidateID].vote;
    }

  // finds the total amount of candidate 
    function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

    
    // returns candidate information, including its ID, name, and party
    function getCandidate(uint candidateID) public view returns (uint, string memory, string memory) {
        return (candidateID,candidates[candidateID].name,candidates[candidateID].party);
    }
}
