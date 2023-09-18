pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
     function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        // Needed at least 0.01 ether to performing a transaction
        require(msg.value > .01 ether);
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, block.timestamp, players));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        // Only Manageer can calling this function
        require(msg.sender == manager);
        // _; means the add-ons code of any function that use restricted
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
}