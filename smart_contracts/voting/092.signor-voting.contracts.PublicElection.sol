pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./Election.sol";

contract PublicElection is Election {


    constructor (uint _startTime, uint _endTime, address[] memory _initialVoters) Election(_startTime, _endTime) public {
        addVoters(_initialVoters);
    }

    function vote(bytes32 _candidate) public onlyVoter votingOpen {
        require(!voted[msg.sender], "already voted");
        require(isCandidate(_candidate), "not a valid candidate");
        voteCount[_candidate]++;
        voted[msg.sender] = true;
        votesReceived++;
    }

}