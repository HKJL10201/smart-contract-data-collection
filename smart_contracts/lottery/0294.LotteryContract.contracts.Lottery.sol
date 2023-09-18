pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    // updated version - 
    //     constructor() {
    //     manager = msg.sender;
    // }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManager {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
        // new dynamic array (hence it is empty) that has a starting defualt of zero addresses in it (0)
    }
    
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    function getAllPlayers() public view returns (address[]) {
        return players;
    }
    // address payable[] memory
    // function getPlayers() public view returns (address payable[] memory) {
    //     return players;
    // }
}   