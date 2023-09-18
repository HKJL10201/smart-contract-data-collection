// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IPoll {
    // ++ Getter functions ++ 
    /**
     * @notice Returns address of owner
     * @dev Address of whom deployed smart contract
     */
    function getOwner() external view returns (address);
    /**
     * @notice Returns _question of poll
     * @dev 
     */
    function getQuestion() external view returns (string memory);
    /**
     * @notice Returns total votes
     * @dev 
     */
    function getTotalVotes() external view returns (uint);
    /**
     * @notice Returns ALL options data
     * @dev 
     */
    function getOptions() external view returns (string[] memory, uint[] memory);
    function getIsPrivate() external view returns (bool);
    /**
     * @notice Returns creation date
     * @dev 
     */
    function getOpenDate() external view returns (uint);
    /**
     * @notice Returns close date
     * @dev 
     */
    function getCloseDate() external view returns (uint);
    /**
     * @notice is Poll still live?
     * @dev 
     */
    function getIsLive() external view returns (bool);
    /**
     * @notice Returns number of live days
     * @dev 
     */
    function getLiveTime() external view returns (uint);
    /**
     * @notice Returns whether voter already voted the poll
     * @dev 
     */
    function hasVoted(address voter) external view returns (bool);
    /**
     * @notice Returns if address has access to poll
     * @dev 
     */
    function getAccess(address from) external view returns (bool);
    // ++ Sett functions ++
    /**
     * @notice Add access to voter to private poll
     */
    function addAccess(address from, address to) external;
    /**
     * @notice Remove access from voter to private poll
     */
    function removeAccess(address from, address to) external;
    /**
     * @notice Change privacy
     */
    function togglePrivacy(address from) external;
    /**
     * @notice Vote option of poll
     */
    function setVote(address from, uint optionIndex) external returns (bool);
    /**
     * @notice Add or decreace poll live in days
     */
    function changeLive(uint timeDays, bool increase) external;
}
