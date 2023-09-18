//SPDX-License-Identifier : UNLICENSED
pragma solidity ^0.8.0;

contract VotingContract {

    // define admin for voting 
    address public chairperson;
    constructor () {
        chairperson = msg.sender;
     }

    // Define structure for Candidates-----------------------------------------------
    struct Candidate{
        address candidate_id;
        string name;
        string email_id;
        bool authorized; // need to be authorized by admin
        uint vote_count;
    }
    mapping (uint => Candidate) public candidates;
    uint public candidatesCount;

    function addCandidate(string memory _name, string memory _email_id) public {
        require(msg.sender == chairperson,'Chairperson will authorize');
        candidatesCount++;
        candidates[candidatesCount] = Candidate(msg.sender, _name, _email_id, false, 0);
    }

    function authorizeCandidate(uint _candidateId) public {
        require(msg.sender == chairperson,'Chairperson only');
        candidates[_candidateId].authorized = true;
    }
    
    // define structure for voters
    struct Voter {
        uint id;
        string voter_name;
        string email_id;
        //bool voter_authorized;
        //uint roll_no;
        address voter_address;
        bool has_voted; // voted or not
        //uint vote_index; 
    }

    //Voters [] public voter_list;
    uint public votersCount; // gives total votes casted
    mapping (address => Voter) public voters;

    function addVoter(string memory _voter_name, string memory _email_id) public {
        require(msg.sender == chairperson,"Chairperson will give access to vote");
        //require(voters.vote_index == 0);
        //require(voters[msg.sender].voter_address == address(0), "Voter already added");
        votersCount++;
        voters[msg.sender] = Voter(votersCount, _voter_name, _email_id,  msg.sender, false);
        
            
    }

        //voters.has_voted = true;
        //voters.vote_index = 1; // give voter right to vote
        // here vote count is checking in
        //require(voters.has_voted == false,"You have already voted");

///-----------------------------------------------------------------------------------------------------
    
    uint public startTime;
    uint public stopTime;
    modifier chairpersonOnly() {
        require (msg.sender ==chairperson, "Chairman can set time limit");
        _;
    }
    function setStart(uint num) external chairpersonOnly{
        require(num >= block.timestamp , " voting starts, time is in unix seconds ");
        startTime = num; // add unix time
        
    }
    
    function setStop (uint num) external chairpersonOnly{
        require(num > block.timestamp && num > startTime, "Voting stops, time is in unix seconds");
        stopTime = num;
    }
//-------------Voting function-----------------
    function vote (uint _candidateid) public {
        require (block.timestamp > startTime, "Election not started");
        require (block.timestamp <= stopTime, "Election over");
        require (voters[msg.sender].has_voted == false, "Already voted");
        
        voters [msg.sender].has_voted == true;
        candidates[_candidateid].vote_count++;

        //emit voted (msg.sender, candidates[_candidateid]);
    }
    
// function for voting results-------------------------------
    function getresults()public view returns (Candidate memory candidate) {
        require (block.timestamp >= stopTime, "Election not yet finished");
         uint v;
         uint max = 0;
         for (uint i=1; i<=candidatesCount; i++){
             if (candidates[i].vote_count > max) {
                 max = candidates[i].vote_count;
                 v = i;
                
             }
         }
         return candidates[v];
    }
}
