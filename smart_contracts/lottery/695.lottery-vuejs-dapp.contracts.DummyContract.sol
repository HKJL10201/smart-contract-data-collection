pragma solidity ^0.4.0;

contract DummyContract {
 address public owner;

 constructor() public {
   owner = msg.sender;
 }
}
