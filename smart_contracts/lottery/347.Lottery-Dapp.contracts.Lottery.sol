//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0<0.9.0;

contract Lottery{
    address payable[] public players;
    address manager;
    address payable public winner;

    constructor(){
        manager = msg.sender;
    }

    receive() external payable{
        require(msg.value==1 ether,"Please pay 1 ether only");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(manager==msg.sender,"You are not the manager");
        return address(this).balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    function pickWinner() public {
        require(msg.sender==manager,"You are not manager");
        require(players.length>=3,"Players are less");

        uint r = random();
        uint index = r%players.length;
        winner=players[index];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }

    function allPlayers() public view returns(address payable[] memory){
        return players;
    }
}

//0x01C72b9FeC767A566f49197d86e68Ccb27ceea22

//ganache 0x5e91B2496283541e4fFdFFa870164E4d46B8b576