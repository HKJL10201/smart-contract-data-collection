//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
//import "@openzeppelin/contracts";

contract Lottery is VRFConsumerBase {
        
    //each oracle job has a unique key hash that identifies which tasks it should perform
    bytes32 internal keyHash;
    //fee that will be paid to the chainlink node
    uint256 internal fee;
    //random number that is returned from the chainlink node
    uint256 public randomResult;

    address public manager;
    address [] public players;

    //VRF coordinator address: the address of the contract that verifies that the numbers returned by the oracle are actually random
    //LINK token contract: address of the link token
    //keyhash: specific to the oracle we're gonna use
    constructor() VRFConsumerBase(
                    0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
                    0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ) {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        manager = msg.sender;
    }

     //the seed will be used by the oracle to start with randomness
    //this emits a log to the chainlink oracle that we've specified
    //it looks for the request, generates the random number, and returns that in the callback
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    //fullfill randomness callback from the VRF Coordinator
    function fulfillRandomness(bytes32 /*requestId*/, uint256 randomness) internal override {
        randomResult = (randomness % players.length) + 1;

        uint winner = randomResult;
        payable(players[winner]).transfer(address(this).balance);
        players = new address[](0);
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    function pickWinner() public restricted {
        getRandomNumber(block.timestamp);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}