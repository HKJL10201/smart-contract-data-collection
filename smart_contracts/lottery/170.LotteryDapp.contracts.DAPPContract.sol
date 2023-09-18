// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Try.sol";

contract DAppContract {

    uint public value;
    Try public tryInstance;
    event click();

    constructor() {

        value = 42;
        tryInstance = new Try();
        
    }

    function pressClick() public {
        
        emit click();
    }
}