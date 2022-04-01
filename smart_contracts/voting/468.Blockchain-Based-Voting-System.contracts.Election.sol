pragma solidity ^0.4.17;

contract Election {

    struct Candidate {
        uint id;
        string name;
        string partyName;
        uint voteCount;
        uint parcetange;
        uint marginWL;
        string winloss;
    }

    struct Voter {
        uint voterID;
        address voterAddress;
        string voterFastName;
        string voterLastName;
        uint voterGender;
        bool voterVoted;
    }

    mapping(uint => Candidate)public candidates;

    mapping(address => Voter) public VoterData;

    uint candidatesCount;
    uint totalVoteCount=0;
    uint voterCounts=0;

    event addCandidateEvent(uint _candidateId, string _candidateName, string _partyName);
    event addVoterEvent(uint _voterId, address _voterAddress, string _voterFastName,string _voterLastName, uint _voterGender,bool _voterVoted);
    event errorLog(string _errorLog);
    event votingLog(string _voterStatus);
    event winerName(string _winName);
    event winnerData(uint _id,string _name,string _partyName,uint _voteCount,uint _parcetange,uint marginWL,string _winloss);

    modifier checkVoterAddress(address _voterAddress){
        if(VoterData[_voterAddress].voterAddress == _voterAddress){
            _;
        } else {
            emit votingLog("You have not register for voting!");
        }
    }

    modifier voterVoteStatus(address _voterAddress){
        if(!VoterData[_voterAddress].voterVoted){
            _;
        } else {
            emit votingLog("You had voted for this time!");
        }
    }
	
    function Election() public {
         addCandidate("BJP","BJP");
         addCandidate("APP","APP");
         addCandidate("NCP","NCP");
    }

    function addCandidate(string _name,string _partyName) public{
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,_partyName,0,0,0,"N");

        emit addCandidateEvent(candidatesCount,_name,_partyName);
    }

    function addVoterData(address _Address,string _FName,string _LName, uint _Gender) public {
        if(VoterData[_Address].voterAddress == _Address)
        {
           emit errorLog("Register user");
        } else {
            voterCounts += 1;
            VoterData[_Address] = Voter(voterCounts, _Address, _FName, _LName, _Gender, false);

            emit addVoterEvent(voterCounts, _Address, _FName, _LName, _Gender,false);
        }
    }

    function vote(uint _candidateId,address _voterAddress) public checkVoterAddress(_voterAddress) voterVoteStatus(_voterAddress) {
        totalVoteCount +=1;
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        VoterData[_voterAddress].voterVoted = true;
        candidates[_candidateId].voteCount++;
        emit votingLog("Done");
    }

    function winer() public {
      uint winerId;
      uint totalcount=0;
      uint highparcentag=0;
      for(uint i=0; i <= candidatesCount; i++){
          candidates[i].parcetange = (candidates[i].voteCount * 100) / totalVoteCount;
          if(candidates[i].voteCount > totalcount){
                totalcount = candidates[i].voteCount;
                highparcentag = candidates[i].parcetange;
                winerId = i;
          }
      }
      setData(highparcentag);
      //return true;
      emit winerName("winer");
    }

    function setData(uint highparcent) private {
      uint winerData = Tiecheck(highparcent);
      for(uint i=0; i <= candidatesCount; i++){
      if(highparcent != candidates[i].parcetange ) {
        candidates[i].marginWL = (highparcent - candidates[i].parcetange);
        candidates[i].winloss ="Loss";
      } else {
             if(winerData == 1){
                 candidates[i].marginWL = (highparcent - candidates[i].parcetange);
                 candidates[i].winloss = "Won";
             }
             else {
               candidates[i].marginWL = (highparcent - candidates[i].parcetange);
               candidates[i].winloss = "Tie";
                }
        }
		emit winnerData(candidates[i].id,candidates[i].name,candidates[i].partyName,candidates[i].voteCount,candidates[i].parcetange,candidates[i].marginWL,candidates[i].winloss);
            		
      }
    }

    function Tiecheck(uint highparcent) private view returns(uint){
        uint chektie=0;
        for(uint x=0; x <= candidatesCount; x++){
            if(highparcent == candidates[x].parcetange)
            {
                chektie +=1;
            }
        }
        return chektie;
    }

    function getCondidateById(uint _id) private view returns(string,string,uint,uint,uint,string){
        return (candidates[_id].name,candidates[_id].partyName,candidates[_id].voteCount,candidates[_id].parcetange,candidates[_id].marginWL,candidates[_id].winloss);
    }

}
