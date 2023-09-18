//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

//REGULAR FUNCTION CALL
import "./121_A.sol";

contract D {

    function foo(address otherContract, string memory x) external {
        A(otherContract).changeWord(x);
    }

    //The state of D does not change.
    //The state of A changes.
    //Import statement is used.

    /* ANOTHER ADDITION WITH RETURN STATEMENT
    function foo(address otherContract, string memory x) external view returns(string memory) {
        return A(otherContract).changeWord(x);
    }
    */

}