// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/// @author Jeff Soriano
/// @title A voting contract that allows voters to choose between two options
contract Voting {
    struct Option {
        string description;
        uint256 count;
    }

    enum VotingPhase {Registration, Voting, Closed}

    Option public optionA;
    Option public optionB;
    VotingPhase public votingPhase;

    address public manager;
    mapping(address => bool) public registeredVoters;
    mapping(address => bool) public voters;
    string public description;
    uint256 public intendedVotingDate;
    uint256 public intendedClosingDate;
    uint256 public actualVotingDate;
    uint256 public actualClosingDate;

    /// Constructor
    /// @param _manager the address that will be managing this contract
    /// @param _description the description of the Voting contract that tells the voters what they're voting for
    /// @param optionADescription the description of optionA
    /// @param optionBDescription the description of optionB
    /// @param _intendedVotingDate the intended date that the manager will move the contract to the Voting phase, in Unix time
    /// @param _intendedClosingDate the intended date that the manager will move the contract to the Closed phase, in Unix time
    /// @dev sets values of all state variables except 'registeredVoters' and 'voters'
    constructor(
        address _manager,
        string memory _description,
        string memory optionADescription,
        string memory optionBDescription,
        uint256 _intendedVotingDate,
        uint256 _intendedClosingDate
    ) {
        manager = _manager;

        description = _description;

        optionA.description = optionADescription;
        optionA.count = 0;
        optionB.description = optionBDescription;
        optionB.count = 0;

        intendedVotingDate = _intendedVotingDate;
        intendedClosingDate = _intendedClosingDate;
        actualVotingDate = 0;
        actualClosingDate = 0;

        votingPhase = VotingPhase.Registration;
    }

    /// Modifier that restricts certain functions for the manager only
    modifier restrictedToManager() {
        require(
            msg.sender == manager,
            "This function is restricted to the manager"
        );
        _;
    }

    /// Get the string value of the voting phase
    /// @dev returns the string value of the state variable 'votingPhase'
    function getVotingPhase() public view returns (string memory) {
        string memory _votingPhase;

        if (votingPhase == VotingPhase.Registration) {
            _votingPhase = "Registration";
        } else if (votingPhase == VotingPhase.Voting) {
            _votingPhase = "Voting";
        } else if (votingPhase == VotingPhase.Closed) {
            _votingPhase = "Closed";
        }

        return _votingPhase;
    }

    /// Moves to the next phase of voting
    /// @dev sets the state variable 'votingPhase' to the next part
    function moveToNextPhase() public restrictedToManager {
        require(
            votingPhase != VotingPhase.Closed,
            "Voting phase is set to Closed. Cannot move to next phase."
        );

        if (votingPhase == VotingPhase.Registration) {
            votingPhase = VotingPhase.Voting;
            actualVotingDate = block.timestamp;
        } else if (votingPhase == VotingPhase.Voting) {
            votingPhase = VotingPhase.Closed;
            actualClosingDate = block.timestamp;
        }
    }

    /// Register to vote
    /// @dev sets the state variable mapping of 'registeredVoters[msg.sender]' to true
    function registerToVote() public {
        require(
            registeredVoters[msg.sender] == false,
            "Address is already a registered voter."
        );
        require(
            votingPhase == VotingPhase.Registration,
            "Voting phase is not set to registration. Cannot register to vote."
        );

        registeredVoters[msg.sender] = true;
    }

    /// Vote
    /// @param isOptionA boolean that determines whether or not to vote for optionA
    /// @dev increments the 'count' variable of either optionA or optionB, then sets 'voters[msg.sender]' to true
    function vote(bool isOptionA) public {
        require(
            registeredVoters[msg.sender] == true,
            "Address is not registered to vote"
        );
        require(voters[msg.sender] == false, "Address has already voted");
        require(
            votingPhase == VotingPhase.Voting,
            "Voting phase is not set to voting. Cannot vote at this time"
        );

        if (isOptionA) {
            optionA.count++;
        } else {
            optionB.count++;
        }

        voters[msg.sender] = true;
    }
}
