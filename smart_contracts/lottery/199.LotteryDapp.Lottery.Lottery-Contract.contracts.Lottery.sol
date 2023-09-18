// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public EntryFee;
    uint256 public OwnerCut;
    
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    constructor (uint256 _Entryfee, uint256 _OwnerCut) public {
        EntryFee = _Entryfee;
        OwnerCut = _OwnerCut;
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function getContractBalance() public view returns (uint256) { //view amount of ETH the contract contains
        return address(this).balance;
    }

    receive() external payable {
        Deposit();
    }
    function Deposit() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not OPEN yet");
        require(msg.value == EntryFee, "Please, pay the entry fee");
        players.push(payable(msg.sender));
    }    

    function SetOwnerCutInPercent(uint256 _newOwnerCut) public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Lottery is not closed");
        require(_newOwnerCut <= 10, "Cant take more than 10%");
        OwnerCut = _newOwnerCut;
    }

    function SetEntryFee(uint256 _newEntryfee) public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Lottery is not closed");
        require(_newEntryfee >= 1000000000000, "Lottery is not cheap");
        EntryFee = _newEntryfee;
    }    

    function StartLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function PickWinner() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery must be OPEN");
        require(players.length > 0, "At least 2 players have to play");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 indexOfWinner = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender, // msg.sender is predictable
                        block.difficulty, // can actually be manipulated by the miners!
                        block.timestamp // timestamp is predictable
                    )
                )
            ) % players.length;
        recentWinner = players[indexOfWinner];

        PayOwner();
        PayWinner(recentWinner);

        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function PayOwner() private {
        (bool sent, bytes memory data) = owner().call{value: uint(address(this).balance) *  OwnerCut / 100}("");
        require(sent, "Failed to send Ether");
    }

    function PayWinner(address payable winner) private {
        (bool sent, bytes memory data) = winner.call{value: uint(address(this).balance)}("");
        require(sent, "Failed to send Ether");
    }
}