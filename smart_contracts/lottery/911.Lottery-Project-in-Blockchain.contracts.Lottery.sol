// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <=0.9.0;

contract Lottery {
    address public Manager;
    address payable[] public Players;
    address payable public Winner;

    constructor() {
        Manager = msg.sender;
    }

    function CheckDup() private view returns (bool) {
        for (uint i = 0; i < Players.length; i++) {
            if (Players[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {
        require(msg.value >= 1 ether, "Only 1 Ether is Allowed");
        if (CheckDup() == false) {
            Players.push(payable(msg.sender));
        }
    }

    function GetBalance() public view returns (uint) {
        require(msg.sender == Manager, "Only Manager Can Check Balance");
        return address(this).balance;
    }

    function Random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        block.timestamp,
                        Players.length
                    )
                )
            );
    }

    function PickWinner() public {
        require(msg.sender == Manager, "Only Manager Can Pick Winner");
        require(Players.length >= 3, "Not Enough Players");
        uint R = Random();
        uint Index = R % Players.length;
        Winner = Players[Index];
        Winner.transfer(GetBalance());
        Players = new address payable[](0);
    }

    function GetPlayers() public view returns (address payable[] memory) {
        return Players;
    }
}
