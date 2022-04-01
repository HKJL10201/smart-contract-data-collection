//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Price.sol";

contract usuario is PriceConsumerV3 {

    uint public time;
    address[] internal Users;
    uint[] internal numeros;

    mapping (address => uint) internal pagos;
    mapping (uint => address) internal boleto;

    function pay(uint _numero) public payable {
        require(pagos[msg.sender] == 0, "One ticket each user.");
        require(msg.value == getPriceRate(), "Verify pay.");
        require(Users.length < 3, "Max users");
        Users.push(msg.sender);
        numeros.push(_numero);
        pagos[msg.sender] += msg.value;
        boleto[_numero] = msg.sender;
        if (Users.length == 3) {
            set_time();
        }
    }

    function set_time() internal returns (uint) {
        time = block.timestamp;
        return time;
    }
}
