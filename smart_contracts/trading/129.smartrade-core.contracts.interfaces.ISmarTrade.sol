// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

/**
 * @dev Required interface of an ISmarTrade compliant contract.
 */
interface ISmarTrade {
    /**
     * @dev Emitted when created a `poll`.
     */
    event PollCreated(address indexed poll);

    /**
     * @dev Emitted when went to new trade.
     */
    event NextTrade(address indexed trade);

    /**
     * @dev Returns the trade id.
     */
    function tradeId() external view returns (uint256);

    /**
     * @dev Returns the trade name.
     */
    function tradeName() external view returns (string memory);

    /**
     * @dev Returns the trade type.
     */
    function tradeType() external view returns (string memory);

    /**
     * @dev Returns all the participants.
     */
    function getParticipants() external view returns (address[] memory);

    /**
     * @dev Returns the poll.
     */
    function getPoll() external view returns (address);

    /**
     * @dev Returns IPFS hash.
     */
    function getIPFSHash() external view returns (string memory);

    /**
     * @dev Returns if can create next trade.
     */
    function canCreateNextTrade() external view returns (bool);

    /**
     * @dev Sets the child trade.
     *
     * Requirements:
     *
     * - `childTrade` cannot be the zero address.
     * - `childTrade` must be contract.
     * - `childTrade` can only been set once
     *
     * Emits a {NextTrade} event.
     */
    function setChildTrade(address childTrade) external;

    /**
     * @dev Creates a poll. It will use ERC1417 (Poll) to deploy new contract to
     *  gather data from participants for trade.
     *
     * Requirements:
     *
     * - `poll` cannot be the zero address
     * - `poll` need to conform to ERC1417
     * - can only create next-trade `poll` once.
     *
     * Emits a {PollCreated} event.
     */
    function createPoll(address poll, uint256 nextTradeProposal) external;
}
