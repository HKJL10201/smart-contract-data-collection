pragma solidity ^0.4.17;

contract Lottery{

    address public manager;
    address[] players;

    constructor(){
        manager = msg.sender;
    }

    function enter() public payable{
        require(msg.value > .01 ether);   // checking for mim transation value
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
         uint index = random() % players.length;
         players[index].transfer(this.balance);
         players = new address[](0); // dynamic array of lenght 0 , make empty the players array after winner selected.
    }

    // this is a modifier function to reduce the code redandancy/repetation.
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    // this will return list of players
    function getPlayers() public view returns (address[]){
        return players; 
    }
}
