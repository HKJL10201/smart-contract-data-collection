// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Voting {
    
    struct Voter{
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }
    
    struct Proposal{
        string name;
        uint voteCount;
    }
    
    address public chairperson;
    
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    
    modifier onlyChairperson {
        require(msg.sender == chairperson, "Only Chairperson can give right to vote");
        _;
    }
    
    constructor() public {
        string[3] memory proposalNames = ["FirstProposal","SecondProposal","ThirdProposal"];
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        for(uint i=0; i< proposalNames.length; i++){
            proposals.push(Proposal({name: proposalNames[0], voteCount:0}));
        }
    }
    
    
    function giveRightToVote(address voter) public onlyChairperson {
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted");
        require(to != msg.sender, "Self delegation is not allowed");
        while(voters[to].delegate != address(to)){
           to = voters[to].delegate;
           require(to != msg.sender, "Found loop in delegation");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage _delegate = voters[to];
        if(_delegate.voted){
            proposals[_delegate.vote].voteCount += sender.weight;
        }else{
            _delegate.weight += sender.weight;
        }
    }
    
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }
    
    function winningProposal() public view returns(uint _winningProposal){
        uint winningCount = 0;
        for(uint p=0; p <proposals.length; p++){
            if(proposals[p].voteCount > winningCount){
                winningCount = proposals[p].voteCount;
                _winningProposal = p;
            }
        }
    }
    
    function winnerName()public view returns (string memory _winnerName){
        _winnerName = proposals[winningProposal()].name;
    }
}