//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

contract Vote{
    address electionComision;
    address public winner;

    struct Voter{
        string name;
        uint age;
        uint voterId;
        string gender;
        uint voteCandidateId;
        address voterAddress;
    }
    struct Candidate{
        string name;
        string party;
        uint age;
        string gender;
        uint candidateId;
        address candidateAddress;
        uint votes;
    }
    uint nextVoterId=1;// starting voterid with 1
    uint nextCandidateId=1;// starting candidateid with 1
    uint startTime;//startime of election
    uint endTime;//end time of election
    mapping(uint=>Voter) voterDetails;//details of voters
    mapping(uint=>Candidate) candidateDetails;///details of candidates
    bool stopVoting;//This  is used to stop the voting process in emergency situation
    constructor(){
        electionComision=msg.sender;//assigning the deployer of contract as election commision
    }
    modifier isVotingOver(){
        require(block.timestamp >endTime ||stopVoting ==true,"voting is not over");
        _;
    }
    modifier onlyCommisioner(){
        require(electionComision== msg.sender,"You are not election commisioner");
        _;
    }
    function candidateRegister(//registration for the candidate
        string calldata _name,
        string calldata _party,
        uint _age,
        string calldata _gender
    )external {
         require(msg.sender!=electionComision,"Election Comision not eligible for candidate registration");
        require(candidateVerification(msg.sender),"Candidate Already Registered");
        require(_age>=18,"You are not eligible");
        require(nextCandidateId<3,"Candidate registration");
        candidateDetails[nextCandidateId]=Candidate(_name, _party,_age,_gender,nextCandidateId,msg.sender,0);
        nextCandidateId++;
    }
    function candidateVerification(address _person) internal view returns(bool){
        for(uint i=1; i<=nextCandidateId; i++){
            if(candidateDetails[i].candidateAddress==_person){
                return false;
            }
        }
        return true;
    }
    function candidateList() public view returns(Candidate[] memory){
        Candidate[] memory array=new Candidate[](nextCandidateId-1);
        for(uint i=1;i<nextCandidateId;i++){
            array[i-1]=candidateDetails[i];
        }
        return array;
    }
    function voterRegister(string calldata _name, uint _age, string calldata _gender)external {
        require(voterVerification(msg.sender),"voter Already Registered");
        require(_age>=18,"You are not eligible");
        voterDetails[nextVoterId]=Voter(_name,_age,nextVoterId,_gender,0,msg.sender);
        nextVoterId++;
    }
    function voterVerification(address _person) internal view returns (bool){
        for(uint i=1;i<nextVoterId;i++){
            if(voterDetails[i].voterAddress== _person){
                return false;
            }
        }
        return true;
    }
    function voterList() public view returns (Voter[] memory){
        Voter[] memory array= new Voter[](nextVoterId-1);
        for(uint i=1;i<nextVoterId;i++){
            array[i-1]=voterDetails[i];
        }
        return array;
    }
    function vote(uint _voterId, uint _id)external {
        require(voterDetails[_voterId].voteCandidateId==0,"Voting already done");
        require(voterDetails[_voterId].voterAddress==msg.sender,"You are not registered"); 
        require(startTime!=0,"voting has not started");
        require(nextCandidateId==3,"Candidate has not registered");
        voterDetails[_voterId].voteCandidateId=_id;
        candidateDetails[_id].votes++;
    }
    function voteTime(uint _startTime,uint _endTime)external onlyCommisioner(){
        startTime=_startTime+ block.timestamp; 
        endTime=startTime+_endTime;
    }
    function votingStatus() public view returns(string memory){
        if(startTime==0){
            return "Voting has not started";
        }
        else if((endTime>block.timestamp) && stopVoting==false){
            return "Voting is in progress";
        }
        else{
            return "Voting Ended";
        }
    }
    function result() external onlyCommisioner(){
        uint max;
        for (uint i=1;i<nextCandidateId;i++){
            if(candidateDetails[i].votes>max){
                max=candidateDetails[i].votes;
                winner=candidateDetails[i].candidateAddress;
            }
        }
    }
    function emergency() public onlyCommisioner(){
        stopVoting =true;
    }




    
    



}
