pragma solidity ^0.4.17;

contract PoolLottery {
    address public manager;
    address public lastWinner;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function joinLottery() public payable {
        require(msg.value == 0.01 ether);
        
        players.push(msg.sender);
    }
    
    function randomInt() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint index = randomInt() % players.length;
        lastWinner = players[index];
        lastWinner.transfer(address(this).balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}
