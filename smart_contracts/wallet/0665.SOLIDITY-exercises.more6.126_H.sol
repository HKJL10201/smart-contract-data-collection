//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

//DELEGATECALL - ABI.ENCODEWITHSELECTOR
import "./121_A.sol";

contract H {

    string public myWord = "Mardin";
    
    function foo(address otherContract, string memory x) external {
        (bool success, ) = otherContract.delegatecall(abi.encodeWithSelector(A.changeWord.selector, x));
        require(success, "failed to call");
    }

    //The state of E does not change.
    //The state of A changes.
    //Import statement is used.
    //It is cheaper than Signature.
}

