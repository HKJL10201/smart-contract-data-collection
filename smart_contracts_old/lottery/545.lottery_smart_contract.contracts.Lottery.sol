pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        //msg.value returns value in wei;
        require(msg.value > .01 ether);
        
        players.push(msg.sender);
    }
    
    function pickWinner() public restricted {
        require(players.length > 0);
        
        uint index = random() % players.length;
        
        players[index].transfer(this.balance);
        
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function random() private view returns (uint) {
        //pseudo random number generator
        //there is a possibility of gaming it
        return uint(keccak256(block.difficulty, now, players));
    }
}
