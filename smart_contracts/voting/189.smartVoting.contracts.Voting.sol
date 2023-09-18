pragma solidity ^0.5.9;

import './AccessControlled.sol';

contract Voting is AccessControlled {

struct Vote {
address receiver;
uint256 timestamp;
}

mapping(address => Vote) public votes;

// Define events we wish to emit
event AddVote(address indexed voter, address receiver, uint256 timestamp);
event RemoveVote(address voter);
event StartVoting(address startedBy);
event StopVoting(address stoppedBy);

constructor() AccessControlled(msg.sender, false) public {
// No action required here.
}

function startVoting() external onlyOwner returns(bool) {
require(!isVoting, "Voting is already OPEN.");
isVoting = true;
emit StartVoting(owner);
return true;
}

function stopVoting() external onlyOwner returns(bool) {
require(isVoting, "Voting is already CLOSED.");
isVoting = false;
emit StopVoting(owner);
return true;
}

function addVote(address receiver) external onlyOwner returns(bool) {
assert(receiver != address(0));
require(isVoting, "Voting is currently not open. Please try again later.");
require(votes[msg.sender].timestamp == 0, "This user has already voted!");

// Set values for the Vote struct
votes[msg.sender].receiver = receiver;
votes[msg.sender].timestamp = now;

emit AddVote(msg.sender, votes[msg.sender].receiver, votes[msg.sender].timestamp);
return true;
}

function removeVote() external onlyOwner returns(bool) {

require(isVoting, "Voting is currently not open. Please try again later.");
require(votes[msg.sender].timestamp != 0, "This user has NOT voted yet!");

delete votes[msg.sender];

emit RemoveVote(msg.sender);
return true;
}

function getVote(address voterAddress) external view returns(address candidateAddress) {
require(msg.sender == owner, "Only the contract owner can perform this operation");
return votes[voterAddress].receiver;
}
}
