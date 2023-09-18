//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

//CALL - ABI.ENCODEWITHSELECTOR

import "./121_A.sol";

contract F {

    function foo(address otherContract, string memory x) external {
        (bool success, ) = otherContract.call(abi.encodeWithSelector(A.changeWord.selector, x));
        require(success, "failed to call");
    }

    //The state of E does not change.
    //The state of A changes.
    //Import statement is used.
    //it is cheaper than Signature.
}