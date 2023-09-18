pragma solidity ^0.4.25;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether); // require is a global var
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
       return uint(keccak256(abi.encodePacked(block.difficulty, now, players))); // 'keccak256' + 'block' is a global var 
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length; 
        players[index].transfer(address(this).balance);
        // addresses are objects with function tied to them
        // 'this' is a ref to the current contract
        players = new address[](0);
    } 
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayer() public view returns(address[] memory) {
        return players;
    }
    
    
}
