// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

error VotingContract__YouHaveVotedAlready();
error VotingContract__VotingIsOver();
contract VotingContract{
    address private manager;
    mapping(address => bool) presidentVote;
    mapping(address => bool) vicePresidentVote;
    mapping(address => bool) secretaryVote;
    //Determine the voting App State
     enum VotingState {
    OPEN,
    CLOSED
  }
  VotingState public s_votingState;
     
    constructor(){
        manager = msg.sender;
        s_votingState = VotingState.OPEN;
    }

    struct Candidates{
        string s_fullName;
        string s_department;
        string s_matricNumber;
        string image;
        uint256 s_voteCount;
        string s_role;
    }
     mapping (uint256 => Candidates) public users;
    //Modifier
    modifier onlyManager{
        require(msg.sender == manager);
        _;
    }
//Check the Vote Role Status
function checkRoleStatus (string memory person, string memory role, string memory err) public pure {
     require((keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked((role)))), err);
}
//Store the candidates in an array
    Candidates [] public candidates;
    function addCandidates(string memory fullName, string memory department, string memory matricNumber, string memory image, uint256 voteCount, string memory role ) public onlyManager{
        Candidates memory newCandidate = Candidates(fullName, department, matricNumber, image, voteCount, role);
        candidates.push(newCandidate);
    }
    function voteForPresident(uint256 index) public {
         if(s_votingState == VotingState.CLOSED){
             revert  VotingContract__VotingIsOver();
         }else{
               checkRoleStatus(candidates[index].s_role, "President", "Wrong Category P"); 
        if(presidentVote[msg.sender]){
            revert VotingContract__YouHaveVotedAlready();
        }else{
         candidates[index].s_voteCount +=1;
        presidentVote[msg.sender] = true;
        }
         }
        
       
    }
      function voteForVicePresident(uint256 index) public {
         if(s_votingState == VotingState.CLOSED){
             revert  VotingContract__VotingIsOver();
         }else{
        checkRoleStatus(candidates[index].s_role, "Vice President", "Wrong Category Vp"); 
        if(vicePresidentVote[msg.sender]){
            revert VotingContract__YouHaveVotedAlready();
        }else{
         candidates[index].s_voteCount +=1;
        vicePresidentVote[msg.sender] = true;
        }
         }
        
       
    }
     function voteForSecretary(uint256 index) public {
         if(s_votingState == VotingState.CLOSED){
             revert  VotingContract__VotingIsOver();
         }else{
               checkRoleStatus(candidates[index].s_role, "Secretary", "Wrong Category S"); 
        if(secretaryVote[msg.sender]){
            revert VotingContract__YouHaveVotedAlready();
        }else{
         candidates[index].s_voteCount +=1;
        secretaryVote[msg.sender] = true;
        }
         }  
    }
    //Get All Candidates
    function getAllCandidate() public view returns (Candidates[] memory) {
        return candidates;
    }
    //Stop Voting
    function stopVoting () onlyManager public {
        s_votingState = VotingState.CLOSED;
    }
    
}