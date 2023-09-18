// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Voting{
    enum Parties {
        APC,
        PDP,
        LP
    }
    
    struct Voter{
        address voter;
        string voterName;
        uint votersID;
        Parties parties;
    }
    mapping (uint => Voter) mapVoter;
    // Voter voters;
uint _votersId;
    function vote(  string memory _voterName, Parties _parties) public  {
         Voter storage voters = mapVoter[_votersId];
       _votersId +=1;
    
     mapVoter[_votersId].voterName =  _voterName;
    mapVoter[_votersId].votersID  = _votersId;
     mapVoter[_votersId].voter = msg.sender;
     mapVoter[_votersId].parties =  _parties;
    }
    function getVotersDetails(uint votersId) public view returns(string memory, address, Parties){
        Voter storage voters = mapVoter[votersId];
        return (voters.voterName, voters.voter, voters.parties);
    }
    function getResult(uint votersId) public view returns ( string memory){
         Voter storage voters = mapVoter[votersId];
       if (voters.parties == Parties.APC){
          return  string(abi.encodePacked(voters.parties, "APC"));
        //    return  (voters.parties, "APC");
       } else  if (voters.parties == Parties.PDP){
           return  string(abi.encodePacked(voters.parties, "PDP"));
            //  return  (voters.parties, "PDP");
       }else if(voters.parties == Parties.LP){
           return  string(abi.encodePacked(voters.parties, "LP"));
       }
    }
}


