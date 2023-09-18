// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract A {
    address public ownerA;

    constructor(address eoa) {
        ownerA = eoa;
    }
}

contract Creator {
    address public ownerCreator;
    A[] public deployedA;

    constructor() {
        ownerCreator = msg.sender;
    }

    function deployA() public {
        A newAAddress = new A(msg.sender);
        deployedA.push(newAAddress);
    }
}
