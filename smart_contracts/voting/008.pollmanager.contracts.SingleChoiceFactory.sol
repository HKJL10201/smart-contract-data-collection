pragma solidity ^0.4.6;

import "./SingleChoice.sol";

contract SingleChoiceFactory {
    uint salt;
    function create(bytes _description) returns(address) {
        salt++;
        SingleChoice sc = new SingleChoice(msg.sender, _description, salt);
        SingleChoiceCreated(address(sc));
        return address(sc);
    }

    event SingleChoiceCreated(address indexed addr);
}
