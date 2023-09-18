pragma solidity ^0.5.16;
contract Election{
    //modelling candidate
        struct candidate{
            uint id;
            string name;
            uint voteCount;
        }
        //store n fetch candidates
        mapping(uint => candidate) public candidates;
        //store voters
        mapping(address => bool) public voters;
        //no of candidates
        uint public candidatecount;
        //event
        event votedevent(uint indexed _candidateid);
        constructor() public{
        addcand("Congress");
        addcand("BJP");
        addcand("AAP");
        addcand("Other");
        }
        
        function addcand(string memory _name) private{
            candidatecount++;
            candidates[candidatecount]= candidate(candidatecount,_name,0);
        }
        //to cast a vote
        function vote(uint _candidateid) public{
            require(!voters[msg.sender]);
            require(_candidateid>0 && _candidateid<= candidatecount);
            voters[msg.sender]=true;
            candidates[_candidateid].voteCount++;
            emit votedevent(_candidateid);
        }
        
}