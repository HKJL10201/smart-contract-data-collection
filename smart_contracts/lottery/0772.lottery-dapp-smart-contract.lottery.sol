//SPDX-License-Identifier: GPL-3.0
//@denizumutdereli
//A Simple lottery dapp + smart contract
pragma solidity >= 0.5.0 <0.9.0;

contract Lottery{
    address payable[] public players;
    address public manager;

    constructor(){
        manager = msg.sender;
    }

    receive() external payable{
        require(players.length<=3); //max users
        require(msg.value == 0.001 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }


    //normaly should be on vrf.
    function random() public view returns(uint){
       return uint( keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function getWinner() public{
        require(msg.sender == manager);
        require(players.length == 3);//loop after every 3 users.

        uint r = random();

        address payable winner;

        uint index = r % players.length;

        winner = players[index];
    
        winner.transfer(getBalance());
        players = new address payable[](0);//reset
    }

    function numberOfUsers() public view returns(uint){
        return players.length;
    }

}