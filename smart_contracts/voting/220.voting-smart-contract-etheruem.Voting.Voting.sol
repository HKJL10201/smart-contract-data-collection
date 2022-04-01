pragma solidity ^0.5.9;

contract Voting {
    bool public isVoting;

    struct Vote {
        address reciever;
        uint256 timestamp;
    }
    

    mapping(address => Vote) public votes;
    
    event AddVote(address indexed voter, address receiver, uint256 timestamp);
    event RemoveVote(address voter);
    event StartVoting(address startedBy);
    event StopVoting(address stoppedBy);
    
    constructor() public {
        isVoting = false;
    }
    
    function startVoting() external returns(bool) {
        isVoting = true;
        emit StartVoting(msg.sender);
        return true;
    }
    
    function stopVoting() external returns(bool) {
        isVoting = false;
        emit StopVoting(msg.sender);
        return true;
    }
    
    function addVote(address reciever) external returns(bool) {
        votes[msg.sender].reciever = reciever;
        votes[msg.sender].timestamp = now;
        emit AddVote(msg.sender, votes[msg.sender].reciever, votes[msg.sender].timestamp);
        return true;
    }
    
    function removeVote() external returns(bool) {
        delete votes[msg.sender];
        emit RemoveVote(msg.sender);
        return true;
    }
    
    function getVote(address voterAddress) external view returns(address candidateAddress) {
        return votes[voterAddress].reciever;
    }
}