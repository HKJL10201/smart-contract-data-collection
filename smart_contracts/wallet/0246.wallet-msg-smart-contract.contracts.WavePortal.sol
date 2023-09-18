// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// Uncomment this line to use console.log
import "hardhat/console.sol";
contract WavePortal {

    uint256 totalWaves;
    event NewWave(address indexed from, uint256 timestamp, string message);

     struct Wave {
        address waver; // The address of the user who waved.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
        uint256 amount;
    }

    Wave[] waves;

    
     //This is an address => uint mapping, associate an address with a number!
     // storing the address with the last time the user waved at us.
     mapping(address => uint256) public lastWavedAt;

    constructor() payable {
        console.log("-smart contract constructed-");
    }

    //Be able to receive crypto
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // function wave() public {
    //     totalWaves += 1;
    //     console.log("sender:%s wave 'in' ", msg.sender);

    // }
    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        //(bool sent, bytes memory data) = _to.call{value: msg.value}("");
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function wave(string memory _message) payable public {
        
        totalWaves += 1;
        console.log("%s made a donation message: %s", msg.sender, _message);
        console.log("%s transferred a value: %s", msg.sender, msg.value);


        waves.push(Wave(msg.sender, _message, block.timestamp, msg.value));

        //emit an event
        emit NewWave(msg.sender, block.timestamp, _message);

        // uint256 sendAmount = 0.000001 ether;

        // require(
        //     sendAmount <= address(msg.sender).balance,
        //     "Insufficient fund"
        // );

        // (bool success, ) = (msg.sender).call{value: sendAmount}("");
        // require(success, "Failed to withdraw money from contract.");    

    }

    //Send pure Wave message
    function wave1(string memory _message) payable public {
        
        //Prevent Spam
        require(
            lastWavedAt[msg.sender] + 30 seconds < block.timestamp,
            "Wait 30 secs"
        );

        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;
        console.log("%s sent a message %s", msg.sender, _message);

        waves.push(Wave(msg.sender, _message, block.timestamp, msg.value));

        //emit an event
        emit NewWave(msg.sender, block.timestamp, _message);

        uint256 prizeAmount = 0.000001 ether;
        require(
            prizeAmount <= address(this).balance,
            "Insufficient fund for the prize"
        );
        (bool success, ) = (msg.sender).call{value: prizeAmount}("");
        require(success, "Failed to withdraw money from contract.");    
        
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }
    
    function getTotalWaves() public view returns (uint256) {
        console.log("total waves: %d", totalWaves);
        return totalWaves;
    }
}
