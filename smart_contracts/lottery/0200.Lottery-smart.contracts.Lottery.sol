// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager= msg.sender;
        players.push(payable(msg.sender));
    }
    receive() external payable {
        require (msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }
    fallback() external payable {

    }
    function getBalance() public view returns(uint) {
        require(msg.sender ==  manager, "only manager can see this");
        return address(this).balance;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public{
        require(msg.sender == manager && players.length >=3);

        uint r = random();
        address payable winner;
        
        uint index= r % players.length;
        winner =  players[index];
        uint bal = (getBalance() * 10)/100;
        payable(manager).transfer(bal);
        winner.transfer(getBalance() - bal);
        players = new address payable[](0);
    }
}   