// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
contract Vote {
    address electionComision;
    address public winner;

    struct Voter {
        string name;
        uint age;
        uint voterId;
        string gender;
        uint voteCandidateId;
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint age;
        string gender;
        uint candidateId;
        address candidateAddress;
        uint votes;
    }

    uint nextVoterId = 1; //voter ID for voters
    uint nextCandidateId = 1; //candidate ID for candidates

    uint startTime; //startTime of election
    uint endTime; //endTime of election

    mapping(uint => Voter) voterDetails; //details of voters
    mapping(uint => Candidate) candidateDetails; //details of candidates
    bool stopVoting; //this for emergency situation to stop voting

    constructor() {
        electionComision = msg.sender; //assigning the deployer of the contract as the election commission
    }

    modifier isVotingOver() {
        require(block.timestamp > endTime || !stopVoting, "Voting is not over");
        _;
    }

    modifier onlyCommissioner() {
        require(electionComision == msg.sender, "Not from the election commission");
        _;
    }


    function candidateRegister(string calldata _name, string calldata _party, uint _age, string calldata _gender) external {
       require(msg.sender!=electionComision,"Election Commision not allowed");
       require(candidateVerification(msg.sender)==true,"Twice registration not possible");
       require(_age>18,"Inelgibile to vote");
       require(nextCandidateId<3,"Candidate registration over");
       candidateDetails[nextCandidateId]=Candidate(_name,_party,_age,_gender,nextCandidateId,msg.sender,0);
       nextCandidateId++;
    }

    function candidateVerification(address _person) internal view returns(bool) {
        for(uint i=1;i<nextCandidateId;i++){
            if(candidateDetails[i].candidateAddress==_person){
                return false;
            }
        }
        return true;
    }
    //initially - nextCandiateId = 1
    //Candidate registers - nextCandiate = 2
    //number of candidates = 1
    function candidateList() public view returns(Candidate[] memory) { //return entire candidate list
        Candidate[] memory array = new Candidate[](nextCandidateId-1);
        for(uint i=1;i<nextCandidateId;i++){
            array[i-1]=candidateDetails[i];
        }
        return array;
    }

    function voterRegister(string calldata _name, uint _age, string calldata _gender) external {
        require(voterVerification(msg.sender) == true, "Voter Already Registered");
        require(_age >= 18, "You are not eligible");
        voterDetails[nextVoterId] = Voter(_name, _age, nextVoterId, _gender, 0, msg.sender);
        nextVoterId++;
    }

    function voterVerification(address _person) internal view returns(bool) {
         for(uint i=1;i<nextVoterId;i++){
            if(voterDetails[i].voterAddress==_person){
                return false;
            }
        }
        return true;
    }

    function voterList() public view returns(Voter[] memory) {
        Voter[] memory array = new Voter[](nextVoterId -1);
        for(uint i=1;i<nextVoterId;i++){
            array[i-1]=voterDetails[i];
        }
        return array;
    }

    function vote(uint _voterId, uint _candidateId) external isVotingOver(){
       require(voterDetails[_voterId].voteCandidateId==0,"You have already voted");
       require(voterDetails[_voterId].voterAddress==msg.sender,"You are not a voter");
       require(startTime!=0,"Voting not yet started");
       require(nextCandidateId==3,"Canidates have not registered");
       require(_candidateId>=1 && _candidateId<3,"Invalid candidates id");
       voterDetails[_voterId].voteCandidateId=_candidateId;
       candidateDetails[_candidateId].votes++; //canidate vote increased by 1
    }

    function voteTime(uint _startTime, uint _endTime) external onlyCommissioner() {
        startTime=_startTime; 
        endTime=_startTime+_endTime;
    }

    function votingStatus() public view returns(string memory) {
       if(startTime==0){
           return "Voting has not started";
       }else if((startTime!=0 && endTime>block.timestamp) && stopVoting==false){
           return "Voting in progress";
       }else{
           return "Voting Ended";
       }
    }

    function result() external onlyCommissioner() {
       if(candidateDetails[1].votes>candidateDetails[2].votes){
           winner = candidateDetails[1].candidateAddress;
       }else{
            winner = candidateDetails[2].candidateAddress;
       }
    }

    function emergency() public onlyCommissioner() {
       stopVoting=true;
    }
}
