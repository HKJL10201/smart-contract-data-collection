pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;   //dyanmic array
    
    uint256 LotteryValue;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value > 0.01 ether);
        
        players.push(msg.sender);
        
        LotteryValue = LotteryValue + msg.value;
    }
    
    function random() private view returns (uint256) {
        return uint256(sha3(block.difficulty, now, players));
    }
    
    function pickWinner() public isManager {
        uint256 index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0); //reset address array "()"
    }
    
    modifier isManager() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}