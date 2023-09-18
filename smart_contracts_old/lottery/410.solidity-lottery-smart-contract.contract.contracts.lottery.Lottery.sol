// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Lottery {
    address public organizerAddress;
    int32 public lotteryRoundNumber;

    struct Set {
        address[] currentParticipatorsAddresses;
        mapping(address => mapping(int32 => bool)) participated;
    }

    event NewParticipation(
        address indexed participantAddress,
        uint256 indexed participationValue
    );
    event WinnerPicked(address indexed winnerAddress);

    Set registry;

    constructor() {
        organizerAddress = msg.sender;
        lotteryRoundNumber = 1;
    }

    modifier restricted() {
        require(
            msg.sender == organizerAddress,
            "Only the organizer can pick a winner"
        );
        _;
    }

    // Private //

    function registerParticipator(address participatorAddress) private {
        registry.currentParticipatorsAddresses.push(participatorAddress);
        registry.participated[participatorAddress][lotteryRoundNumber] = true;
    }

    function isNotRegistered(address addressToValidates)
        private
        view
        returns (bool)
    {
        return !registry.participated[addressToValidates][lotteryRoundNumber];
    }

    function pseudoRandom() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / 1000) * 1000));
    }

    function startNewLotteryRound() private {
        registry.currentParticipatorsAddresses = new address[](0);
        lotteryRoundNumber++;
    }

    function getWinnerAddress() private returns (address) {
        address winnerAddress = registry.currentParticipatorsAddresses[
            pseudoRandom() % registry.currentParticipatorsAddresses.length
        ];

        emit WinnerPicked(winnerAddress);

        return winnerAddress;
    }

    function rewardWinner(address winnerAddress) private {
        uint256 rewardAmount = address(this).balance;

        payable(winnerAddress).transfer(rewardAmount);
    }

    // Public //

    function canParticipate() external view returns (bool) {
        return !registry.participated[msg.sender][lotteryRoundNumber];
    }

    function participateLottery() external payable {
        address newParticipatorAddress = msg.sender;
        uint256 transactionAmount = msg.value;

        require(isNotRegistered(newParticipatorAddress), "Already registered");
        require(
            transactionAmount >= 0.001 ether,
            "You should at least send 1 Ethers"
        );

        registerParticipator(newParticipatorAddress);

        emit NewParticipation(organizerAddress, transactionAmount);
    }

    function getParticipatorAddress(uint104 participatorNumber)
        external
        view
        returns (address)
    {
        return registry.currentParticipatorsAddresses[participatorNumber - 1];
    }

    function getNumberOfParticipators() external view returns (uint256) {
        return registry.currentParticipatorsAddresses.length;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pickWinner() external restricted returns (address) {
        address winnerAddress = getWinnerAddress();

        rewardWinner(winnerAddress);

        startNewLotteryRound();

        return winnerAddress;
    }

    function getAllParticipators() external view returns (address[] memory) {
        return registry.currentParticipatorsAddresses;
    }
}
