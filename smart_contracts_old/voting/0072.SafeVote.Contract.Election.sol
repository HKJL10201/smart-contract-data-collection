pragma solidity >0.4.0 <0.6.0;


contract SampleVoting {
    // cadidate info struct.
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // voters info struct
    struct Voter {
        uint aadhar;
        bool registered;
        bool voted;

        string name;
        string email;
        uint mobile_no;
    }

    // Store Candidates
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    
    //mapping of aadhar to a boolean
    mapping(uint => Voter) public voters;

    constructor () public {
        addCandidate("Shivansh");
        addCandidate("Hardik");
        addCandidate("Utkarsh");
    }

    function addCandidate (string memory _name) private {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidatesCount ++;
    }
    function register(uint aadhar,string memory name,string memory email,uint mob) public {

        //check if already registered
        if(voters[aadhar].registered==true) {
            revert("Already registered");
        }
        voters[aadhar] = Voter(aadhar,true,false,name,email,mob);


    }
    //functuion to caste vote
    function vote (uint _candidateId,uint aadhar) public {

        //check if already voted
        if(voters[aadhar].voted==true) {
            revert("Already casted Vote");
        }
        //updating the voter
        voters[aadhar].voted = true;
        //incrementing the vote
        candidates[_candidateId].voteCount++;

    }
}
