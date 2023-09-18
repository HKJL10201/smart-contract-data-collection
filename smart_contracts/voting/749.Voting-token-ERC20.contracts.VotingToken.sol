//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VotingToken is ERC20 {
    //Using numbers as candidates for simplicity temporarily
    uint[5] candidates = [1, 2, 3, 4, 5];
    mapping(uint => uint) candidateVotes;

    //Custom set amount of time pre-defined for voting
    uint votingStartTime = 1664769600; // October 5 2022 4pm 1665000000000;
    uint public votingEndTime = 1664769600; // October 5 2022 5pm 1665003600000
    uint public timestamp = block.timestamp;

    bool isVotingOpen = false;

    address immutable i_owner;

    constructor(uint initialSupply) ERC20("VotingToken", "VTK") {
        _mint(msg.sender, initialSupply);
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == i_owner,
            "You are not the owner of the voting token contract"
        );
        _;
    }

    //To verify if the person voting has token balance to vote
    modifier isAllowedToCastVote(address _voter) {
        require(
            this.balanceOf(_voter) > 0,
            "Token balance insufficient to cast vote"
        );
        _;
    }

    // This function can be used only by the owner to open the voting whenever desired
    function openVoting() public onlyOwner {
        isVotingOpen = true;
    }

    // This function can be used only by the owner to close the voting whenever desired
    function closeVoting() public onlyOwner {
        isVotingOpen = false;
    }

    //To check if the voting system is open before casting a vote
    function checkIfVotingIsOpen() public view returns (bool) {
        //Returns true if the time is during the custom set amount of time pre-defined
        // OR
        //if the owner manually set the voting system open with openVoting() function
        if (
            (block.timestamp >= votingStartTime &&
                block.timestamp <= votingEndTime) || isVotingOpen
        ) return true;
        return false;
    }

    function castVote(uint _candidateNumber)
        public
        isAllowedToCastVote(msg.sender)
    {
        require(checkIfVotingIsOpen(), "Voting is not allowed at this moment!");
        require(
            _candidateNumber >= 1 && _candidateNumber <= 5,
            "Invalid Candidate number!"
        );
        uint _updatedCandidateVotes = candidateVotes[_candidateNumber] + 1;
        candidateVotes[_candidateNumber] = _updatedCandidateVotes;
        transfer(address(this), 1);
    }

    function winningCandidate() public view returns (uint) {
        require(
            block.timestamp > votingEndTime && !isVotingOpen,
            "Voting is not closed yet!"
        );
        uint winningCandidateNumber = 1;
        for (uint i = 2; i <= 5; i++) {
            if (candidateVotes[i] > winningCandidateNumber) {
                winningCandidateNumber = i;
            }
        }
        return winningCandidateNumber;
    }
}
