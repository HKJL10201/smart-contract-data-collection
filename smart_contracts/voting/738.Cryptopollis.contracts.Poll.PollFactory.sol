// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Import contracts
import "./Poll.sol";
import "./IPollFactory.sol";
import "../Utils/Context.sol";
import "../Utils/StateLimits.sol";
// Import Libraries

/**
 * @title PollFactory
 * @dev Basic functionality to create new polls and control read and write.
 */
contract PollFactory is IPollFactory, Context, Limits {
    // ++ States ++
    //address public owner;
    // Maps ID of the poll to PollBody structure (uint => PollBody)
    mapping(uint => Poll) private _polls;
    // Number of polls created
    uint totalPollsCounter;
    // uint qLimit, uint oLimit, uint oALimit
    constructor () {
        //owner = msg.sender;
        //questionLengthLimit = qLimit;
        //optionLengthLimit = oLimit;
        //optionArrayLengthLimit = oALimit;
        
        // Total max size => 1344 bytes (1.3125 KB)
        questionLengthLimit = 64;
        optionLengthLimit = 64;
        optionArrayLengthLimit = 20;
    }

    modifier pollExist(uint id) {
        require(address(_polls[id]) != address(0), "Poll does not exist");
        _;
    }

    function newPoll(string memory question, string[] memory options, uint openDate, uint liveDays, bool _private) external virtual override returns (bool) {
        Poll instancePoll = new Poll(msg.sender, _msgSender(), question, options, openDate, liveDays, _private);
        _polls[totalPollsCounter] = instancePoll;
        emit emitPoll(msg.sender, totalPollsCounter);
        totalPollsCounter += 1;
        return true;
    }
    // ++ Getter functions ++ 
    /**
     * @notice Returns the number of issued polls
     * @dev Returns pollsCounter state directly
     */
    function getTotalPollsCounter() public view virtual override returns (uint) {
        return totalPollsCounter;
    }
    /**
     * @notice Returns address of owner
     * @dev Address of whom deployed smart contract
     */
    function getPollOwner(uint id) public view virtual override pollExist(id) returns (address) {
        return _polls[id].getOwner();
    }
    /**
     * @notice Returns _question of poll
     * @dev 
     */
    function getQuestion(uint id) public view virtual override pollExist(id) returns (string memory) {
        return _polls[id].getQuestion();
    }
    /**
     * @notice Returns ALL string options from Poll
     * @dev 
     */
    function getOptions(uint id) public view virtual override pollExist(id) returns (string[] memory, uint[] memory) {
        return _polls[id].getOptions();
    }
    /**
     * @notice Returns total votes of Poll
     * @dev 
     */
    function getPollTotalVotes(uint id) public view virtual override pollExist(id) returns (uint) {
        return _polls[id].getTotalVotes();
    }
    /**
     * @notice Returns date on which Poll was created
     * @dev 
     */
    function getOpenDate(uint id) public view virtual override pollExist(id) returns (uint) {
        return _polls[id].getOpenDate();
    }
    /**
     * @notice Returns date on which Poll was closed
     * @dev 
     */
    function getCloseDate(uint id) public view virtual override pollExist(id) returns (uint) {
        return _polls[id].getCloseDate();
    }
    /**
     * @notice Returns number of live days
     * @dev 
     */
    function getLiveTime(uint id) public view virtual override pollExist(id) returns (uint) {
        return _polls[id].getLiveTime();
    }
    /**
     * @notice Returns if address has access to poll
     * @dev 
     */
    function getAccess(address from, uint id) public view virtual override pollExist(id) returns (bool) {
        return _polls[id].getAccess(from);
    }
    // ++ Checkers ++
    function isPrivate(uint id) public view virtual override pollExist(id) returns (bool) {
        return _polls[id].getIsPrivate();
    }
    function isLive(uint id) public view virtual override pollExist(id) returns (bool) {
        return _polls[id].getIsLive();
    }
    /**
     * @notice Returns whether voter already voted the poll
     * @dev 
    */
    function hasVoted(address _voter, uint id) public view virtual override pollExist(id) returns (bool) {
        return _polls[id].hasVoted(_voter);
    }
    // ++ Setter functions ++
    /**
     * @notice Vote poll
     * @dev 
    */
    function setVote(uint id, uint optionIndex) external virtual override pollExist(id) returns (bool) {
        _polls[id].setVote(msg.sender, optionIndex);
        return true;
    }
    /**
     * @notice Extend live of poll in days
     */
    function changeLive(uint id, uint timeDays, bool increase) external virtual override pollExist(id) {
        _polls[id].changeLive(timeDays, increase);
    }
    /**
     * @notice Add access to voter to private poll
     */
    function addAccess(address to, uint id) external pollExist(id) {
        _polls[id].addAccess(msg.sender, to);
    }
    /**
     * @notice Remove access from voter to private poll
     */
    function removeAccess(address to, uint id) external virtual override pollExist(id) {
       _polls[id].removeAccess(msg.sender, to);
    }
    /**
     * @notice Change private to public or viceversa
     */
    function togglePollPrivacy(uint id) external virtual override pollExist(id) {
       _polls[id].togglePrivacy(msg.sender);
    }
}
