//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {
    address public owner;
    address payable[] public players;
    uint256 public lotteryId;
    address public winner;
    mapping(uint256 => address payable) public lotteryHistory;

    //chainlinkVRF variables
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 subscriptionId;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callBackGasLimit = 100000;
    uint16 numConfirmations = 3;
    uint32 numWords = 1;

    uint256 requestId;

    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        owner = msg.sender;
        lotteryId = 1;
        subscriptionId = _subscriptionId;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value >= 0.01 ether);
        //address of player entering the lottery
        players.push(payable(msg.sender));
    }

    function getRandomNumber() public onlyOwner {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            numConfirmations,
            callBackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        uint256 index = randomWords[0] % players.length;
        (bool success, ) = players[index].call{value: address(this).balance}(
            ""
        );
        require(success, "Transaction Failed!");
        lotteryHistory[lotteryId] = players[index];
        winner = players[index];
        lotteryId++;
        players = new address payable[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
