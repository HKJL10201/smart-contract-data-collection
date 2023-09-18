// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Lottery{

    address payable[] public players;
    address manager;
    address payable public winner;

    constructor (){
        manager=msg.sender;
    }

    receive() external payable{
        require(msg.value == 1 ether,"Please pay 1 ether only");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint)
    {
        require(msg.sender ==manager,"You are not the manager");  // only manager can access
        return address(this).balance;
    }

    function random() internal view returns(uint)
    {
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

      function  pickWinner() public
    {
        require(msg.sender == manager,"You are not the manager");
        require(players.length>=3,"Players are less than 3");
        uint r=random();
        uint index = r % players.length;
        winner = players[index];
        winner.transfer(getBalance());
        players=new address payable[](0);

    }

    function allPlayers() public view returns(address payable[] memory){
        return players;
    }

}

// contract address:    0xCB2736d075e53d57218135fcde4ba0eeeD9F39B2

//contract  ganache address:    0x8F4934Dc339cF63C241E0fFeB4101867D036041F