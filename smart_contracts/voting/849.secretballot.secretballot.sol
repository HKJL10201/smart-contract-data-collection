// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/// @title A contract for conducting polls with a secret ballot
/// @author nhrj36
/// @notice The owner can create ballots that users conduct a commit-reveal vote on.
contract SecretBallot is Ownable {
    // Type declarations
    struct Voter {
        bytes32 voteHash; // Hashed vote submitted by voter
        bool hasCommited; // Whether the voter has commited a vote
        bool hasRevealed; // Whether the voter has revealed their vote
    }

    struct BallotConfig {
        uint8 numOptions; // Number of options on ballot
        uint8 numWinners; // Number of ballot winners
        uint32 commitPhaseEndTime; // Unix timestamp for when the commit phase ends
        uint32 revealPhaseEndTime; // Unix timestamp for when the reveal phase ends
        uint8 percentReturn; // Percentage of vote commit cost returned upon reveal
        uint168 votePrice; // Cost of commiting a vote, in wei
        bytes32 ballotHash; // Unique identifier for the ballot, for event filtering
    }

    // Phase state machine pattern from https://docs.soliditylang.org/zh/latest/common-patterns.html
    enum Phases {
        NewlyDeployed,
        CommitPhase,
        RevealPhase,
        ViewResults
    }

    // State variables
    /// @notice Struct containing lengths of public mappings
    BallotConfig public ballotConfig;

    /// @notice List of ballot options
    mapping(uint => string) public options;

    /// @notice List of winning ballot option indices
    mapping(uint => uint) public winners;

    Phases phase = Phases.NewlyDeployed;

    mapping(address => Voter) addressToVoter; // Maps each address to a voter
    mapping(address => uint) pendingWithdrawals;
    mapping(uint => uint) voteCounts; // Vote counts for each ballot choice
    address[] addresses; // List of addresses that have voted
    uint numRevealedVotes; // Number of votes that have been revealed

    // Events
    event NewBallot(
        string title,
        bytes32 indexed ballotHash,
        string[] options
    );
    event VoteCommited(
        bytes32 indexed ballotHash,
        address indexed from,
        bytes32 voteHash
    );
    event VoteRevealed(
        bytes32 indexed ballotHash,
        address indexed from,
        uint vote
    );
    event BallotResultAvailable(
        bytes32 indexed ballotHash,
        string result
    );
    event PhaseRead(uint8 phase);
    event BallotCountRead(bytes32 indexed ballotHash, uint index, uint count);

    // Modifiers
    modifier onlyAtPhase(Phases _phase) {
        require(phase == _phase, "Cannot call this function during this phase");
        _;
    }

    /// Perform any timed phase transitions necessary before calling function
    modifier timedTransitions() {
        if (phase == Phases.CommitPhase && block.timestamp >= ballotConfig.commitPhaseEndTime) {
            nextPhase();
        }
        if (phase == Phases.RevealPhase && block.timestamp >= ballotConfig.revealPhaseEndTime) {
            string memory result = calcBallotWinner();
            emit BallotResultAvailable(
                ballotConfig.ballotHash,
                result
            );
            nextPhase();
        }
        _;
    }

    // External functions

    /// Get the current phase
    function getPhase() external timedTransitions {
        emit PhaseRead(uint8(phase));
    }

    /// Let an address withdraw their funds
    /// @notice The owner can only withdraw during the View Results phase
    function withdraw() timedTransitions external {
        require(
            phase == Phases.ViewResults || msg.sender != owner(),
            "Owner cannot withdraw funds during this phase"
        );
        uint amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds available to withdraw");
        delete pendingWithdrawals[msg.sender];
        msg.sender.transfer(amount);
    }

    /// Create a new ballot
    /// @param _title The ballot title
    /// @param _options List of ballot options
    /// @param _votePrice Amount in wei that it costs to commit a vote
    /// @param _percentReturn Percentage of vote price to return upon successful vote reveal
    /// @param _commitPhaseMinutes Duration of the commit phase in minutes
    /// @param _revealPhaseMinutes Duration of the reveal phase in minutes
    function createBallot(
        string calldata _title,
        string[] calldata _options,
        uint168 _votePrice,
        uint _percentReturn,
        uint _commitPhaseMinutes,
        uint _revealPhaseMinutes
    )
        external
        onlyOwner
        timedTransitions
    {
        require(
            phase == Phases.NewlyDeployed || phase == Phases.ViewResults,
            "Previous ballot still active"
        );
        require(_options.length <= 256, "Too many ballot options submitted");
        require(_options.length > 1, "Ballot requires at least two options to vote on");
        require(_percentReturn <= 100, "Percentage return > 100");
        require(_commitPhaseMinutes <= 20160, "Commit phase too long");
        require(_revealPhaseMinutes <= 20160, "Reveal phase too long");

        // Clear old ballot
        if (ballotConfig.numOptions > _options.length) {
            // Clear any options that won't be overwritten by the new ones
            for (uint i=_options.length; i<ballotConfig.numOptions; i++) {
                delete options[i];
            }
        }
        // Clear winners mapping
        for (uint i; i<ballotConfig.numWinners; i++) {
            delete winners[i];
        }
        // Clear voter mapping
        for (uint i; i<addresses.length; i++) {
            delete addressToVoter[addresses[i]];
        }
        delete addresses;
        delete numRevealedVotes;

        // Setup new ballot config
        ballotConfig.numOptions = uint8(_options.length);
        ballotConfig.numWinners = 0;
        ballotConfig.percentReturn = uint8(_percentReturn);
        ballotConfig.votePrice = uint168(_votePrice);
        ballotConfig.commitPhaseEndTime = uint32(
            block.timestamp + (_commitPhaseMinutes * 60)
        );
        ballotConfig.revealPhaseEndTime = uint32(
            ballotConfig.commitPhaseEndTime + (_revealPhaseMinutes * 60)
        );
        ballotConfig.ballotHash = keccak256(abi.encode(_title, block.timestamp));

        for (uint i=0; i<ballotConfig.numOptions; i++) {
            options[i] = _options[i]; // Overwrite old options
            delete voteCounts[i]; // Reset old vote counts
        }

        phase = Phases.CommitPhase;

        emit NewBallot(_title, ballotConfig.ballotHash, _options);
    }

    /// Commit a vote
    /// @param _voteHash Keccak256 hash of (vote + secret) where + is concatenation
    function commitVote(bytes32 _voteHash)
        external
        timedTransitions
        onlyAtPhase(Phases.CommitPhase)
        payable
    {
        require(
            msg.value == ballotConfig.votePrice,
            "The exact fee is required to be paid"
        );
        require(
            !addressToVoter[msg.sender].hasCommited,
            "Each address can only commit one vote"
        );

        addresses.push(msg.sender);
        addressToVoter[msg.sender] = Voter({
            voteHash: _voteHash,
            hasCommited: true,
            hasRevealed: false
        });

        // Mark vote fee available for contract owner
        pendingWithdrawals[owner()] += ballotConfig.votePrice;

        emit VoteCommited(ballotConfig.ballotHash, msg.sender, _voteHash);
    }

    /// Reveal a vote
    /// @param _voteChoice Plaintext ballot choice that was commited
    /// @param _voteSecret Plaintext secret that was commited
    function revealVote(
        uint _voteChoice,
        string calldata _voteSecret
    )
        external
        timedTransitions
        onlyAtPhase(Phases.RevealPhase)
    {
        require(
            keccak256(abi.encode(_voteChoice, _voteSecret)) == addressToVoter[msg.sender].voteHash,
            "The plaintext vote is required to hash to the submitted vote hash"
        );
        require(
            !addressToVoter[msg.sender].hasRevealed,
            "This address has already revealed a vote"
        );
        require(
            _voteChoice < ballotConfig.numOptions,
            "The vote choice is required to be in the range of the ballot options"
        );

        // Count the vote
        voteCounts[_voteChoice]++;
        addressToVoter[msg.sender].hasRevealed = true;
        numRevealedVotes++;

        // Mark fee return available for voter, and unavailable for owner
        uint feeReturn = (ballotConfig.votePrice * ballotConfig.percentReturn) / 100;
        pendingWithdrawals[msg.sender] += feeReturn;
        pendingWithdrawals[owner()] -= feeReturn;

        emit VoteRevealed(ballotConfig.ballotHash, msg.sender, _voteChoice);

        // If all votes have been revealed, reveal the result of the vote
        if (numRevealedVotes == addresses.length) {
            string memory result = calcBallotWinner();
            emit BallotResultAvailable(
                ballotConfig.ballotHash,
                result
            );
            nextPhase();
        }
    }

    /// Get the number of valid votes cast for a specific ballot option
    /// @param _index List index of ballot option (starting from 0)
    function getBallotCount(uint _index)
        external
        timedTransitions
        onlyAtPhase(Phases.ViewResults)
    {
        require(_index < ballotConfig.numOptions, "Ballot option index out of range");
        emit BallotCountRead(ballotConfig.ballotHash, _index, voteCounts[_index]);
    }

    /// Reveal the ballot winner if haven't already.
    /// @notice Advances phases if necessary
    function revealBallotWinner() external {
        require(phase != Phases.NewlyDeployed, "Newly deployed contract has no results");
        require(phase != Phases.ViewResults, "Results have already been revealed!");
        require(
            phase != Phases.CommitPhase || block.timestamp >= ballotConfig.commitPhaseEndTime,
            "Nothing to do: no phase transition"
        );
        require(
            phase != Phases.RevealPhase || block.timestamp >= ballotConfig.revealPhaseEndTime,
            "Nothing to do: no phase transition"
        );

        if (phase == Phases.CommitPhase && block.timestamp >= ballotConfig.commitPhaseEndTime) {
            nextPhase();
        }
        if (phase == Phases.RevealPhase && block.timestamp >= ballotConfig.revealPhaseEndTime) {
            string memory result = calcBallotWinner();
            emit BallotResultAvailable(
                ballotConfig.ballotHash,
                result
            );
            nextPhase();
        }
    }

    // Internal functions

    /// Transition to the next ballot phase
    function nextPhase() internal {
        phase = Phases(uint8(phase) + 1);
    }

    /// Calculate who the winner(s) is (are)
    function calcBallotWinner() internal returns (string memory) {
        if (addresses.length > 0) {
            // Find winning number of votes
            uint sumVotes;
            uint winningCount = voteCounts[0];
            for (uint i=1; i<ballotConfig.numOptions; i++) {
                sumVotes += voteCounts[i];
                if (voteCounts[i] > winningCount) {
                    winningCount = voteCounts[i];
                }
                if (sumVotes == numRevealedVotes) {
                    break;
                }
            }

            // Populate winners
            uint8 counter;
            for (uint i; i<ballotConfig.numOptions; i++) {
                if (voteCounts[i] == winningCount) {
                    winners[counter++] = i;
                }
            }

            ballotConfig.numWinners = counter;

            if (ballotConfig.numWinners == 1) {
                return options[winners[0]];
            }

            return "Tie";
        }
        return "None";
    }
}
