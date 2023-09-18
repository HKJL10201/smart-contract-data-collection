pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        // msg object is available whenever a user calls a function in the contract
        // msg.data --> data of the sender that called the function
        // msg.gas--> amount of gas needed
        // msg.sender --> address of the function caller
        // msg.value --> amount of ether sent with function invocation
        manager = msg.sender;
    }

    function enter() public payable {
        // validation code
        // msg.value is in integer, wei
        // ether amount will automatically be converted to wei 
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    // to generate pseudo-random number
    // this is not the best way to generate random numbers, as the outcome is semi-predictable
    // we should use a better random number generator for real-life application, 
    // although this is still limited as smart contracts don't allow pure randomness
    
    // keccak256() is same as sha3()
    // block difficulty, current time, players' addresses --> sha3 --> hash -- (parsed) --> uint
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    // modulo operator ensures that the result is between
    // 0 and the number of players (exclusive)
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }

    // _ is replaced with the code of tbe function that is calling it
    // this means all the code before the _ runs before the code of the calling function
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;    
    }
}
