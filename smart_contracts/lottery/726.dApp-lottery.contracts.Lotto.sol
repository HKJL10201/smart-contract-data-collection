pragma solidity ^0.4.17;

contract Lotto {
    address public manager;
    address[] public players;
    
    function Lotto() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() restricted public {
        require(msg.sender == manager);
        
        uint index = random() % players.length;
        address winnerAddress = this;
        
        players[index].transfer(winnerAddress.balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayer() public view returns (address[]) {
        return players;
    }
}