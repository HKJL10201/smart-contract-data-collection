// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "hardhat/console.sol";
contract Lottery {
    address[] public noOfParticipants;
    mapping(address => uint) public participants;
    mapping(address => bool) private isParticipants;
    address public admin;
    uint public randomWin;

    constructor() {
        admin = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == admin, "You are not an Owner");
        _;
    }
    modifier notOwner() {
        require(msg.sender != admin, "You are an Owner");
        _;
    }

    function length() public view returns (uint8) {
        return uint8(noOfParticipants.length);
    }

    function takePart() public payable notOwner {
        require(noOfParticipants.length<=10,"Max Number Reached");
        require(
            msg.value == 0.01 ether,
            "at least 0.01 ether needed to participate in the lottery"
        );
        if (isParticipants[msg.sender]) participants[msg.sender] += msg.value;
        else {
            isParticipants[msg.sender] = true;
            participants[msg.sender] = msg.value;
            noOfParticipants.push(msg.sender);
        }
    }

    function randomWinner() public OnlyOwner returns (uint256) {
        require(
            noOfParticipants.length >= 3,
            "Need More than 3 Participanst to start lottery"
        );
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    noOfParticipants.length
                )
            )
        );
        randomWin = num % noOfParticipants.length;
        console.log("random:",randomWin);
        return randomWin;
    }

    function winnerPay() public OnlyOwner {
        require(noOfParticipants.length >= 3, "Not enough Participants");
        address winner = noOfParticipants[randomWin];
        console.log(winner);
        (bool success, ) = winner.call{value: address(this).balance}(msg.data);
        require(success, "Failed Transaction");
        deleteData();
    }

    function deleteData() private {
        for (uint8 i = 0; i < noOfParticipants.length; i++) {
            delete participants[noOfParticipants[i]];
            delete isParticipants[noOfParticipants[i]];
        }
        noOfParticipants = new address[](0);
    }
}
