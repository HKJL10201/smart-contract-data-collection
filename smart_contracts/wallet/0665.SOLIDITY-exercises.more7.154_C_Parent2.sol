//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

import "./153_B_Child.sol";

contract Parent2 {

    /*
    Previous parent is creating a new instance of the child contract.
    In other words, it is deploying it. If you want to create a contract
    variable from an already existing contract, then do below:  
    
     */

    Child public child;

    constructor(address _childAddress) {
        child = Child(_childAddress);
    }


}
