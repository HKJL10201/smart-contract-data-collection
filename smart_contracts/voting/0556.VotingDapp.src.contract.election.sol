// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
// Smart Contract for the Voting application
contract VotingForPurpose{
 
      // Refer to the owner
    address  owner;
    
    constructor(){  
        owner = msg.sender;
    }

    struct Election{
        uint id;
        string purpose;
        uint status;
        uint[] candidatesids;
        uint totalVotes;
    }
 
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string slogan;
        uint election_id;
    }

    struct Voter{
        string votername;
        bool authorized; 
    }

    mapping(address=>mapping(uint=>bool)) voted;
    mapping(uint => Election) public elections; 
    mapping(uint => Candidate) public candidates;
    mapping(address=>Voter) public voters;
    address[] voterslist;

    uint public candidatesCount;
    uint public electionCount;
    uint public totalregisteredvoters;

    modifier ownerOn() {
       require(msg.sender==owner);
       _;
    }

    modifier checkvote(address _address,uint _candidateID,uint _electionid) {
        require(_address == msg.sender,"You can only cast your own vote");
        require(elections[_electionid].candidatesids.length>=2 && elections[_electionid].status==2,"Voting has not started");
        require(candidates[_candidateID].election_id==_electionid,"Not a valid candidate");
        require(!voted[_address][_electionid],"You have already voted");
        require(voters[_address].authorized,"You have no right to Vote");
       _;
    }

    function isAdmin(address user) public view returns(bool){
        return owner==msg.sender || owner == user;
    }

    function createElection(string memory _purpose) public ownerOn{
        electionCount++;
        elections[electionCount]=Election(electionCount,_purpose,1,new uint[](0),0);
    }
      
    function addCandidate(string memory _name, string memory _details, uint _election_id) public ownerOn {
        require(_election_id<=electionCount && uint(elections[_election_id].status)==1,"Election is not created");
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _details, _election_id);
        elections[_election_id].candidatesids.push(candidatesCount);
    }

    function addVoter(address _voteraddress,string memory _votername)
    public {
        require(msg.sender != owner,"Only voter can register himself");
        require(bytes(voters[msg.sender].votername).length==0,"Voter already added");
        voters[_voteraddress]=Voter(_votername,false);
        voterslist.push(_voteraddress);
        totalregisteredvoters++;
    }

    function authorize(
     address _voter) public ownerOn{
        voters[_voter].authorized= true;     
    }

    function startVoting(uint _electionid) public ownerOn{
        require(elections[_electionid].status==1 && elections[_electionid].candidatesids.length>=2);
        elections[_electionid].status=2;
    }

    function endElection(uint _electionid) public ownerOn{ 
        require(elections[_electionid].status==2);
        elections[_electionid].status=3;
    }
    
    function vote(address _address,uint _candidateID,uint _electionid) public checkvote(_address,_candidateID,_electionid){
        voted[_address][_electionid]=true;
        candidates[_candidateID].voteCount++;
        elections[_electionid].totalVotes++;
    }
 
    function totalVotesofElection(uint _electionid) public view returns(uint){
        return elections[_electionid].totalVotes;
    }

    function totalVotesofCandidate(uint _candidateid) public view returns(uint){
        return candidates[_candidateid].voteCount;
    }

    function noOfElections() public view returns(uint){
        return electionCount;
    }
    function noOfCandidates() public view returns(uint){
        return candidatesCount;
    }
    function noOfTotalRegisteredVoters() public view ownerOn returns(uint){
        return totalregisteredvoters;
    }

    function totalRegisteredVoters() public view ownerOn returns(address[] memory){
        return voterslist;
    }

    function getElection(uint _electionid) public view returns(Election memory){
        require(_electionid<=electionCount,"Invalid Election");
        return elections[_electionid];
    }

    function getCandidate(uint _candidateid) public view returns(Candidate memory){
        require(_candidateid<=candidatesCount,"Invalid Candidate");
        return candidates[_candidateid];
    } 

    function getVoterdetails(address _voteraddress) public view returns(Voter memory){
        require(msg.sender==owner || msg.sender==_voteraddress,"Only the voter and admin can check the details");
        require(bytes(voters[_voteraddress].votername).length!=0,"Invalid Voter");
        return voters[_voteraddress];
    } 

    function deleteElection(uint election_id) public ownerOn{
        delete elections[election_id];
    }

    function hasVoted(address _voteraddress,uint election_id) public view returns(bool){
        require(msg.sender==owner || msg.sender==_voteraddress,"Only the voter and admin can check the details");
        return voted[_voteraddress][election_id];
    } 

    function getCandidates(uint _election_id) public view returns(uint[] memory){
        return elections[_election_id].candidatesids;
    }
}