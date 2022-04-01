pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract ContractCallingItself {

    uint someVar = 10;

    function callSelf() public {
        address selfAddress = address(this);
        ContractCallingItself selfContract = ContractCallingItself(selfAddress);
        selfContract.doubleSomeVar();
    }

    function doubleSomeVar() public {
        someVar = someVar * 2;
    }

    function getSomeVar() public view returns (uint) {
        return someVar;
    }
}
