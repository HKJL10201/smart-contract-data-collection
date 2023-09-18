//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITicket {
    /**
     * @dev Do not forget to add the "initializer" custom modifer
     * @param _winnerPicker is a VRFConsumer contract address
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint64 _start,
        uint64 _end,
        uint128 _price,
        address _winnerPicker // vrf consumer
    ) external;

    function buyTicket() external payable;

    function buyTicketWithURI(string memory _tokenUri) external payable;

    function pickWinner() external;

    function pickSmallWinner(uint256 _randomness) external;

    function pickBigWinner(uint256 _randomness) external;

    function claimSurpriseReward() external;

    function claimBigReward() external;

    function started() external view returns (bool);

    function finished() external view returns (bool);
}
