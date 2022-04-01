// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract ReturnToMonke {

  constructor() payable {
    console.log("We have been constructed!");
  }
    uint256 totalBananasEaten;
    uint256 totalMonkes;

    uint256 private seed;

    enum MonkeLevel{HUMAN, CHIMP, ORANGUTAN, GORILLA, KINGKONG, GIGAKONG}

    event NewWoop(address indexed from, uint256 timestamp, string message);

    struct Woop {
        address wooper; // The address of the user who waved.
        string woop; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
    }

    // Store woops sent
    Woop[] woops;

    mapping(address => uint256) public lastBananaEaten;

    struct MonkeStruct {
      address monke;
      uint bananasEaten;
      MonkeLevel lvl;
      bool isMonke;
    }

    mapping (address => MonkeStruct) public Monkes;

    function isMonke(address monkeAddress) public view returns(bool isIndeed) {
        return Monkes[monkeAddress].isMonke;
    }


    function eatBanana(string memory _message) public {
        require(
          lastBananaEaten[msg.sender] + 2.5 minutes < block.timestamp,
          "Wait 15m"
        );

        lastBananaEaten[msg.sender] = block.timestamp;
        
        Monkes[msg.sender].bananasEaten += 1;
        totalBananasEaten += 1;
        console.log("%s has eatten %d bananas!", msg.sender, Monkes[msg.sender].bananasEaten);

        woops.push(Woop(msg.sender, _message, block.timestamp));

        uint256 randomNumber = (block.difficulty + block.timestamp + seed) % 100;
        
        console.log("Random # generated: %s", randomNumber);

        seed = randomNumber;

        if (randomNumber < 50) {
          uint256 prizeAmount = 0.0001 ether;
          require(
            prizeAmount <= address(this).balance,
            "Trying to withdraw more money than the contract has."
          );
          (bool success, ) = (msg.sender).call{
            value: prizeAmount}("");
          require(success, "Failed to withdraw money from contract");
        }

        emit NewWoop(msg.sender, block.timestamp, _message);

        if (Monkes[msg.sender].bananasEaten == 10) {
          console.log("%s has become the GIGA KONG!", msg.sender);
          Monkes[msg.sender].lvl = MonkeLevel.GIGAKONG;
        } else if (Monkes[msg.sender].bananasEaten == 8) {
          console.log("%s has become the KING KONG!", msg.sender);
          Monkes[msg.sender].lvl = MonkeLevel.KINGKONG;
        } else if (Monkes[msg.sender].bananasEaten == 6) {
          console.log("%s evolved into a Gorilla!", msg.sender);
          Monkes[msg.sender].lvl = MonkeLevel.GORILLA;
        } else if (Monkes[msg.sender].bananasEaten == 4) {
          console.log("%s evolved into an Orangutan!", msg.sender);
          Monkes[msg.sender].lvl = MonkeLevel.ORANGUTAN;
        } else if (Monkes[msg.sender].bananasEaten == 1) {
          console.log("%s has rejected humanity and become a chimp! The monke army grows stronger!", msg.sender);
          Monkes[msg.sender].lvl = MonkeLevel.CHIMP;
          totalMonkes += 1;
        }

        
    }

    function getTotalMonkes() public view returns (uint256) {
        console.log("The monke army is %d monkes strong!!", totalMonkes);
        return totalMonkes;
    }

    function getTotalBananasEaten() public view returns (uint256) {
        console.log("Monkes have consumed %d bananas!!", totalBananasEaten);
        return totalMonkes;
    }

    function getAllWoops() public view returns (Woop[] memory) {
        return woops;
    }
}