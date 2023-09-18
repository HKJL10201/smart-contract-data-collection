//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./User.sol";
import "./Random.sol";

contract Lottery is usuario, Randomness {

    address internal genesis;
    address public winner;

    constructor() {
        winner = msg.sender;
        genesis = 0x0000000000000000000000000000000000000000;
    }
    
    function pago() public payable {
        require(address(this).balance > 0);
        comprobar();
        for (uint i=0; i < Users.length; i++) {
            address index_direccion = Users[i];
            uint index_numerico = numeros[i];
            pagos[index_direccion] = 0;
            delete boleto[index_numerico];
            delete time;
            Users = new address[](0);
            numeros = new uint[](0);
        }
        payable(winner).transfer(address(this).balance);
    }

    function comprobar() internal returns (address) {
        require(Users.length == 3, "Dont enough users.");
        require(block.timestamp >= time + 10 seconds, "Wait ten seconds");
        uint random_number = number();  
        if (boleto[random_number] != genesis) {
            winner = boleto[random_number];
        }
        return winner;
    }   
}
