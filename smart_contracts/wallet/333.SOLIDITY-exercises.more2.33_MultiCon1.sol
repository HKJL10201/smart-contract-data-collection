// SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract A {

    address myAddress;

    function setAddress(address _newContract) external {
        myAddress = _newContract;
    }

    function getValue(uint _testNumber2) external view returns(uint) {
        B b = B(myAddress);
        return b.getValue(_testNumber2);
    }
  

}

contract B {
    function getValue(uint _testNumber) external pure returns(uint){
        return _testNumber;
    }
}