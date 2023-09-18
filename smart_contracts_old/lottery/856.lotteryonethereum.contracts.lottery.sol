pragma solidity >=0.4.22 <0.6.0;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager=msg.sender;
    }
    
    modifier adminOnly() {
        require(msg.sender==manager);
        _;
    }
    
    function enter() payable public {
        require(msg.value>0.01 ether);
        
        players.push(msg.sender);
    }
    
    function random() private view returns(uint){
        return uint256(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public adminOnly {
        players[random()%players.length].transfer(address(this).balance);
        players=new address[](0);
    }

    function getPlayers() public view returns(address[]){
        return players;
    }
    
    
    
}