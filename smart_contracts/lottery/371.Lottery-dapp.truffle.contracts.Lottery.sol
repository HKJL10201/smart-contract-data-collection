// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract Lottery is VRFV2WrapperConsumerBase, ConfirmedOwner {

    struct RandomNumber {
        uint value;
        bool inProgress;
        bool alreadyUsed;
    }

    RandomNumber private randomNumber;

    address[] public participants;
    mapping(address => uint) public bets;
    address payable public lastWinner;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    event WinnerFound(address payable indexed winner);
    event NewBet(address indexed player, uint indexed value);

    constructor() 
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        // To block calling drawWinner function before requesting random number
        randomNumber.alreadyUsed = true;
    }

    function addBet() public payable {
        require(!randomNumber.inProgress, "Cannot join the lottery while chosing a winner");
        require(msg.value >= 1 gwei, "Minimum bet is 1 gwei");
        
        // A new player enters the game
        if (bets[msg.sender] == 0) {
            participants.push(msg.sender);
        } 

        bets[msg.sender] += msg.value;
        emit NewBet(msg.sender, msg.value);
    }

    function requestRandomNumber() public onlyOwner returns (uint requestId) {
        randomNumber.inProgress = true;
        return requestRandomness(callbackGasLimit, requestConfirmations, 1);
    }

    function fulfillRandomWords(uint, uint[] memory randomNumbers) internal override {
        randomNumber.value = randomNumbers[0] % address(this).balance;
        randomNumber.inProgress = false;
        randomNumber.alreadyUsed = false;
    }

    function drawWinner() public onlyOwner {
        require(!randomNumber.alreadyUsed, "Request new random number");
        require(!randomNumber.inProgress, "Wait for Chainlink VRF to fulfill randomness");

        uint currSum;
        uint index;

        // Choosing winner based on intervals
        // For example first participant wins when randomNumber is between [0, their bet value)
        while (index < participants.length && currSum <= randomNumber.value) {
            currSum += bets[participants[index++]];
        }

        address payable winner = payable(participants[--index]);
        winner.transfer(address(this).balance);
        emit WinnerFound(winner);

        lastWinner = winner;
        randomNumber.alreadyUsed = true;
        resetBetsData();
    }

    function resetBetsData() internal onlyOwner {
        for (uint i = 0; i < participants.length; i++) {
            delete bets[participants[i]];
        }
        participants = new address[](0);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    function getRandomNumber() public view onlyOwner returns (uint, bool, bool) {
        return (randomNumber.value, randomNumber.inProgress, randomNumber.alreadyUsed);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

}
