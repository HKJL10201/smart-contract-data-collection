// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 <0.9.0;

//importing Interface 
import "./IVotingContract.sol";

//inheriting and contract declaration
contract VotingContract is IVotingContract{

// variable for time start of the contract
uint deployTime;
//For updating user interface
event Progress(address indexed sender, string indexed level );

    //address adding candidates
    address  public chairperson;

    //blueprint for adding candidates
    struct Candidate{
        uint Id;
        bytes32 name;
        uint voteCount;
    }

    //mapping address to the condition of voting(boolean datatype)
    mapping(address => bool) public voted;
    
    //creating an empty array of candidates using the struct Candidate
    Candidate[] candidateList;

    //mapping a string of byte length 32 to candidates of data-type Candidate
    mapping(bytes32 => Candidate) candidates;

    //modifier to check that caller is the only chairperson
    modifier onlyChairperson() {
        require(chairperson == msg.sender, "only Chairperson can add candidate");
        _;// continue executing rest of the code
    }

    //modifier to check if caller has cast their vote
    modifier hasVoted() {
        require(!voted[msg.sender], "You already casted your vote");
        _;//continue executing rest of the code
    }

    //constructor to initialize state variables deploy time and chairperson
    constructor(address _chairperson){
         deployTime = block.timestamp;
         chairperson = _chairperson;

        //logging the start of nomination
        emit Progress(_chairperson, "Nomination of candidate has started");
    }
    ///function to add candidates being voted for
    function  addCandidate(bytes32 name)  external onlyChairperson override returns (bool){
        
        //statement to ensure that candidates are added within the 3 minutes alloted time
        if(block.timestamp > deployTime + 180)
        {
            //logging the end of nomination; ending addCandidate function 
             emit Progress(msg.sender, "Nomination of candidate has ended");
             return false;
        }
    
        bytes32 previousCandidate = candidates[name].name;
        // to ensure that a candidate is not added twice

        require(previousCandidate != name,"Candidate Already Exist");
        // creates a new candidate of datatype Candidate and gives it an ID equal to the length of the array of candidates
        
        Candidate memory newCandidate = Candidate({
            Id : candidateList.length,
            name : name,
            voteCount: 0 //initializing voteCount to 0
            });

           // adding new candidates to the array 
           candidateList.push(newCandidate);  
           candidates[name] = newCandidate;
        return true;
    }

    //function to vote a candidate 
    function voteCandidate(uint candidateId) external hasVoted override returns(bool){

        // ensuring candidate is part of array of candidate by comparing IDs
        require(candidateId < candidateList.length,"Invalid candidate");

        // to ensure that voting occurs between 3-6 minutes oc Contract deployment 
        if(block.timestamp > deployTime + 360 || block.timestamp < deployTime + 180){
            return false;
        }

        //updating vote count after voting has occured
        candidateList[candidateId].voteCount += 1;

        //checks the voting status of the caller as true
        voted[msg.sender] = true;
        return true;
    }

    //function to get the winner of the election
    function getWinner() external view override returns(bytes32){

        //ensuring the voting has ended before running function
         if(block.timestamp < deployTime + 360){
            revert("voting still ongoing");
        }
        
        //candidates must be added before this function can run
        require(candidateList.length > 0,"No candidate");

        // initializing maxVote to 0
        uint maxVote = 0;

        //creating variable winner that is of datatype Candidate
        Candidate memory winner;

        //loop to determine winner
        for(uint i = 0; i < candidateList.length; i++)
        {
            // storing each candidate in variable candidate
            Candidate memory candidate = candidateList[i];

            //checking each candidate's number of votes to determine the highest
            if(candidate.voteCount > maxVote)
            {
                maxVote = candidate.voteCount;
                winner = candidate;
            }

        }
        //returns the election winner
        return winner.name;
    }

}
