pragma solidity ^0.4.17;

contract Lottery {

    address public manager;

    address[] public players;         // Dynamic Arrays

    uint public winnerIndex;

    function Lottery() public {         //Constructor
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == manager);
        _;
    }

    function enterLottery() public payable {
        if(manager != msg.sender)       //Manager is not allowed to participate into lottery
        {
            if(players.length <5)       //Number of players = 4
            {
                require(msg.value == 0.5 ether);          //require 0.5 Ether some amount of Ether
                players.push(msg.sender);
            }
        }
    }

    function random() public view returns(uint) {
        return(uint(keccak256(block.difficulty, now, players)));      //Sha256 and keccak256 is same
    }

    function pickWinner() public onlyOwner {     //Only manager/owner can call the pickWinner
        winnerIndex = random() % players.length;
        players[winnerIndex].transfer(this.balance);
        //Reset all players once transferred ether to the winner
        players = new address[](0);         //Reinitialize Dynamic array with 0 count array to retart another round of Lottery
    }

    function getPlayers() public view returns(address[]) {
        return players;
    }

    function myArrayLength() public view returns(uint) {
        return players.length;
    }

    function printLastPlayer() public view returns(address) {
        uint a = players.length-1;
        return players[a];
    }
}
