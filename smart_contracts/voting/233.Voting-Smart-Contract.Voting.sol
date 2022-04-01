// SPDX-License-Identifier: GPL-3.0

//Objective:
//Only Authority of Election Commission can add candidates
//Anyone can view listed candidates (Candidate Id)
//Anyone can vote (the Candidate Id)
//Show the Winner till now

pragma solidity >=0.7.0 <0.9.0;

contract voting{

//Candidate Details
struct candidate{
    uint id;
    string name;
    uint voteCount;
}

//candidateId => candidate  
mapping (uint=>candidate) candidates;  //"candidates[uint id]" gives "candidate"


uint private candidateId;
address public electionAuthority;

constructor(){
    electionAuthority = msg.sender;
}

modifier onlyAuthority(){
require(msg.sender==electionAuthority,"Accessible to Election Commision Authority only");
_;
}

//Adding canidates through candidateId settings
function addCandidate(string memory _name) public onlyAuthority{
   candidateId++;
   candidates[candidateId] = candidate(candidateId,_name,0);
}

//Get Voter's list
function candidateDetailsfromId(uint Id) external returns(candidate memory){
    emit candidateDetailsOrder("Candidate Id","Candidate Name","Candidate Vote Count");
    return candidates[Id];
}

//To let know audience how to read details
event candidateDetailsOrder(string id,string name,string votecount);

//Return array of candidate details
candidate[] candidateList;
//See candidate list
function seeCandidateList() external returns(candidate[] memory){

    for(uint id=1;id<=candidateId;id++)
    {candidateList.push(candidates[id]);}

    emit candidateDetailsOrder("Candidate Id","Candidate Name","Candidate Vote Count");
    return candidateList;
}

//voter=>voted or not
mapping (address=>bool) voter;

modifier validateVoter(){
 require(!voter[msg.sender],"You have already voted"); //If voter has not voted can vote
 _;
}

function vote(uint _candidateId) public validateVoter{
    require(_candidateId>0 && _candidateId<=candidateId,"Enter Valid Id"); //_candidateId should be the valid one
    voter[msg.sender]=true;
    candidates[_candidateId].voteCount++; //Increment candidate's votecount that is attached to particular candidate Id
}

//See who is winning
function winnerTillNow() public view returns(string memory){
    string memory winner;
    uint maxi;
 
   for(uint id=1;id<=candidateId;id++){ 
       if(candidates[id].voteCount > maxi){  
       maxi=candidates[id].voteCount;
       winner=candidates[id].name;
    }}
    return winner;
 }

}
