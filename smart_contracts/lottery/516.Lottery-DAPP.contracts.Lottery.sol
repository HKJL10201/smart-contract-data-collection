// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.14 <=0.9.0;

contract Lottery {
    address public manager;
    address payable public winner;
    address[] public allWinners;
    address payable[] public participants;

    constructor() {
        manager = msg.sender; //global variable
    }

    receive() external payable {}

    function transfer() external payable {
        require(msg.value == 2 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function totalParticipants() public view returns (uint256) {
        return participants.length;
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants.length
                    )
                )
            );
    }

    function selectWinner() public {
        require(msg.sender == manager);
        require(participants.length >= 3);
        uint256 rand = random();
        uint256 index = rand % participants.length;

        winner = participants[index];

        winner.transfer(getBalance());
        participants = new address payable[](0);
        allWinners.push(winner);
    }
}
