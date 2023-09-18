// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase {

    address[] participant;
    address owner;
    address payable public winner;
    uint256 public startTime;
    uint256 public endTime;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 randomNumber;
    
    constructor() VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; 
        owner=msg.sender;
        startTime= block.timestamp;
        endTime= block.timestamp + 60 minutes;
    }
    
    function getRandomNumber() private returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
       randomNumber = (randomness % participant.length);
    }
 
    function participate() payable public{
        require(msg.sender!=owner,"owner can not participate");
        require(block.timestamp >= startTime," entering before start time");
        require(block.timestamp < endTime," entering after end time");
        require(msg.value>=100000000000000000,"0.1 ether is needed");
        participant.push(msg.sender);
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

    function decideWinner() public {
        require(winner==address(0)," winner is allready decided");
        require(block.timestamp > endTime," winner can not decide before end time");
        require(msg.sender==owner,"owner can run this");
        getRandomNumber();
        winner = payable(participant[randomNumber]);
    }

    function claimReward() payable public {
        require(block.timestamp > endTime," can not claim reward before end time");
        require(msg.sender==winner,"you are not winner");
        uint256 balance = payable(address(this)).balance;
        winner.transfer(balance/100);
        winner=payable(address(0));
    }


}