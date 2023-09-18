// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Lottery{
    address public manager;
    address payable[] public players;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    function participate() public payable{
        // if any player sent 1 ether to the company, add it to offical players
        require(msg.value == 1 ether, "Please pay 1 ether only!!!");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        //only manager has access to this function!!!
        require(manager == msg.sender, "You're not the manager!!!");
        return address(this).balance;
    }

    function randomNumber() public view returns(uint) {
        uint timestamp = block.timestamp;
        bytes32 hash = keccak256(abi.encodePacked(timestamp));
        return uint(hash);
    }

    function whoIsWinner() public {
        require(manager == msg.sender, "You're not the manager!!!");
        require(players.length>=3, "Players are less than 3");

        uint rand = randomNumber();
        uint index = rand % players.length;
        winner=players[index];
        winner.transfer(getBalance());
        
        players = new address payable[](0);
    }
}
