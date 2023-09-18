pragma solidity ^0.4.22;

contract Voting {
    bytes32[] public canditateList;
    mapping (bytes32 => uint8) public votesReceived;
    constructor() public {
        canditateList = getBytes32ArrayForInput();
    }
    
    function validateCandidate(bytes32 candiateName) internal view returns(bool){
        for(uint8 i = 0;i<canditateList.length; i++){
            if(candiateName == canditateList[i])
                return true;
        }
        return false;
    }
    function vote(bytes32 candiateListName) public payable returns(bytes32){
        require(validateCandidate(candiateListName));
        votesReceived[candiateListName] +=1;
    }
    
    function totalVotesFor(bytes32 candiateName) public view returns(uint8){
        require(validateCandidate(candiateName));
        return votesReceived[candiateName];
    }
    
    function getBytes32ArrayForInput() pure public returns (bytes32[3] b32Arr) {
        b32Arr = [bytes32("Candidate"), bytes32("Alice"), bytes32("Cary")];
    }
}