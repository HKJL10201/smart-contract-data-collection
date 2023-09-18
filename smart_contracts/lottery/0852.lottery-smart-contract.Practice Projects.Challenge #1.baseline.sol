//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CryptosToken{
    string public name = "Cryptos";
    uint supply;
    address public owner;

    constructor(){
       owner = msg.sender;
    }

    function setter(uint _supply) public {
        supply = _supply;
    }

        function getter() public view returns(uint){
        return supply;
    }
}