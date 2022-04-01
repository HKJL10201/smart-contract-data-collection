pragma solidity ^0.4.2;

contract Election{
    string public candidateName;

    function Election_1() public {
        candidateName = "Candidate 1";
    }

    function setCandidate (string memory _name) public {
        candidateName = _name;
    }
}
