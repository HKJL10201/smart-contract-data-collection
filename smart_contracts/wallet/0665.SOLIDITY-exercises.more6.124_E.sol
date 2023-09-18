//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

//CALL - ABI.ENCODEWITHSIGNATURE

contract E {

    function foo(address otherContract, string memory x) external {
        (bool success, ) = otherContract.call(abi.encodeWithSignature("changeWord(string)", x));
        require(success, "failed to call");
    }

    //The state of E does not change.
    //The state of A changes.
    //Import statement not used.
}