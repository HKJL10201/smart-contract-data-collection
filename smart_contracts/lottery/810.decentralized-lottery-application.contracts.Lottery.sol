pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor(){
        manager = msg.sender;
    }
    
    function enterLottery() public payable isNotFree {
        players.push(msg.sender);
    }
    function pseodoRandom ()  private isPlayersNotEmpty returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, players, msg.sender))) % players.length;
    }
    function chooseRandomWinner() public isProtected returns(address) {
        address winnerAddr = players[pseodoRandom()];
        payable(winnerAddr).transfer(address(this).balance);
        return winnerAddr;
    }
    modifier isNotFree(){
        require(msg.value > 0.01 ether);
        _;
    }
    modifier isPlayersNotEmpty(){
        require(players.length >= 1);
        _;
    }
    modifier isProtected(){
        require(msg.sender == manager);
        _;
    }
}   