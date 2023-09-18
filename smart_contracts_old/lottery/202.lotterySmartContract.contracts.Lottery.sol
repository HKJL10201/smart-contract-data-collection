pragma solidity ^0.5.0;

contract Lottery {
    address public manager;
     address payable[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > 1 wei,"You need to pay some ether");
        players.push(msg.sender);
    }
    
    function random() private view returns(uint){
        uint source = block.difficulty + now;
        bytes memory source_b = toBytes(source);
        return uint(keccak256(source_b));
    } 
    
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager,"Only manager can call this");
        _;
    }
    
    function getPlayers() public view returns(address payable[] memory){
        return players;
    }
 
}