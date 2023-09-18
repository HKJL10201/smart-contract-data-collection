// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId = 7420;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public randomResult;

    address public owner;
    address payable [] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    
    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        owner = msg.sender; 
        lotteryId = 1;
    }

    function getWinnnerByLottery(uint lotteryId) public view returns (address payable) {
        return lotteryHistory[lotteryId];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enterLottery() public payable {
        require(msg.value >  .0001 ether);      
        players.push(payable(msg.sender));
    }
    
    function pickWinner() public onlyOwner {
        getRandomNumber();
    }

    function payWinner() public {
        uint index = randomResult % players.length;
        players[index].transfer(address(this).balance);
        lotteryHistory[lotteryId] = players[index];
        lotteryId++;       
        players = new address payable[](0);
    }

    function getRandomNumber() public returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        randomResult = randomWords[0];
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

}