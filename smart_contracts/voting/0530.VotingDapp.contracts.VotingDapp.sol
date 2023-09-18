pragma solidity ^0.4.24;


contract VotingDapp {
    //setup model for candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;
    //set a candidate
    //get a candidate notice in solidity mapping size is unknown, cant iterate either. 
    //mapping(uint => Candidate) public candidates;
    //set candidates count
    uint public candidateCount;
    uint public totalVotes;
    string private test;

    //constructor
    constructor (bytes32[] _cands) public 
    {
        uint candidateCounts = _cands.length;
        for (var i = 0; i < candidateCounts; i++) {
            test = bytes32ToStr(_cands[i]);
            candidateCount++ ;
            candidates.push(Candidate(candidateCount, test, 0));
        }
        // addCandidate("candidate_one");
        // addCandidate("candidate_two");
        // addCandidate("candidate_three");
    }

    function bytes32ToStr(bytes32 _bytes32) public constant returns (string) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }     
  
    function addCandidate(string _name) private {
        
        candidateCount++ ;
        candidates.push(Candidate(candidateCount, _name, 0));
        //candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function voteForCandidate(string _name) {

    }

    function vote(uint votes) returns(bool success) {
        // totalVotes += votes;
        // voterCount[msg.sender] += votes; // cumulative
        // return true;
    }
}