pragma solidity ^0.4.9;

contract Voting {
    
    address[] private voterList;
    
    bytes32[] private candidateList;
    
    mapping(bytes32 => uint8) private votesReceived;
    
    function Voting(bytes32[] candidateNames) public {
        for(uint8 i=0; i<candidateNames.length; i++) {
            candidateList.push(candidateNames[i]);
            votesReceived[candidateNames[i]] = 0;
        }
    }
    
    function addCandidate(bytes32 candidate) public {
        candidateList.push(candidate);
        votesReceived[candidate] = 0;
    }
    
    function voteForCandidate(bytes32 candidate) public {
        require(validVoter(msg.sender) == false);
        require(validCandidate(candidate) == true);
        
        votesReceived[candidate] += 1;
        voterList.push(msg.sender);
    }
    
    function votesOfCandidate(bytes32 candidate) public constant returns (uint8) {
        require(validCandidate(candidate) == true);
        
        return votesReceived[candidate];
    }
    
    function validCandidate(bytes32 candidate) private constant returns (bool) {
        for(uint8 i=0; i<candidateList.length; i++)
            if(candidateList[i] == candidate)
                return true;
                
        return false;
    }
    
    function validVoter(address sender) private constant returns (bool) {
        for(uint8 i=0; i<voterList.length; i++)
            if(voterList[i] == sender)
                return true;
        
        return false;
    }
    
}
