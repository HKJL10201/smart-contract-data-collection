pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address public winner;
    address[] public players;
    
    function Lottery() public{
        manager = msg.sender;
    }
    
    function enter() public payable restricted{
        players.push(msg.sender);
    }

    modifier restricted {
        require(msg.value > .01 ether );
        _;
    }

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    function getAllPlayers() public view returns (address[]){
        return players;
    }

    function pickWinner() public {
        require(manager == msg.sender);
        uint index = random() % players.length;
        winner = players[index];
        winner.transfer(this.balance);
        players = new address[](0);
    }

    function getWinner() public view returns (address){
        return winner;
    }

    function getPoolBalance() public view returns (uint){
        return this.balance;
    }
}