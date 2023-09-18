pragma solidity >=0.4.9 <0.9.0;
pragma experimental ABIEncoderV2;
contract Election{
    address admin ;
    constructor(address _Admin) public{
     admin = _Admin;
    }
    uint256 CandidateCount =0;
    struct Candidates {
        string CandidateName;
        address  CandidateAddress;
        uint256 CandidateCitizenShip;
        string CandidateParty;
        uint256 votecount;
  }
  mapping(uint256 => Candidates) public candidate;
  function addCandidate(string  memory _candidateName, address _candidateAddress, uint256 _candidateCitizenship, string memory _candidateParty ) public{
       require(msg.sender == admin,"only admin can add candidates");
       bool newUser = true;
       for (uint i=0;i<CandidateCount;i++)
       {
           if(candidate[i].CandidateAddress == _candidateAddress)
           {
               newUser=false;
               break;
           }
       }
       require(newUser == true ,"Candidate is already registered");
  candidate[CandidateCount]=Candidates(_candidateName,_candidateAddress,_candidateCitizenship,_candidateParty,0);
  CandidateCount++;

  }
  function getAllCandidates() public view returns( Candidates[] memory){
       Candidates[] memory  ret = new Candidates[] (CandidateCount);
    for (uint i = 0; i < CandidateCount; i++) {
        ret[i] = candidate[i];
    }
    return ret;

  }
  function getNumberOfCandidate() public view returns(uint256){
      return CandidateCount;
  }
  function getCandidate(uint256 candidateId) public view returns(string memory,address ,uint256 ,string memory,uint256){
     Candidates memory ret = candidate[candidateId];
      return(ret.CandidateName,ret.CandidateAddress,ret.CandidateCitizenShip,ret.CandidateParty,ret.votecount);
  }
    uint256 VoterCounter=0;
    
    
    struct Voters {
        string VoterName;
        address VoterAddress;
        string VoterGender;
        uint  age;
        uint256 Citizennumber;
        bool voted;


    }
    mapping(uint256 => Voters) public voterdet;
   
    function addVoter(string memory _voterName, address _voterAddress, string memory _voterGender, uint _age, uint _citizenshipNumber) public{
       
       require(_age > 18,"age must be greater than 18 ");
       bool newVoter=true;
       for (uint i=0;i<VoterCounter;i++)
       {
           if(voterdet[i].VoterAddress == _voterAddress)
           {
               newVoter=false;
               break;
           }
       }
       require(newVoter == true ,"voter is already registered");
       
       voterdet[VoterCounter]= Voters(_voterName,_voterAddress,_voterGender,_age,_citizenshipNumber,false);
       VoterCounter++;
    }
    function getVoter(uint256 id) public view returns(Voters memory){
        return voterdet[id];
    }
  uint   election_Status=1;
     function Vote(uint256 CandidateId) public{
         for(uint i=0;i<VoterCounter;i++){
             require(msg.sender == voterdet[i].VoterAddress,"voter is not register bro");
         }
         require(election_Status ==1,"election is not started yet");
         for(uint i=0; i<VoterCounter; i++)
         {
             if(voterdet[i].VoterAddress == msg.sender)
             {
                
                 require(! voterdet[i].voted,"already voted");
                 voterdet[i].voted=true;
             }
         }
         candidate[CandidateId].votecount +=1;
         

     }
     function isStarted() public view returns(bool){
         bool status= false;
         if(election_Status == 1)
         {
             status=true;
         }
          return status;
     }
     function isStopped() public view returns(bool)
     {
        bool isstopped=false;
         if(election_Status==0)
         {
             isstopped=true;
         }
         return isstopped;
     }
     function startElection() public {
         require(msg.sender==admin,"only admin can start the elcetion");
         election_Status=1;

     }
     function stopElection() public {
         require(msg.sender == admin ,"only admin can stop the election");
         election_Status=0;
     }
     uint public winnerindex;
function CalculateWinner() private{
    uint winingVoteCount =0;
    for(uint  i=0;i<CandidateCount;i++)
    {
        if(candidate[i].votecount>winingVoteCount)
        {
            winingVoteCount=candidate[i].votecount;
            winnerindex=i;
        }

    }

}
function getWinerName() public view returns(string memory,string memory,uint256){
    return(candidate[winnerindex].CandidateName,candidate[winnerindex].CandidateParty,candidate[winnerindex].votecount);

}

}