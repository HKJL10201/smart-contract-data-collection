pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;
    
    // constructor function prototype changed in newer versions of solidity
    function Lottery() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManager {
        uint winner = random() % players.length;
        players[winner].transfer(this.balance);
        lastWinner = players[winner];
        players = new address[](0);
    }
    
    function bal() public view returns (uint) {
        return this.balance;
    }
    
    // helper function to restrict only to manager
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    // initial getter supplied by contract only returns 1 index
    // of players array so need a custom getter
    function getPlayers() public view returns(address[]) {
        return players;
    }
    
}

contract Bigtits {
    address public manager;
    address[] public players;
    
    // constructor function prototype changed in newer versions of solidity
    function Lottery() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManager {
        uint winner = random() % players.length;
        players[winner].transfer(this.balance);
        players = new address[](0);
    }
    
    function bal() public view returns (uint) {
        return this.balance;
    }
    
    // helper function to restrict only to manager
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    // initial getter supplied by contract only returns 1 index
    // of players array so need a custom getter
    function getPlayers() public view returns(address[]) {
        return players;
    }
    
}