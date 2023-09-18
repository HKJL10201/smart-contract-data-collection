pragma solidity ^0.4.17;
contract Lottery {
    address public manager;
    address[] public players;
    mapping (address => uint) index;

    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        if (index[msg.sender] == 0) {
            players.push(msg.sender);
        }
        index[msg.sender] += msg.value;
    }
    
    function random() private view returns(uint256) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManager {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    } 
    
    function getPlayers() public view returns(address[]) {
        return players;
    }
    
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
}