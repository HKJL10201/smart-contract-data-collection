pragma solidity ^0.5.9;

contract AccessControlled {

    // Define state variables for the owner and the voting status flag
    address owner;
    bool public isVoting;

    constructor(address _owner, bool _isVoting) public {
        isVoting = _isVoting;
        owner = _owner;
    }

    // We define the modifiers used as part of our functions here.
    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can perform this operation");
        _;
    }

    modifier voteClosed {
        require(!isVoting, "Voting is currently open. Wait for it to be closed.");
        _;
    }

}
