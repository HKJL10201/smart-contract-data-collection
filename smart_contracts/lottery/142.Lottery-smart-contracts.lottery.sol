pragma solidity ^0.4.17;

contract Lottery {
    
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint){
        return uint(keccak256(block.difficulty,now,players));
    }
    
    function pickwinner() public {
        require(msg.sender == manager);
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
}
