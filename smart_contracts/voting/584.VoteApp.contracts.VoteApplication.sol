//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Poll.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteApplication is Ownable {

    address[] createdPolls; 
    address appOwnerAddress;

    constructor() {
        appOwnerAddress = msg.sender;
    }
    
    function createPoll() public onlyOwner{
        Poll newPoll = new Poll();
        createdPolls.push(address(newPoll));
    }


    // ... Voting process has created
    function addNewCandidateToThePoll(address _pollAddress, address _newCandidateAddress) public onlyOwner {
        Poll(payable(_pollAddress)).addNewCandidate(_newCandidateAddress);
    }

    function addNewVoterToThePoll(address _pollAddress, address _newVoterAddress) public onlyOwner {
        Poll(payable(_pollAddress)).addNewVoter(_newVoterAddress);
    }


    // ... Voting process has activated
    function startVotingProcess(address _pollAddress) public onlyOwner {
        Poll(payable(_pollAddress)).startVotingProcess();
    }

    function deliverVote(address _pollAddress, address _voterAddress, address _selectedCandidateAddress) public onlyOwner {
        Poll(payable(_pollAddress)).deliverVote(_voterAddress, _selectedCandidateAddress);
    }

    function endVotingProcess(address _pollAddress) public {
        Poll(payable(_pollAddress)).endVotingProcess();   
    }


        // ... Voting process has ended
    function rewardTheWinnerOf(address _pollAddress) public onlyOwner{
        Poll(payable(_pollAddress)).sendTheCommisionToTheWinner();
    }

    function rewardTheOwnerOf(address _pollAddress) public onlyOwner{
        Poll(payable(_pollAddress)).sendTheCommisionToTheOwner(appOwnerAddress);
    }


    // view functions 

    function getVotersOf(address _pollAddress) public view returns(address[] memory) {
        return Poll(payable(_pollAddress)).getVoters();
    }

    function getCandidatesOf(address _pollAddress) public view returns(address[] memory) {
        return Poll(payable(_pollAddress)).getCandidates();
    }

    function getCreatedPolls() public view returns(address[] memory) {
        return createdPolls;
    }
}
