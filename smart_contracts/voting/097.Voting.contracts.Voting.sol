//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable{
    uint256 voteCount;

    mapping (uint256 => Vote) votes;

    struct Vote {
        mapping (address => bool) voterHasVoted;
        mapping (address => uint256) nomineeToVoteCount;
        address[] participants;
        uint256 balance;
        uint256 nomineeCount;
        uint256 maxVotes;
        uint256 startTimeStamp;
        bool isActive;
        address currentLeader;
        address winner;
    }

    event VoteIsCreated(uint256 voteId);

    event VoterHasVoted(uint256 voteId, address voter, address nominee);

    event VoteHasEnded(uint256 voteId, address winer, uint256 prize);

    event Withdrawal(uint256 voteId, address owner, uint256 comission);

    function addVoting() external onlyOwner {
        uint256 voteId = voteCount++;
        uint _startTimeStamp = block.timestamp;
        Vote storage _vote = votes[voteId];
        _vote.startTimeStamp = _startTimeStamp;
        _vote.isActive = true;

        emit VoteIsCreated(voteId);
    }

    function vote(uint256 voteId, address nominee) external payable{
        Vote storage _vote = votes[voteId];
        
        require(block.timestamp <= _vote.startTimeStamp + 3 days, "That vote no longer accepts new votes!");
        require(!_vote.voterHasVoted[msg.sender], "You can only vote once !");
        require(msg.value == 0.01 ether, "The voting fee is 0.01 ETH.");

        _vote.balance += 10000000000000000;
        _vote.participants.push(msg.sender);
        _vote.nomineeToVoteCount[nominee]++;
        _vote.voterHasVoted[msg.sender] = true;

        if(_vote.nomineeToVoteCount[nominee] > _vote.maxVotes){
            _vote.maxVotes = _vote.nomineeToVoteCount[nominee];
            _vote.currentLeader = nominee;
        }

        emit VoterHasVoted(voteId, msg.sender, nominee);
    } 

    function finish(uint256 voteId) external{
        Vote storage _vote = votes[voteId];

        require(block.timestamp <= _vote.startTimeStamp + 3 days, "The vote cannot be ended prematurely! ");

        _vote.isActive = false;
        _vote.winner = _vote.currentLeader;
        uint256 prize = (_vote.balance * 90) / 100;
        _vote.balance -= prize;
        address payable winner = payable(_vote.winner);
        winner.transfer(prize);

        emit VoteHasEnded(voteId, winner, prize);
    }

    function withdraw(uint256 voteId) external onlyOwner{
         Vote storage _vote = votes[voteId];

        require(!_vote.isActive, "This vote is not over yet !");

        address payable _owner = payable(owner());
        uint comission = _vote.balance;
        _owner.transfer(comission);

        emit Withdrawal(voteId, msg.sender, comission);
    }

    function getParticipants(uint256 voteId) external view returns(address[] memory) {
        return votes[voteId].participants;
    } 

    function getWinner(uint256 voteId) external view returns(address){
        return votes[voteId].winner;
    }

    function getIsActive(uint256 voteId) external view returns(bool){
        return votes[voteId].isActive;
    }

    function getTimeRemaining(uint256 voteId) external view returns(uint256){
        if(votes[voteId].isActive == false) {
            return 0;
        } else if (votes[voteId].startTimeStamp + 3 days >= block.timestamp){
            return votes[voteId].startTimeStamp + 3 days - block.timestamp;
        } else {
            return 0;
        }
    }
}