//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

import "./153_B_Child.sol";

//This is to show how to create deploy a contract from another contract.
/*Normally we deploy contracts by ourselves. Here we are deploying it from another contract.
By deploying Parent contract, we will have Parent and Child contract deployed.
Then we can save the instance of Child contract inside this variable: "Child public child"
This variable will return the contract address of Child contract after we deploy Parent contract.
Then we can access variables and functions inside the Child contract like below. */

contract Parent {

    string public mothername;

    Child public child;

    constructor(string memory _p, string memory _m) {
        mothername = _m;
        child = new Child(_p);
    }

    function getName() external view returns(string memory) {
        return child.name();
    }



}