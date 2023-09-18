pragma solidity ^0.4.17;
//deploying contract to rinkeby test network
//infrua API
//https://rinkeby.infura.io/v3/0ac6b8409aa34a99870301dbb4bef246

//https://rinkeby.etherscan.io/
contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;   
    }
    
    function enter() public payable{
        //minimum amount of ether
        require(msg.value > .01 ether);
        players.push(msg.sender);//make test here to determine that the enter function works
    }
    
    function random() private view returns (uint){
      return uint(keccak256(block.difficulty, now, players));
       
    }
    
    function pickWinner()public restricted {
        
        
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier restricted(){
        require(msg.sender == manager); //enforce security
        _;//run all the rest of the code inside this function
    }
    
    function getPlayers()public view returns(address[]){
        return players;
    }
    
}