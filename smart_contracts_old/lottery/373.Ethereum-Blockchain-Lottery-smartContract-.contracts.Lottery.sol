pragma solidity 0.4.17;

contract Lottery {
    
    address public manager;
    address[] public players;
    
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function addPlayer() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns(uint) {
        uint(sha3(block.difficulty, now, players));
    }
    
    function pickWinner() public {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function entries() public view returns(address[]){
        return players;
    }
}