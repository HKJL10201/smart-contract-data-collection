pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    //Remember send value to contract!
    function enter() public payable {
        //check caller whether has enough ether to play game
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        //pseudo random
        return uint(keccak256(block.difficulty, now, players));
    }

    //Only manager can call this function
    function pickWinner() public restricted{
        require(msg.sender == manager);
        uint index = random() % players.length;
        //send prize to winner
        players[index].transfer(this.balance);
        //return to  original state with initial size 0.
        players = new address[](0);
    }

    //repeat logic in function can use modifier
    modifier restricted() {
        //check the caller is manager
        require(msg.sender == manager);
        //other function's code are at here! (_;)
        _;
    }

    //get player list
    function getPlayers() public view returns (address[]) {
        return players;
    }

}
