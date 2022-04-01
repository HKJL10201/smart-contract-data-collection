// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9; // specifies the version of solidity that our code is written in

contract Lottery {
    address public manager;  // does not enforece security if we use public or private
    address payable[] public players; // dynamic array that can only hold addresses
    address public winner;
    // msg is a global object that is always available in any function that runs in our contract
    /*
        mgs.data - Data field from the call or transaction that invoked the current function
        msg.gas - Amount of gas the current function invocation has available
        msg.sender - Address of the account that started the current function invocation
        msg.value - Amount of ether (in wei) that was sent along with the function invocation
    */
    constructor() {
    manager = msg.sender;
    }

    // to enter the lottery ehter need to be sent
    function enter() public payable { // payable - function expects some ether
        require(msg.value > .01 ether); // used for validation, false - exits the function, true - continues to execute the function
        players.push(payable(msg.sender));
    }

    function random() private view returns (uint){ // returns random number - not realy that random
               return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
               // keccak256 - Global function,block - global variable (the difficulty to solve a current block), now - current time no need for importing
    }

    function pickWinner () public restricted { // restircted - first calls the modifier restricted()
        uint index = random() % players.length;
        players[index].transfer(address(this).balance); // transfer - used for sending money to se specific address from a contract, this.balance - this-is our contract
        winner = players[index];
        players = new address payable[](0); // empty out the list of players
    }

    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

    function getWinner() public view returns (address){
        return winner;
    }

    modifier restricted(){ // Used for reducing the amount of code, any repetetive code
        require(msg.sender == manager); // check if the caller of pickWinner is called by the manager (person who deployed the contract)
        _; // takes out all of the code from the function where we use it a places it here
    }
}