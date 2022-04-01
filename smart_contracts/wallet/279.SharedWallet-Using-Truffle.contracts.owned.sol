pragma solidity ^0.4.19;

contract owned
{
   address owner;

   modifier onlyOwner()
   {
       if(msg.sender==owner)
       {
           _;
       }
   }
   constructor() public
   {
       owner=msg.sender;
   }
}
