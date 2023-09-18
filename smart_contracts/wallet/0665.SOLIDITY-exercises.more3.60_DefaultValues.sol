//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract DefaultValues {
    uint public a; // 0
    int public b; // 0
    string public c; // empty string
    address public d; // 0x0000...
    bytes32 public e; // 0x0000..64 zeros after x
    bool public f; // false
}