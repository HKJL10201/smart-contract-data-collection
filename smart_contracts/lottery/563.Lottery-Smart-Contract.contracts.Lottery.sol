pragma solidity ^0.4.17;

contract Lottery{
    address manager;
    address[] players;

    function Lottery() public{
        manager = msg.sender;
    }

    function entry() public payable{
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint){
        return uint(keccak256(block.difficulty, now, players));
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    function pickWinner() public restricted{    
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }

    function etherPool() public view returns(uint){
        return this.balance;
    }

    function getPlayers() public view returns(address[]){
        return players;
    }
}