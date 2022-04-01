pragma solidity ^0.4.17;

contract Lottery {
    address public manager; // public as we want to get access to manager from the front end js
    
    // whenever someone creates an instance of this contract, we want to set the manager variable to the addresss from which the transaction object was sent
    // the constructor function is called automatically when we create a new instance of the contract
    
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        // when a function expects to have some ether sent to it, it has to be marked payable
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        // clearing out the player array
        players = new address[](0);
        // the second parenthesis is to indicate that its initial size should be 0
        // if we had given (5) we would get [0x0000, 0x0000, 0x0000, 0x0000, 0x0000]
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}