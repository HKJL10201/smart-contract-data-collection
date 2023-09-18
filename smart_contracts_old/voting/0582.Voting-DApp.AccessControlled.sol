    
pragma solidity ^0.5.9;

contract AccessControlled {

    bool public isVoting;

    constructor() public {
        isVoting = false;
    }

    // We define the modifiers used as part of our functions here.
    modifier isVotingOpen {
        require(isVoting == true, "Voting process is not open.");
        _;
    }
}