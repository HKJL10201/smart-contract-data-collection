pragma solidity  ^0.6.1;

contract voting{
    address public manager;
    uint public CandidateCount;
    mapping(address=>bool) participants;
    struct Candidate{
        address candidateAddress;
        string name;
        string party;
        string description;
        uint votes;
        uint id;
    }
    constructor() public{
        manager=msg.sender;
        CandidateCount=0;
    }
    Candidate[] public candidates;
    mapping(address=>bool) public voters;
    address[] names;
    function createCandidate(string memory name,address candidateAddress,string memory party,string memory description) public{
        require(!participants[candidateAddress]);
        uint id=candidates.length;
        Candidate memory candidate=Candidate({
          candidateAddress:candidateAddress,
          name:name,
          party:party,
          description:description,
          votes:0,
          id:id
        });
        participants[candidateAddress]=true;
        names.push(candidateAddress);
        candidates.push(candidate);
        CandidateCount++;
    }
    function vote(uint id) public{
        require(!voters[msg.sender]);
        voters[msg.sender]=true;
        candidates[id].votes++;
    }
    function pickWinner() public view returns(uint){
        require(msg.sender==manager);
        uint winnerid;
        uint max=0;
        for(uint i=0;i<candidates.length;i++){
            if (candidates[i].votes>max){
                max=candidates[i].votes;
                winnerid=candidates[i].id;
            }
        }
        return winnerid;
    }
    function returnNames() public view returns(address[] memory){
        return names;
    }
    
}