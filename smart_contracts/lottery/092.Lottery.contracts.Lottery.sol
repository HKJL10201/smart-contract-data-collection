pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender; // same nice
    }
    
    function enter() public payable {
        require(msg.value >  .0000001 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players)); // sha3()
    }
    
    function pickWinner() public purple {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier purple() {
        require(msg.sender==manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}
