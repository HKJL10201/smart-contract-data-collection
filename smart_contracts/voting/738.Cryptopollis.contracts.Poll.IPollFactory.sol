// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title PollFactory
 * @dev Basic functionality to create new polls and control read and write.
 */
interface IPollFactory {
    // ++ Events ++
    event emitPoll(address indexed opener, uint indexed pollId);
    
    function newPoll(string memory question, string[] memory options, uint openDate, uint liveDays, bool _external) external returns (bool);
    // ++ Getter functions ++ 
    /**
     * @notice Returns the number of issued polls
     * @dev Returns pollsCounter state directly
     */
    function getTotalPollsCounter() external view returns (uint);
    /**
     * @notice Returns address of owner
     * @dev Address of whom deployed smart contract
     */
    function getPollOwner(uint id) external view returns (address);
    /**
     * @notice Returns _question of poll
     * @dev 
     */
    function getQuestion(uint id) external view returns (string memory);
    /**
     * @notice Returns ALL string options from Poll
     * @dev 
     */
    function getOptions(uint id) external view returns (string[] memory, uint[] memory);
    /**
     * @notice Returns total votes of Poll
     * @dev 
     */
    function getPollTotalVotes(uint id) external view returns (uint);
    /**
     * @notice Returns date on which Poll was created
     * @dev 
     */
    function getOpenDate(uint id) external view returns (uint);
    /**
     * @notice Returns date on which Poll was closed
     * @dev 
     */
    function getCloseDate(uint id) external view returns (uint);
    /**
     * @notice Returns number of live days
     * @dev 
     */
    function getLiveTime(uint id) external view returns (uint);
    /**
     * @notice Returns if address has access to poll
     * @dev 
     */
    function getAccess(address from, uint id) external view returns (bool);
    // ++ Checkers ++
    function isPrivate(uint id) external view returns (bool);
    function isLive(uint id) external view returns (bool);
    /**
     * @notice Returns whether voter already voted the poll
     * @dev 
    */
    function hasVoted(address _voter, uint id) external view returns (bool);
    /**
     * @notice Vote poll
     * @dev 
    */
    function setVote(uint id, uint optionIndex) external returns (bool);
    // ++ Setter functions ++
    /**
     * @notice Extend live of poll in days
     */
    function changeLive(uint id, uint timeDays, bool increase) external ;
    /**
     * @notice Add access to voter to external poll
     */
    function addAccess(address to, uint id) external ;
    /**
     * @notice Remove access from voter to external poll
     */
    function removeAccess(address to, uint id) external ;
    /**
     * @notice Change external to external or viceversa
     */
    function togglePollPrivacy(uint id) external ;
}
