// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.17;

contract Lottery {

    address manager;
    address[] players;

    function Lottery() public {
        manager = msg.sender;
    }

    function join() public payable {
        require(msg.value > 0.1 ether);
        players.push(msg.sender);
    }

    function random() private returns (uint) {
        // sha3 and now have been deprecated
        return uint(keccak256(block.difficulty, now, players));
        // convert hash to integer
        // players is an array of entrants
        
    }

    function pickWinnder() public onlyManager {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
    }

    modifier onlyManager() {
        require(msg.sender ==  manager);
        _;
    }

    function getPlayer() public view returns(address[]){
        return players;
    }

}

