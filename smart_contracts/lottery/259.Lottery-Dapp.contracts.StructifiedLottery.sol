//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Lottery {
    address public manager;
    // address payable[] public players;

    struct PlayerStruct {
        address payable player;
    }

    PlayerStruct[] public players;

    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(PlayerStruct(payable(msg.sender)));
        // players.push(payable(msg.sender));
    }
    // function random() private view returns(uint) {
    //     return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    // }

    function getPlayers() public view returns (PlayerStruct[] memory){
        return players;
    }


    // function pickWinner() public restricted{
    //     uint index = random() % players.length;
    //     players[index].transfer(address(this).balance);
    //     players=new address payable [](0);
    // }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
}