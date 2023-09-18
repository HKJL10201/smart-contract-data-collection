pragma solidity >=0.8.7;

contract TestEvent {
   event Deposit(address indexed _from, bytes32 indexed _id, uint _value);
   function deposit(bytes32 _id) public payable {      
      emit Deposit(msg.sender, _id, msg.value);
   }
    //this array below is only for getting some bytes value to use
    // as argument for the above function. 
   bytes32[] public myArray = [bytes32("apple"), bytes32("orange")];
}