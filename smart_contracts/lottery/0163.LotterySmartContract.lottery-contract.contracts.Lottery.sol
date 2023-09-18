pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    //constructor function
    function Lottery() public {
        manager = msg.sender;
    }
    
    //function to enter the lottery
    function enterLottery() public payable {
        
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        //pseudo random number generator
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function SelectWinner() public justForManagers{
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
        
    }
    
    modifier justForManagers() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns(address[]) {
        return players;
    }
}