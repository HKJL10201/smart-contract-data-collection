//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract HexTest{
    function getAddress() external pure returns(address) {
        return address(0);
    }

    bytes32 public myWord =bytes32("Hello");
    bytes32 public myWord2 = bytes32(0);
}