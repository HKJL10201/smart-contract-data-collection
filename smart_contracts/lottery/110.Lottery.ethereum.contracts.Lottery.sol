pragma solidity ^0.4.17;

contract Lottery {
    address public manager;// Holds a 20 byte value (size of an Ethereum address).
     address[] public players;
    
    function Lottery() public {
        manager = msg.sender;//when deploying msg.sender is the owner of the contract
    }
    
    function enter() public payable { //method is payble if it receives a ether during the transaction
        
        require(msg.value > 0.1 ether);
        players.push(msg.sender);
    }
    
    
    function random() public  view returns (uint) {
        
     return   uint(keccak256(block.difficulty,now,players));//hashing
    }
   
  function pickWinner() public restricted{
      uint index = random() % players.length;
      players[index].transfer(this.balance);
      players = new address[](0);//give array with no element
  }
   
  modifier restricted(){ //meamgin apita function ekak action ekak wenas kla haki
       
      require (msg.sender == manager);
      _;//original code eka methanta danda kyla kynne mekn
  }
   
  function getPlayers() public view returns (address[]) {
      return players;
       
  }
   
}