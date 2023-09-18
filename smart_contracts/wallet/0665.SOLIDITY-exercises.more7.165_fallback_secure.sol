//SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

contract Apple {

    function unexpectedCall() external payable {
        revert("Unexpected function call");
    }

    fallback() external payable {
        unexpectedCall();
    }

    /*
    Because the fallback() function can be called in unexpected situations, it 
    is important to implement it carefully to ensure that it cannot be used to 
    exploit the contract. One common approach is to use a revert() statement at 
    the beginning of the function to reject any unexpected calls.
     */


}