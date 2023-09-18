pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address [] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint randIndex = random() % players.length;
        address winner = players[randIndex];
        players = new address[](0); // address [] means dynamic, if number then that num elements, parameter when 0 to custrctor means 0 length
        winner.transfer(this.balance);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _; // Take all code of modified function... this is where  it runs
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}