//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract vote{

    address public electionCommision;
    address public winner;

    struct voter{

        string name;
        uint age;
        uint voterId;
        string gender;
        uint voterCandidateId;
        address voterAddress;

    }

    struct candidate{
        string name;
        string party;
        uint age;
        string gender;
        uint candidateId;
        address candidateAddress;
        uint votes;
    }

    uint nextVoterId =1;
    uint nextCandidateId = 1;
    uint startTime;
    uint endTime;

    mapping (uint => voter ) voterDetails;
    mapping (uint => candidate) candidateDetails;

    bool stopVoting; //only by election commision

    voter[] private voteArr;

    constructor(){
        electionCommision = msg.sender;
    }

    function candidateRegistration (string calldata _name, string calldata _party, uint _age, string calldata _gender) external{
        
        require(candidateVerification(msg.sender),"you are already registered");
        require(_age>=18,"you are quite young");
        require(nextCandidateId<3,"registration full");
        candidateDetails[nextCandidateId]=candidate(_name,_party,_age,_gender,nextCandidateId,msg.sender,0);
        nextCandidateId++;
    } 

    function candidateVerification (address _person) internal  view returns(bool){

        for(uint i=1; i <= nextCandidateId; i++){
            if(candidateDetails[i].candidateAddress == _person){
                return false;
            }
            else{
                return true;
            }
        }
    }

    function candidateList () internal view returns( candidate[] memory){

        candidate[] memory arr = new candidate[](nextCandidateId-1);

        for (uint i =1; i<nextCandidateId;i++){
            arr[i-1]= candidateDetails[i];
        }

    return arr;
    }

    function voterRegister(string calldata _name,

        uint _age,string calldata _gender) external{



        require(voterVerification(msg.sender),"You have already registrated");

        require(_age>=18,"You are not eligbile to vote");

        voterDetails[nextVoterId]=voter(_name,_age,nextVoterId,_gender,0,msg.sender);   



        nextVoterId++;

    }

    function voterVerification(address _user) internal view returns(bool) {

        for(uint i=1;i<nextVoterId;i++){

        if(voterDetails[i].voterAddress==_user){

        return false;

        }       

        }

        return true;

        }   



    function voterList() public view returns(voter[] memory){

        voter[] memory arr=new voter[](nextVoterId-1);

        for(uint i=1;i<nextVoterId;i++){

        arr[i-1]=voterDetails[i];

        }

        return arr;

        }



    function Vote(uint _voterId,uint _id) external isVotingOver(){

        require(voterDetails[_voterId].voterCandidateId==0,"You have already voted");

        require(voterDetails[_voterId].voterAddress==msg.sender,"You are not registered");

        require(block.timestamp>startTime,"Voting has not started");

        require(nextCandidateId>2,"Canidate registration is not done yet");

        require(_id>0 && _id<3,"Candidate does not exist");

        voterDetails[_voterId].voterCandidateId=_id;

        candidateDetails[_id].votes++;

    }



    function voteTime(uint _startTime,uint _endTime) external {

        require(electionCommision==msg.sender,"You are not from election commision");

        startTime=block.timestamp+_startTime;//5pm+5 minutes = 5:05 minutes

        endTime=startTime+_endTime;//5:05+20 minute= 5:25 minutes

        stopVoting=false;

    }



    function votingStatus() external view returns(string memory){

        if(startTime==0){

        return "Voting Not Started";

        }
        else if((startTime!=0 && endTime>block.timestamp) && stopVoting==false){

        return "Voting in progress";

        }
        else{

        return "Voting Ended";

        }

    }



    function result() external{

        require(electionCommision==msg.sender,"You are not from election commision");

        candidate[] memory arr= new candidate[](nextCandidateId-1);

        arr = candidateList();

        if(arr[0].votes>arr[1].votes){

        winner = arr[0].candidateAddress;

        }else{

        winner = arr[1].candidateAddress;

        }

    }



    function emergency() public {

        require(electionCommision==msg.sender,"You are not from election commision");

        stopVoting=true;

    }



    modifier isVotingOver(){

        require(endTime>block.timestamp || stopVoting,"Voting is over");

        _;

    }


}
