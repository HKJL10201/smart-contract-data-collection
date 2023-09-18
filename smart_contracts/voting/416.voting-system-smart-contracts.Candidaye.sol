pragma solidity >=0.4.9 <0.9.0;
pragma experimental ABIEncoderV2;
contract Candidate{
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


}