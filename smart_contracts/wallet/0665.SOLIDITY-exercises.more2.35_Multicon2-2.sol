//SPDX-Licence-Identifier: MIT
pragma solidity >=0.8.7;

interface InterfaceB {
    function getString(string memory _anyText) external pure returns(string memory);

}

contract B {
    function getString(string memory _anyText) external pure returns(string memory) {        
        return _anyText;
    }

    function getHello() external pure returns(string memory) {
        return "Hi";
    }
}