//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract simpleContract{ 

uint256 public value;



function setValue(uint256  newValue) public {
value = newValue;

 }
function retrieve()  public view returns(uint256) { 
return value; 
}

}
