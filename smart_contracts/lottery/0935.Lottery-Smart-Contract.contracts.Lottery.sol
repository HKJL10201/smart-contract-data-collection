// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Lottery contract inherits from the VRFConsumerBase contract provided by the Chainlink library. 

contract Lottery is VRFConsumerBase {
    address payable public owner;
    uint256 public ticketPrice;
    uint256 public ticketCount;
    uint256 private randomResult;
    bytes32 private keyHash;
    uint256 private fee;

    mapping(address => bool) public participants;

    event LotteryResult(uint256 indexed randomNumber, address indexed winner);

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee, uint256 _ticketPrice) 
        VRFConsumerBase(_vrfCoordinator, _link) {
        owner = payable(msg.sender);
        keyHash = _keyHash;
        fee = _fee;
        ticketPrice = _ticketPrice;
    }

   //The enterLottery function allows users to enter the lottery by sending the specified ticketPrice amount of cryptocurrency to the contract address. 

    function enterLottery() public payable {
        require(msg.value == ticketPrice, "Invalid ticket price.");
        require(!participants[msg.sender], "Already participated in the lottery.");

        participants[msg.sender] = true;
        ticketCount++;
    }
    // The endLottery function triggers the random number generation by calling the requestRandomness function provided by the Chainlink library.
    function endLottery() public {
        require(msg.sender == owner, "Only owner can end the lottery.");
        require(ticketCount > 0, "No participants in the lottery.");

        bytes32 requestId = requestRandomness(keyHash, fee);
    }

    //// Once the random number is generated, the fulfillRandomness function is called, which selects the winner using the selectWinner function and transfers the prize amount to the winner's address.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        address winner = selectWinner();
        uint256 totalPrize = ticketPrice * ticketCount;
        payable(winner).transfer(totalPrize);
        emit LotteryResult(randomResult, winner);
        ticketCount = 0;
    }

    function selectWinner() private view returns (address) {
        uint256 index = randomResult % ticketCount;
        for (uint256 i = 0; i < ticketCount; i++) {
            if (participants[address(uint160(uint(keccak256(abi.encodePacked(i)))))] == true) {
                if (index == 0) {
                    return address(uint160(uint(keccak256(abi.encodePacked(i)))));
                }
                index--;
            }
        }
        revert("Could not select a winner.");
    }
}
