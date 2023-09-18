// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingApp is Ownable {
    string public name = "Voting App";

    enum Stage {
        INITIAL,
        REGISTER,
        VOTING,
        END
    }

    string public title;
    string[] public choices;
    Stage public currentStage;

    mapping(address => bool) private isRegistered;
    mapping(address => bool) private hasVoted;
    uint256[] numberOfVotes;

    constructor(string memory _title, string[] memory _choices) {
        title = _title;
        choices = _choices;
        currentStage = Stage.INITIAL;
        populateNumberOfVotes();
    }

    modifier registeredMustEqual(bool mustBeRegistered) {
        require(isRegistered[msg.sender] == mustBeRegistered);
        _;
    }

    modifier votedMustEqual(bool mustHaveVoted) {
        require(hasVoted[msg.sender] == mustHaveVoted);
        _;
    }

    modifier onlyInStage(Stage stage) {
        require(currentStage == stage, "Invalid stage for requested operation");
        _;
    }

    /**
     * Set the current stage absolutely anywhere (only owner).
     * Meant for testing purposes only! Otherwise it's kinda sus
     * if the owner does this.
     * @param stage the number of the stage (1-4) to jump to.
     */
    function setStage(uint8 stage) external onlyOwner {
        // TODO how to ensure it's not used any other time?
        // Or how else to solve it? Using advance and resetToStage
        // for misc operations is ugly in testing. Or just get rid of those?
        require(
            stage >= uint8(Stage.INITIAL) && stage <= uint8(Stage.END),
            "stage out of range"
        );
        currentStage = Stage(stage);
    }

    /** Advance to next stage (only owner) */
    function advance() external onlyOwner {
        require(currentStage != Stage.END, "Already reached end stage");

        if (currentStage == Stage.INITIAL) {
            currentStage = Stage.REGISTER;
        } else if (currentStage == Stage.REGISTER) {
            currentStage = Stage.VOTING;
        } else {
            currentStage = Stage.END;
        }
    }

    /** Reset to any previous stage (only owner). */
    function resetToStage(uint8 stage) external onlyOwner {
        require(
            uint256(currentStage) > stage,
            "Resetting is only possible to an earlier stage"
        );
        currentStage = Stage(stage);
    }

    /** Register to vote. Will be rejected during non-register stage. */
    function register()
        external
        registeredMustEqual(false)
        onlyInStage(Stage.REGISTER)
    {
        isRegistered[msg.sender] = true;
    }

    /** Unregister from vote. Will be rejected during non-register stage. */
    function unregister()
        external
        registeredMustEqual(true)
        onlyInStage(Stage.REGISTER)
    {
        isRegistered[msg.sender] = false;
    }

    /**
     * Cast your vote. Will be rejected during non-voting stage.
     * @param choice the number of the choice you're voting for. Cannot be overwritten later.
     */
    function vote(uint256 choice)
        external
        registeredMustEqual(true)
        onlyInStage(Stage.VOTING)
        votedMustEqual(false)
    {
        hasVoted[msg.sender] = true;
        numberOfVotes[choice]++;
    }

    /**
     * Check whether or not you have voted already. Meant for edge cases just to be sure that
     * the vote actually went through.
     * @return true if the sender has voted, false otherwise
     */
    function haveIVoted()
        external
        view
        registeredMustEqual(true)
        returns (bool)
    {
        return hasVoted[msg.sender];
    }

    /**
     * Check whether or not you have registered. Meant for edge cases just to be sure that
     * the register went through.
     * @return true if the sender is registered, false otherwise
     */
    function amIRegistered() external view returns (bool) {
        return isRegistered[msg.sender];
    }

    /**
     * Get the results. I wanted this to return a JSON string but unfortunately there is no
     * quick way to do that.
     * @return array containing the number of votes for each option specified by the indexes
     */
    function getResults()
        external
        view
        onlyInStage(Stage.END)
        returns (uint256[] memory)
    {
        return numberOfVotes;
    }

    function populateNumberOfVotes()
        private
        onlyOwner
        onlyInStage(Stage.INITIAL)
    {
        numberOfVotes = new uint256[](choices.length);
        for (uint256 i = 0; i < choices.length; i++) {
            numberOfVotes[i] = 0;
        }
    }
}
