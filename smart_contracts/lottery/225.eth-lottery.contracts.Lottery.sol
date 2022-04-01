pragma solidity ^0.4.17;

contract Lottery {
    
    address public manager;
    address[] public entrants;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= .01 ether);
        entrants.push(msg.sender);
        
    }
    
    function random() private view returns (uint) {
        // Generate (psuedo) random number
        // psuedo because depending on the time someone entered
        // it could potentially influence the result
        return uint(keccak256(block.difficulty, now, entrants));
    }
    
    function pickWinner() public restricted {
        // 1. Generate (psuedo) random number
        uint index = random() % entrants.length;
        // 2. Select winner using the random index
        entrants[index].transfer(this.balance);
        // 3. Empty list of entrants after winner is picked
        entrants = new address[](0);
    }
    
    modifier restricted() {
        // function does not need to be named 'restricted'
        // can be anything
        
        // this function checks that the manager is the
        // account calling any subsequent functions
        require(msg.sender == manager);
        // underscore essentially is a place holder
        // for all subsequent code called with the 
        // restricted modifier
        _;
    }
    
    function getEntrants() public view returns (address[]) {
        return entrants;
    }
}
