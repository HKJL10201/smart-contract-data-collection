// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract A {

  address myAddress;

  function setAddressB(address _addressOtherContracts) external {
    myAddress = _addressOtherContracts;
  }

  function callHelloWorld() external view returns(string memory) {
    B b = B(myAddress);
    return b.helloWorld();
  }

  function callGetNumber() external view returns(uint) {
    C c = C(myAddress);
    return c.getNumber();
  }
  
}

contract B {
  
  function helloWorld() external pure returns(string memory) {
    return "Hello World";
  }

}

// here we can say public and result will be same. However, public costs more gas than external.
// because external functions can be accessed only externally and public functions can be accessed both 
// externally and internally. In this Contract B and Contract C functions, we do not NEED to access them internally (public),
// we want to access them only from the Contract A., which means only externally. So, after declaring them external, 
// if I try to access them not from contract A, it will give error.

contract C {
  function getNumber() external pure returns(uint) {
    return 666;
  }
}