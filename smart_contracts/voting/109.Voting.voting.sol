// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract vote{
 address public electionCommission;  // deployer
 address winner;  // check the winner

 struct voter{    // voter details
     string name;
     uint age;
     string gender;
     uint voterId;
     uint voterCandidateId; //which party he have voted
     address voterAddress;
 }

 struct candidate{ // candidate details
     string name;
     string party;
     uint age;
     string gender;
     uint candidateId;
     address candidateAddress;
     uint votes;
 }

    uint nextVoterId=1; //increment when a voter register
    uint nextCandidateId=1; //increment when a candidate register
    uint startTime; // block.timestamp in seconds
    uint endTime; // block.timestamp in seconds

    mapping(uint => voter) voterDetails;
    mapping(uint => candidate) candidateDetails;

    bool stopVoting; // electionCommission has the autority to stop voting incase of emergency
  constructor(){
      electionCommission = msg.sender; // deployer will be the electionCommission
  }

  function candidateRegister(string calldata _name, string calldata _party, uint _age, string calldata _gender)external candidateSlot checkElectionStops {  // register candidate
   require(candidateAlreadyReg(msg.sender),"You have Already registered");
   require(_age >= 18 ,"Youre are Below 18 years");
   candidateDetails[nextCandidateId]=candidate(_name, _party, _age, _gender,nextCandidateId,msg.sender,0);  
   nextCandidateId++;
  }

  function voterRegister(string calldata _name, uint _age, string calldata _gender)external checkElectionStops{  // register candidate
   require(voterAlreadyReg(msg.sender),"You have Already registered");
   require(_age >= 18 ,"You're are Below 18 years");
   voterDetails[nextVoterId]=voter(_name, _age, _gender,nextVoterId,0,msg.sender);
   nextVoterId++;
  }
  function candidateAlreadyReg(address _person) internal view returns (bool){   //check whether the candidate is registering for the second time
  for(uint i=1; i< nextCandidateId ;i++){
       if(candidateDetails[i].candidateAddress == _person){
         return false;
     }
     }
    return true;
  }
  function voterAlreadyReg(address _voter) internal view returns (bool){   //check whether the Voter is registering for the second time
  for(uint i=1; i< nextVoterId ;i++){
       if(voterDetails[i].voterAddress == _voter){
         return false;
     }
     }
    return true;
  }
  function candidateList() public view returns( candidate[] memory){
      candidate[] memory arr = new candidate[](nextCandidateId-1); // creating a new empty array with specified length
      for(uint i=1; i< nextCandidateId ;i++){
          arr[i-1]=candidateDetails[i];
      }
      return arr;
  }
  function VoterList() external view returns( voter[] memory){ //Voter
      voter[] memory votearr = new voter[](nextVoterId-1); // creating a new empty array with specified length
      for(uint i=1; i< nextVoterId ;i++){
          votearr[i-1]=voterDetails[i];
      }
      return votearr;
  }
   
   function electionVotingStarts(uint _startTime , uint _endTime) external electionRights { //Voting start and End Time
         startTime=block.timestamp + _startTime; 
         endTime = startTime+_endTime;
         stopVoting=false;
   }
    function votingProcess(uint _voterId , uint _canId) public checkElectionStops voteInProgress{  //Votimg Procedure
       require(_canId > 0 && _canId <= nextCandidateId,"Candidate Id does not exist" );
       require(_voterId > 0 && _voterId <= nextVoterId,"VoterId does not exist" );
      //require(nextCandidateId > 2 , "Party is not yet fullfilled , Wait for Sometime");
       require(voterDetails[_voterId].voterAddress == msg.sender,"You are not an regisered Voter, Kindly Register first!");
       require(voterDetails[_voterId].voterCandidateId == 0 , "You have already Voted");
       candidateDetails[_canId].votes++;
       voterDetails[_voterId].voterCandidateId=_canId;
   }

   function StopVoting() external {
        require(electionCommission == msg.sender , "Only Electioncommission has the rights ");
        stopVoting=true;
    }
    function voteStatus() public view returns(string memory){
        if(startTime == 0 || startTime > block.timestamp  ){
            return "Voting has Not started";
        }else if((startTime < block.timestamp  && endTime > block.timestamp) && stopVoting == false){
            return "Voting is in Progress";
        }else{
             return "Voting Ended";
        }
    }
    function VoteResult() public electionRights {
      require(block.timestamp > endTime && stopVoting == false,"Voting is in progress" );
      candidate[] memory arrs = new candidate[](nextCandidateId-1);
      uint max=0;
      arrs =candidateList();
      arrs[0].votes > arrs[1].votes ?  winner=arrs[0].candidateAddress : arrs[1].candidateAddress;
        for(uint v=1;v> arrs.length;v++){
            if( arrs[v].votes > max){
                max=arrs[v].votes;
                winner= arrs[v].candidateAddress;
            }
        }
    }
    function ShowWinner() public view returns(address){
     require( winner != address(0) , "Winner Has not Declared yet");
      return winner;
  }
   modifier candidateSlot() {
        require(nextCandidateId < 3 ,"Registration is full for this Voting Period");
        _;
    }
   modifier voteInProgress() {
        require(startTime < block.timestamp , "Voting has not started yet!");
       require(endTime > block.timestamp , "Voting has been Ended , will declare the Winner soon !");
        _;
    }
    modifier electionRights() {
        require(electionCommission == msg.sender , "Only Electioncommission has the rights ");
        _;
    }
    modifier checkElectionStops() {
        require(stopVoting == false , "Voting is Stopped by ElectionCommisiion Due to Some reasons");
        _;
    }
} 
