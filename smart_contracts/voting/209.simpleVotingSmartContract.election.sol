pragma solidity ^0.5.7;

contract Election {

    struct Candidate{
        string name;
        string symbol;
    }

    Candidate[] public candidatesToVote;

    mapping (address=>Candidate) public candidateToAddress;

    constructor () public {
        candidatesToVote.push(Candidate("Candidate 1","ZTP"));
        candidatesToVote.push(Candidate("Candidate 2","TIP"));
    }

    function voteCandidate(string memory _name,string  memory _symbol) public  {
        for(uint16 i=0; i<candidatesToVote.length;i++){
            if((keccak256(abi.encodePacked(candidatesToVote[i].symbol))== keccak256(abi.encodePacked(_symbol))) && (keccak256(abi.encodePacked(candidatesToVote[i].name))== keccak256(abi.encodePacked(_name)))){
                bytes memory tempEmptyStringTest = bytes(candidateToAddress[msg.sender].name); // Uses memory
                if (tempEmptyStringTest.length == 0) {
                    candidateToAddress[msg.sender] = Candidate(_name,_symbol);
                } 
            }
        }
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidatesToVote;
    }
    
}