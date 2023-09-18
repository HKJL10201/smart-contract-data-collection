//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase{

    constructor()
    VRFConsumerBase(
                0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
                0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
            ) 
    {
        owner = msg.sender; //Setting the owner to the deployer of the contract
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // LINK token fee needed for random number 
    }

    //Lottery variables
    address public owner;
    mapping (uint=>address payable) public ticketId;
    uint public totalTickets;
    bool public lotteryisActive; 
    uint public startTime;
    uint public stopTime;

    event LotteryStarted(uint startTime, uint stopTime);
    event LotteryEnded(address winner, uint amount);

    // Variables for Random number from  oracle
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;

    // Network: Polygon mumbai
    // LINK Token	0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    // VRF Coordinator	0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
    // Key Hash	0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
    // Fee	0.0001 LINK

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function newLottery() public onlyOwner { // Owner creating a new instance of lottery
        require(lotteryisActive == false,"Lottery round is in progress");
        lotteryisActive = true;
        startTime = block.timestamp;
        stopTime = block.timestamp + 1 hours;
        emit LotteryStarted(startTime, stopTime);
    }


    function buyTicket() public payable { // Participate in lottery 
        require(block.timestamp<stopTime, "The time to buy tickets is over. Please wait for the next round of lottery");
        require(msg.value == 0.1 ether,"Please change the value to 0.1 ether");
        totalTickets++;
        ticketId[totalTickets] = payable(msg.sender);
    }

    function endLottery() public onlyOwner { // Owner ending an existing instance of lottery
        
        //Uncomment the below line for requirement of 1 hour duration 

        // require(block.timestamp>stopTime, "Please wait till stop time");

        //Uncomment below line after testing
        // getRandomNumber(); 
        lotteryisActive = false;
        startTime = stopTime = 0;
    }
    //NOTE: Call disburseAmountToWinner() function after a minute of calling endLottery()"function (To get the random value from the oracle)

    function disburseAmountToWinner() public onlyOwner{ // Owner disbursing the winning amount

        uint winner = 2; // Comment this line and uncomment next line for chainlink random number in oracle 
        // uint winner = randomResult;
        emit LotteryEnded(ticketId[winner], address(this).balance);
        ticketId[winner].transfer(address(this).balance);
        
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() private  returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = (randomness % totalTickets) +1;
    }

}


