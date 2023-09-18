//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Voting{
    uint noOfVoters;
    uint noOfCandidates;
    
    address admin;
    
    enum Phases {StartPhase, EnrollmentPhase, VotingPhase, ResultPhase}
    Phases electionPhases;

    struct Candidate{
        address candidate_address;
        string candidate_name;
        uint noOfVotes;
    }
   
    struct Voter{
        bool hasVoted;
        bool isValid;
    }
    
    mapping (uint => Candidate) public candidates;
    mapping (string => Voter) voters;
    mapping (address => Voter) eligibleVotersList;
    
    constructor(){
        admin = msg.sender;
        electionPhases = Phases.StartPhase;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"Only Admin");
        _;
    }
    function phaseChangeTo(uint phase) public onlyAdmin returns(string memory){
        if(phase == 0){
            electionPhases = Phases.StartPhase;
            return "Phase = StartPhase";
        }
        else if(phase == 1){
            electionPhases = Phases.EnrollmentPhase;
            return "Phase = EnrollmentPhase";
        }
        else if(phase == 2){
            electionPhases = Phases.VotingPhase;
            return "Phase = VotingPhase";
        }
        else if(phase == 3){
            electionPhases = Phases.ResultPhase;
            return "Phase = ResultPhase";
        }
        else{
            return "Enter Valid Phase";
        }
    }
    // voting phase should be there
    function candidateEnrollment(string memory name,address candidate_address) public onlyAdmin {
        require(electionPhases == Phases.EnrollmentPhase);
        uint candidateID = noOfCandidates++;
        candidates[candidateID] = Candidate(candidate_address,name,0);
        //Event emit
    }
    
    //vote ---> check if voted, eligible voter --> canditate id param --> Vote Struct ++ --> Bool , voting phase 
    // add voter --> admin only --> to add voter in mapping 
    // enum , enum phase change admin only function 
    function voterEnrollment(address voter_address) public onlyAdmin {
        require(electionPhases == Phases.EnrollmentPhase);
        require(eligibleVotersList[voter_address].isValid == false);
        eligibleVotersList[voter_address].isValid = true; 
        // eligibleVotersList[voter].voter_address = voter;
        noOfVoters++;    
    }
    function vote(uint candidateID) public returns(string memory){
        require(electionPhases == Phases.VotingPhase);
        require(eligibleVotersList[msg.sender].isValid == true);
        require(eligibleVotersList[msg.sender].hasVoted == false);
        candidates[candidateID].noOfVotes += 1;
        eligibleVotersList[msg.sender].hasVoted = true;
        return "You have successfully voted";
    }
    // result end 
    function results() public onlyAdmin view returns (string memory){
        require(electionPhases == Phases.ResultPhase);
        uint maxVotes = candidates[0].noOfVotes;
        uint candidateID;
        for(uint i = 0 ; i<noOfCandidates;i++) {
            if(maxVotes < candidates[i].noOfVotes) {
                maxVotes = candidates[i].noOfVotes;
                candidateID = i;
            }
        }
        return (candidates[candidateID].candidate_name);
    }
}
