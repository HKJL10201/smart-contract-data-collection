pragma solidity >=0.7.0 <0.9.0;

contract Voting{
    
    struct Condidate{
        uint id;
        string name;
        uint128 voteCount;
    }
    
    mapping(uint=>Condidate)Condidates;
    mapping(address=>bool)Participants;
    
    address owner;
    uint128 public condidateCount;
    
    constructor()public{
        owner = msg.sender;
    }
    
    function Add(string memory name) public returns(stirng memory){
        require(owner == msg.sender,"Error");
        condidateCount++;
        Condidates[condidateCount] = Condidate(condidateCount,name,0);
        returns "Add Condidate in Success";
    }
    
    function Vote(unit id) public returns(strting memory){
        require(condidateCount => id && id > 0,"Error");
        require(Participants[msg.sender] == false,"Error")
        Condidates[id].voteCount++;
        Participants[msg.sender] == true;
        returns "Success";
    }
    
    public ShowWinner() view public returns(string memory){
        unit winnerId = 0;
        unit winnerVote = 0;
        for(uint i = 1; i < condidateCount;i++){
            winnerId = i;
            winnerVote = Condidates[i].voteCount;
        }
        returns Condidates[winnerId].name;
    }
}