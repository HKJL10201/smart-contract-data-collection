//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
// linter warnings (red underline) about pragma version can igonored!

// contract code will go here
contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    //This function will allow users to enter the lottery.
    //Each address will be stored into the players address array
    function enter() public payable {
        require(msg.value > 0.01 ether, "the amount of ether should be at least 0.01");
        players.push(payable(msg.sender));
    }

    //This function will generate a random uint number using keccak256 algorithm
    function random() private view returns(uint) {
        //keccak256 returns a hash, so it is needed to convert the value in uint(256)
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    //This function will pick a winner from the players array.
    //It picks a single random index which identifies the winner and this last will receive the ethers
    function pickWinner() external restricted {
        //generating a uint number using the random function modulo array size
        uint index = random() % players.length;
        //send ethers to the winner at the position = index
        payable(players[index]).transfer(address(this).balance);
        //clean up the players' array initializing it again
        players = new address payable[](0);
    }

    //this modifier is useful to avoid writing recurring statements 
    //if used in a function definition, in this case, the function will be callable by the owner only.
    modifier restricted() {
        require(msg.sender == manager, "the function can be called by the owner only");
        _;
    }

    //This function allows the caller to view the addresses that entered the lottery
    function getPlayers() public view  returns(address payable[] memory) {
        return players;
    }
}