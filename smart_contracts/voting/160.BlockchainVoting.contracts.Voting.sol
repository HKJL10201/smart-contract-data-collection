//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Voting contract which allows on-chain voting for blockchain users.
 *
 * Allows pausing of voting via pausable
 * Also allows contextual information via inheritance
 * Allows ownership through ownable
 */

contract Voting is Ownable, Pausable {
    /**
     * @dev added the arrays to hold the addresses of users who have
     * interacted with the functions.
     */
    address[] public registeredVoters;
    address[] public voteCasters;

    /**
     * @dev this variable holds the question that we are going to ask the blockchain.
     */
    string public question;

    /**
     * @dev a map that has a one to one realtionship between
     * addresses and voters.
     */
    mapping(address => Voter) voters;

    /**
     * @dev a enum that holds responses that the user can give.
     */
    enum Response {
        NO,
        YES
    }

    /**
     * @dev When a user casts a vote we want to emit that to the network
     */
    event Vote(address indexed _address, bool response);

    /**
     * @dev When a user connects to cast a vote we want to emit that to the blockchain
     */
    event Register(address indexed _address);

    /**
     * @dev Voter struct allows us to represent every voter and their information.
     */
    struct Voter {
        string name;
        Response response;
        bool castVote;
        bool init;
    }

    /**
     * @dev Initalises the code in the paused state, not ready for voting.
     */
    constructor(string memory _question) {
        // pause voting until ready
        _pause();

        // Set the question to be asked
        question = _question;
    }

    /**
     * @dev Modifier to make a function callable only when the user is not registered to vote.
     *
     * Requirements:
     *
     * - The user must be not already registered to vote
     */
    modifier NotRegisteredToVote() {
        require(
            voters[_msgSender()].init == false,
            "Voting: You are already registered to vote"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the user is registered to vote.
     *
     * Requirements:
     *
     * - The user must be already registered to vote
     */
    modifier registeredToVote() {
        require(
            voters[_msgSender()].init == true,
            "Voting: You are not registered to vote"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the user has cast their vote
     *
     * Requirements:
     *
     * - The user must have already voted.
     */
    modifier voteCast() {
        require(
            voters[_msgSender()].castVote == true,
            "Voting: You have not casted your vote."
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the user has not cast their vote
     *
     * Requirements:
     *
     * - The user must have not already voted.
     */
    modifier voteNotCast() {
        require(
            voters[_msgSender()].castVote == false,
            "Voting: You have casted your vote."
        );
        _;
    }

    /**
     * @dev function to start the voting session, only the owner can call this.
     */
    function startVote() external onlyOwner {
        _unpause();
    }

    /**
     * @dev function to end the voting session, only the owner can call this.
     */
    function endVote() external onlyOwner {
        _pause();
    }

    /**
     * @dev function to add a voter to the voting session, can be called by the user
     * (simimilar to an approve function before a tx occurs.)
     * @param _name The voters name.
     *
     * Emits a {Register} event.
     */
    function addVoter(string memory _name)
        external
        whenPaused
        NotRegisteredToVote
    {
        address newVoter = _msgSender();
        voters[newVoter] = Voter(_name, Response.NO, false, true);
        // Add a new voter to the list of registered voters
        registeredVoters.push(newVoter);

        emit Register(newVoter);
    }

    /**
     * @dev function to cast a vote on the session, user must be registered to
     * invoke this function.
     * @param _response The voters answer.
     *
     * Emits a {Vote} event.
     */
    function vote(bool _response)
        external
        whenNotPaused
        registeredToVote
        voteNotCast
    {
        address voterAddress = _msgSender();
        //Update struct values
        Voter storage voter = voters[voterAddress];
        voter.response = (_response == true ? Response.YES : Response.NO);
        voter.castVote = true;
        voteCasters.push(voterAddress);

        emit Vote(voterAddress, _response);
    }

    /**
     * @dev Get the votes that have been cast and return the yes alongside the no votes.
     */
    function getVotes() public view returns (uint256, uint256) {
        uint256 yesCount = 0;
        uint256 noCount = 0;
        for (uint256 i = 0; i < voteCasters.length; i++) {
            if (voters[voteCasters[i]].response == Response.YES) {
                yesCount++;
            } else {
                noCount++;
            }
        }
        return (noCount, yesCount);
    }

    /**
     * @dev Get all the registered voters and the voters who have casted the votes.
     */
    function getUsers()
        public
        view
        returns (address[] memory, address[] memory)
    {
        return (registeredVoters, voteCasters);
    }

    /**
     * @dev Reset the votes for the voting session.
     */
    function resetVotes() external whenPaused onlyOwner {
        // Run rhrough all of the people who casted votes
        for (uint256 i = 0; i < voteCasters.length; i++) {
            // Get the current address we want to reset
            address currentAddress = voteCasters[i];

            // Get the previous name of the user so we can reset it
            string memory currentVoterName = voters[currentAddress].name;

            voters[currentAddress] = Voter(
                currentVoterName,
                Response.NO,
                true,
                false
            );
        }
        // Delete all voters
        delete voteCasters;
    }

    /**
     * @dev create getter for registeredVoters (Referenced var)
     */
    function getRegisteredVoters() public view returns (address[] memory) {
        return registeredVoters;
    }

    /**
     * @dev create getter for voteCasters (Referenced var)
     */
    function getVotedUsers() public view returns (address[] memory) {
        return voteCasters;
    }
}
