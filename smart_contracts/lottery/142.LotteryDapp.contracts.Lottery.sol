pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public persons;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > 0.001 ether);
        
        persons.push(msg.sender);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;        
    }
    
    function getRandom() private view restricted returns (uint) {
        return uint(keccak256(block.difficulty, now, persons));
    }
    
    function pickWinner() public restricted {
        uint index = getRandom() % persons.length;
        persons[index].transfer(this.balance);
        persons = new address[](0);
    }
    
    function getPlayers () public view returns(address[]) {
        return persons;
    }
    
}