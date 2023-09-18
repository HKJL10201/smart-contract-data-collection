pragma solidity >=0.8.0;
contract Voting{
    mapping(string => uint8) internal votesReceived;

    string[]  public candidateList;

    constructor(string[] memory candidateNames) public {
        candidateList = candidateNames;
    }

    function validCandidate(string memory candidate) view public returns(bool){
        bytes memory b1 = bytes(candidate);
        for(uint i=0;i<candidateList.length;i++)
        {
            bytes memory b2 = bytes(candidateList[i]);
            if(keccak256(b1) == keccak256(b2)){
                return true;
            }
        }
        return false;
    }

    function totalVotesFor(string memory candidate) view public returns(uint8){
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    function voteForCandidate(string memory candidate) public{
        require(validCandidate(candidate));
        votesReceived[candidate]++;
    }

}
