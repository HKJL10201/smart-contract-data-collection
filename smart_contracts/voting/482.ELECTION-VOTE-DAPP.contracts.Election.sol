// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract Election{
    uint  public noOfCandidates;
    struct candidate{
        uint id;
        string name;
        uint noOfVotes;
    }
    mapping(uint=>candidate) public candidates;
    mapping(address=>bool) public voted;
    event electionupdate(
        uint id,
        string name,
        uint noOfVotes
    );
    constructor(){
          addCandidates("BJP");
          addCandidates("UPA");
          addCandidates("AAP");
    }

    function addCandidates(string memory name) private{
        noOfCandidates++;
        candidates[noOfCandidates]=candidate(noOfCandidates,name,0);
    }

    function voteCandidate(uint _id)  public{
        require(!voted[msg.sender],"already voted!");
        require(_id!=0 && _id<=noOfCandidates,"not found candidate");
        candidates[_id].noOfVotes++;
        voted[msg.sender]=true;
        emit electionupdate(_id,candidates[_id].name,candidates[_id].noOfVotes);
    }

}