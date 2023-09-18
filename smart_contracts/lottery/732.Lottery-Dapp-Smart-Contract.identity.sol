// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract Identity
{
    string name;
    uint256 age;
    constructor () public 
    {
        name = "ihtisham";
        age = 19;
    }
    function getName() public view returns(string memory)
    {
        return name;
    }
    function getAge() public view returns(uint256)
    {
        return age;
    }
}