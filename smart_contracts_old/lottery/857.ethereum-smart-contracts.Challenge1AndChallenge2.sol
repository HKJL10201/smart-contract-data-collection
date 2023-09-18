//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CryptosToken{
    string public constant name = "Cryptos";
    uint supply;
    address public owner;

    constructor() public{

        owner = msg.sender;
        supply = 0;
    }


    function setSupply(uint _supply) public {

        supply = _supply;
    }

    function getSupply() public view returns(uint){

        return supply;
    }
}