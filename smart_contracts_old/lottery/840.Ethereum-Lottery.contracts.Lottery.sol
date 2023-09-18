pragma solidity ^0.4.17;
  
contract Lottery {
  address public manager;
  address[] public players;
  
  function Lottery() public {
    //Whenever the contract is created we get the sender's address
    //as manager.
    manager = msg.sender;
  }
  
  // Selecting payable means the external account who calls
  // this function will submit some money. And the money
  // is added into this.balance.
  function enter() public payable {
    // If it does not meet the requirement, it does not
    // run to the next ling of code.
    require(msg.value > .01 ether);
    players.push(msg.sender);
  }
  
  //Implement a function to generate pseudo-random number.
  // Solidity does not have random number generater.
  function random() private view returns(uint) {
    // keccak256() is the same as sha3(). It runs SHA3 algorithm.
    // block is a global variable. It is this contract.
    // now is a global variable. It is the current time.
    // uint is uint256.
    return uint(keccak256(block.difficulty, now, players));
  }
  /*    
  function pickWinner() public {
    // Make sure only manager can call this function.
    require(msg.sender == manager);
  
    uint index = random() % players.length;
    //this is the instance of this contract. It has a varilable
    // called balance. It shows all the money this instance has.
    players[index].transfer(this.balance);
      
    //After picking a winner we clean the players list and start
    // next round of Lottery
    // It means it is non-fixed array and initial size or memory
    // allocated is zero.
    players = new address[](0);
  }
   */
          
  modifier OnlyManagerCanCall() {
    require(msg.sender == manager);
    _;
  }
  
  function pickWinner() public OnlyManagerCanCall {
    uint index = random() % players.length;
    players[index].transfer(this.balance);
    players = new address[](0);
  }
  
  function getPlayers() public view returns (address[]) {
    return players;
  }
}
