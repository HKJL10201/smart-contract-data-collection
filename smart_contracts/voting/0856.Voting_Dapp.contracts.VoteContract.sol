// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;



contract VoteContract {

   address public owner;
   uint ElectionsCounter;

   struct Candidate{
      string name;
      uint voteCount;
      uint candidateId;
   }

   struct Voter{
      address voterAddress;
      string name;
      string uniqueID;
      bool hasVoted;
      bool isVerified;
   }

   struct Election{
      address election_owner;
      string title;
      Voter[] Election_Voters;
      Candidate[] Election_Candidates;
      bool start;
      bool end;
      uint candidateCount;
      uint voterCount;
   }
   
   mapping(uint => Election) public Elections;

   constructor(){
      owner = msg.sender;
      ElectionsCounter = 0;
   }

   //modifier to specify functions that only the election creator/admin can access
   modifier onlyElectionAdmin(uint _electionID){
      require(Elections[_electionID].election_owner == msg.sender);
      _;
   }

   // this function is used to create a new election
   function createElection(string memory _title) public {
      Elections[ElectionsCounter].election_owner = msg.sender;
      Elections[ElectionsCounter].title = _title;
      Elections[ElectionsCounter].start = false;
      Elections[ElectionsCounter].end = false;
      Elections[ElectionsCounter].candidateCount = 0;
      Elections[ElectionsCounter].voterCount = 0;
      ElectionsCounter++;

   }

   // Only election creator/admin has access to this function
   function addCandidate(string memory _name, uint _electionID) public onlyElectionAdmin(_electionID){
      Elections[_electionID].Election_Candidates.push(Candidate({
         name:_name,
         voteCount: 0,
         candidateId : Elections[_electionID].candidateCount
      }));
      Elections[_electionID].candidateCount += 1;
   }

   // request to be added as voter
   function applyToVote(string memory _name, string memory _uniqueID, uint _electionID) public {
      Elections[_electionID].Election_Voters.push(Voter({
         voterAddress : msg.sender,
         name : _name,
         uniqueID : _uniqueID,
         hasVoted : false,
         isVerified : false
      }));
      Elections[_electionID].voterCount +=1;
   }

   //Voting function 
   function vote(uint candidateId, uint _electionID) public{
      uint voterNumber;
      for(uint i=0;i<Elections[_electionID].voterCount;i++){
         if(Elections[_electionID].Election_Voters[i].voterAddress == msg.sender){
            voterNumber = i;
         }
      }
      require(Elections[_electionID].Election_Voters[voterNumber].hasVoted == false);  // require that voter hasn't voted already.
      require(Elections[_electionID].Election_Voters[voterNumber].isVerified == true); // require that voter is verified.
      require(Elections[_electionID].start == true); // require that the voting process has started
      require(Elections[_electionID].end == false);  // and has not ended yet
      Elections[_electionID].Election_Candidates[candidateId].voteCount += 1;
      Elections[_electionID].Election_Voters[voterNumber].hasVoted = true;
   }

   // verify a specific voter address
   function verifyVoter(address _address, uint _electionID) public onlyElectionAdmin(_electionID){
      uint voterNumber;
      for(uint i=0;i<Elections[_electionID].voterCount;i++){
         if(Elections[_electionID].Election_Voters[i].voterAddress == _address){
            voterNumber = i;
         }
      }
      Elections[_electionID].Election_Voters[voterNumber].isVerified = true;
   }

   // start the voting process
   function startElection(uint _electionID) public onlyElectionAdmin(_electionID){
      Elections[_electionID].start = true;
      Elections[_electionID].end = false;
   }

   // end the voting process
   function endElection(uint _electionID) public onlyElectionAdmin(_electionID){
      Elections[_electionID].end = true;
      Elections[_electionID].start = false;
   }

   // return start value to know if voting process has started
   function getStart(uint _electionID) public view returns (bool) {
      return Elections[_electionID].start;
   }

   // return end value to know if voting process has ended
   function getEnd(uint _electionID) public view returns (bool) {
      return Elections[_electionID].end;
   }

   // get the address of the owner of a specific election
   function getElectionOwner(uint _electionID) public view returns(address){
      return Elections[_electionID].election_owner;
   }

   // get a specific election name based on ID
   function getElectionName(uint _electionID) public view returns(string memory){
      return Elections[_electionID].title;
   }

   // get total number of elections created
   function getElectionsCounter() public view returns(uint){
      return ElectionsCounter;
   }
   
   // get total number of candidates of a specific election
   function getCandidateNumber(uint _electionID) public view returns (uint) {
      return Elections[_electionID].candidateCount;
   }
  
   // get total number of voters
   function getVoterCount(uint _electionID) public view returns (uint) {
      return Elections[_electionID].voterCount;
   }

   //check if given voterID already exists in the list
   function voterExists(uint _electionID,string memory _voterID) public view returns(bool){
      for(uint i=0; i < Elections[_electionID].voterCount;i++){
         //use this cause solidity doesn't support string comparison with '=='
         if(keccak256(bytes(Elections[_electionID].Election_Voters[i].uniqueID)) == keccak256(bytes(_voterID))){
            return true;
         }
      }
      return false;
   }
   
   // return status of specified voter (is he verified? did he already vote?)
   function getVotingDetails(address _address,uint _electionID)public view returns(bool isVerified,bool hasVoted){
      for(uint i=0;i<Elections[_electionID].voterCount;i++){
         if(Elections[_electionID].Election_Voters[i].voterAddress == _address){
            return (Elections[_electionID].Election_Voters[i].isVerified, Elections[_electionID].Election_Voters[i].hasVoted);
         }
      }
   }
   
   // return true if voter has already registered for the election given
   function isVoterRegistered(address _address,uint _electionID) public view returns(bool isRegistered){
      for(uint i=0;i<Elections[_electionID].voterCount;i++){
         if(Elections[_electionID].Election_Voters[i].voterAddress == _address){
            return true;
         }
      }
      return false;
   }

   //get all the candidates from a specific election
   function getCandidates(uint _electionID) public view returns(Candidate [] memory){
      return Elections[_electionID].Election_Candidates;
   }

   //get all the voters from a specific Election
   function getVoters(uint _electionID) public view returns(Voter [] memory){
      return Elections[_electionID].Election_Voters;
   }
}