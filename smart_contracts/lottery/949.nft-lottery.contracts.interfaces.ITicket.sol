// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITicket {
    function purchaseStartBlock() external view returns (uint256);

    function purchaseEndBlock() external view returns (uint256);

    function ticketPrice() external view returns (uint256);

    function latestLotteryId() external view returns (uint256);

    function prizePool() external view returns (uint256);

    function surpriseWinnerId() external view returns (uint256);

    function lotteryWinnerId() external view returns (uint256);

    function lotteryHolders(uint256 lotteryId) external view returns (address);

    function initialize(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _ticketPrice,
        address _newOwner,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external;

    function setBaseURI(string memory _uri) external;

    function buyTicket() external payable;

    function declareSurpriseWinner() external;

    function declareLotteryWinner() external;

    function getSurpriseWinner() external view returns (address winner);

    function getLotteryWinner() external view returns (address winner);
}
