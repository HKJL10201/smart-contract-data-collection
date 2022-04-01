// pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

contract Voting {

    string[] voterHash;
    string[] candidateHash;
    mapping (string => uint) candidateVoteCount;
    mapping (string => uint) voterVoteCount;

    function addVoter(string memory _voterHash) public returns (bool){
        voterHash.push(_voterHash);
        voterVoteCount[_voterHash] = 0;
        return true;
    }

    function addCandidate(string memory _candidateHash) public returns (bool) {
        candidateHash.push(_candidateHash);
        candidateVoteCount[_candidateHash] = 0;
        return true;
    }

    function getVoters() public view returns (string[] memory) {
        return voterHash;
    }

    function getCandidates() public view returns (string[] memory) {
        return candidateHash;
    }

    function vote(string memory _candidateHash, string memory _voterHash) public returns (bool) {

        if(voterVoteCount[_voterHash] != 0)
            return false;
        else{
            voterVoteCount[_voterHash]++;
            candidateVoteCount[_candidateHash]++;
            return true;
        }
    }

    function reset() public
    {
        for(uint i=0;i<voterHash.length; i++)
        {
            voterVoteCount[voterHash[i]] = 0;
        }

        for(uint i=0;i<candidateHash.length; i++)
        {
            candidateVoteCount[candidateHash[i]] = 0;
        }
    }

    function getVoteCount(string memory _candidateHash) public view returns (uint) {
        return candidateVoteCount[_candidateHash];
    }
}