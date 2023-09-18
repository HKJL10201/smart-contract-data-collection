// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    
    address manager;

    address payable[] public players; 
    address payable public winner;

    constructor(){
    manager = msg.sender;
    }

    receive() external payable{ 
        require(msg.value==1 ether, "Please pay 1 ether only"); 
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint){ 
        require(manager==msg.sender, "You are not the manager");
        return address(this).balance;
    }

    function random() internal view returns(uint){ 
        return uint(keccak256(abi.encodePacked (block.difficulty, block.timestamp,players.length)));
    }

    function pickWinner() public {
        require(msg.sender==manager, "You are not the manager"); 
        require(players.length>=2, "Players are less than 2");

        uint r = random();
        uint index = r%players.length; //remainder <players.length
        winner = players[index];
        winner.transfer (getBalance());
        players = new address payable[](0);
    }

}