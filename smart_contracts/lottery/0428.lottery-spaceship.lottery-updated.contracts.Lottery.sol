// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address payable[] public players;
    uint[] public choices;
    address payable[] public winner;
    uint current = 10;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter(uint choice) public payable {
        require(msg.value > .01 ether);
        players.push(payable(msg.sender));
        choices.push(choice);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted {
        uint next = random();
        if (next > current) {
            for(uint i=0;i<players.length;i++) {
                if(choices[i] == 1) {
                    winner.push(players[i]);
                }
            }
        } else {
             for(uint i=0;i<players.length;i++) {
                if(choices[i] == 0) {
                    winner.push(players[i]);
                }
            }
        }
        current = next;
        uint index = random() % winner.length;
        winner[index].transfer(address(this).balance);
        winner = new address payable[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getNumber() public view returns (uint) {
        return current;
    }
}   