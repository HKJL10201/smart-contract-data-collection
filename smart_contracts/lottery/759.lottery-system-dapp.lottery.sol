// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8;

contract Lottery {
    address public manager; // manager address
    address payable[] public participants; // participants have to transact

    constructor() {
        manager = msg.sender; // the deploy account's address
    }

    receive() external payable {
        require(msg.value == 0.002 ether, 'amount is not appropriate');
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == manager, 'balance can only accessed by manager' );
        return address(this).balance;
    }

    //to select winner participant randomly
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function selectWinner() public  {
        require(msg.sender == manager, 'manager access only');
        require(participants.length >= 3, 'less participants');
        uint r = random();
        address payable winner;
        uint index = r % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);
    }
}
