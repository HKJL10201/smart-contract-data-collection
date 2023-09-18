// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery2 {
    address public immutable manager;
    address[] public persons;
    address public winner;
    uint256 public constant lotteryPrice = 5 gwei;

    constructor() {
        manager = msg.sender;
    }

    function takeLottery() public payable {
        require(msg.value == lotteryPrice, "the ticket price is 5 gwei");
        persons.push(payable(msg.sender));
    }

    function isParticipated(address _person) public view returns (bool) {
        for (uint i = 0; i < persons.length; i++) {
            if (persons[i] == _person) {
                return true;
            }
        }
        return false;
    }

    function totalPersons() public view returns (uint) {
        return persons.length;
    }

    receive() external payable {
        takeLottery();
    }

    fallback() external payable {
        takeLottery();
    }

    function generateRandom() internal view returns (uint256) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        persons.length
                    )
                )
            ) % persons.length;
    }

    function getPrizeBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function declearWinner() public payable {
        require(
            msg.sender == manager,
            "Only the manager can declear the winner"
        );
        require(persons.length >= 3, "Participants should be greater then 3");
        winner = persons[generateRandom()];
        payable(winner).transfer(getPrizeBalance());
        persons = new address payable[](0);
    }
}
