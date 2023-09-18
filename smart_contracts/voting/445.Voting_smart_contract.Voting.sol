// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract voting{
    address public chairman;
    constructor(){
        chairman=msg.sender;
        setcandidate("Yogi","Graduated");
        setcandidate("Modi","Matrix");
    }
    struct candidate{
        uint Voterid;
        string candidateName;
        string Education;
        uint numberofVotes;
    }
    mapping(uint=>candidate) public Candidates;
    uint public candidateCount;
    mapping(address=>bool) public voter;

    function vote(uint _id) public{
        require(voter[msg.sender]==false,"you have already voted.");
        require(_id>0 && _id<=candidateCount,"No candidate with such id exist");
        voter[msg.sender]=true;
        Candidates[_id].numberofVotes++;
    }

    function setcandidate(string memory _candidateName,string memory _education) private{
        require(msg.sender==chairman,"only chairman can set the candidates.");
        candidateCount++;
        Candidates[candidateCount]=candidate(candidateCount,_candidateName,_education,0);
    }
    function winner() public view returns(string memory){
        if(Candidates[1].numberofVotes>Candidates[2].numberofVotes){
                 return Candidates[1].candidateName;     
        }
    }
}