pragma solidity ^0.4.25;
contract Lottery {

    address manager;
    
    address[] participants;
   
    function Lottery() {
        manager = msg.sender;        
    }
    
    function joinMe() payable
    {
      require(msg.value>0.01 ether);
       participants.push(msg.sender);
    }
    
    function random() private view returns(uint){
        return uint(keccak256(block.difficulty,now,participants));
    }
    
   
    
    function pickWinner() public
    {
        require(msg.sender==manager);
        uint index=random()% participants.length;
        participants[index].transfer(this.balance);
        
    }
    
    
    
    function getManager() public returns (address){
       return manager;
   }
   
   function getParticipants() public returns (address[]){
       return participants;
   }
   
   
}