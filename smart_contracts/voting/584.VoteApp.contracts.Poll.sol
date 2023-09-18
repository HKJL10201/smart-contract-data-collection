//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Poll is Ownable {

    uint256 pollStartedTime;
    address public pollAddress;
    address winnerAddress;


    enum State {Created, Running, Ended} 
    State public state;

    struct voter {
        bool hasRightToVote;
        bool votedStatus;
        bool isVoter;
    }

    struct candidate {
        uint256 amountOfVotes;
        bool isCandidate;
    }

    mapping(address => candidate) candidates; // candidate's address => amount of gained votes
    mapping(address => voter) voters; // voter's address => status: voted or not
    address[] candidatesList;
    address[] votersList;

    modifier pollInState(State _state) {
        require(state == _state, "Disallowed operation in the current poll state!");
        _;
    }

    modifier isVoter(address _currentVoterAddress) {
        require(voters[_currentVoterAddress].isVoter, "User is not a voter of this poll!");
        _;
    }

    modifier isCandidate(address _selectedCandidateAddress) {
        require(candidates[_selectedCandidateAddress].isCandidate, "User is not a candidate of this poll!");
        _;
    }

    constructor() {
        state = State.Created;
        pollAddress = msg.sender;
    }
    

    function addNewCandidate(address _newCandidateAddress) public pollInState(State.Created) onlyOwner {
        candidates[_newCandidateAddress].amountOfVotes = 0; // Added candidate has 0 votes by default 
        candidates[_newCandidateAddress].isCandidate = true;  
        candidatesList.push(_newCandidateAddress);
    }

    function addNewVoter(address _newVoterAddress) public pollInState(State.Created) onlyOwner{
        voter memory newVoter; 
        newVoter.isVoter = true;
        voters[_newVoterAddress] = newVoter; // Added voter didn't vote by default
        votersList.push(_newVoterAddress);
        
    }

    function startVotingProcess() public pollInState(State.Created) onlyOwner {
        pollStartedTime = block.timestamp;
        state = State.Running;
    }

    receive() external payable {
        require(msg.value == 0.01 ether, "Sorry, only 0.01 ethers is acceptable as a fee!");
        voters[msg.sender].hasRightToVote = true;
    }

   function deliverVote(address _voterAddress, address _selectedCandidateAddress) public 
    pollInState(State.Running)  
    isVoter(_voterAddress) 
    isCandidate(_selectedCandidateAddress) 
    onlyOwner {
       require(voters[_voterAddress].hasRightToVote == true, "Voter has no right to vote. Voting process charges commision!");
       require(voters[_voterAddress].votedStatus == false, "Voter has already voted!");
       candidates[_selectedCandidateAddress].amountOfVotes += 1; // Incrementing amount of gained votes;
       voters[_voterAddress].votedStatus = true; // User has voted;

       if (winnerAddress == address(0) || candidates[_selectedCandidateAddress].amountOfVotes > candidates[winnerAddress].amountOfVotes) {
           winnerAddress = _selectedCandidateAddress;
       }
   }

    function endVotingProcess() public pollInState(State.Running) {
        require(block.timestamp - pollStartedTime > 3 days, "Voting process is running for about 3 days!");
        state = State.Ended;
    }

    function sendTheCommisionToTheWinner() public onlyOwner pollInState(State.Ended){
        Address.sendValue(payable(winnerAddress), pollAddress.balance * 9 / 10);
    }

    function sendTheCommisionToTheOwner(address _appOwnerAddress) public onlyOwner  pollInState(State.Ended){
        Address.sendValue(payable(_appOwnerAddress), pollAddress.balance / 10);
    }

    function getVoters() public view returns(address[] memory) {
        return votersList;
    }

    function getCandidates() public view returns(address[] memory) {
        return candidatesList;
    }


    

    
}