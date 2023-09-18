//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract TestCall {
    string public message;
    uint public x;

    event Log(string message);

    fallback() external payable{
        emit Log("fallback triggered");
    }

    function foo(string memory _message, uint _x) external payable returns(bool, uint){
        x = _x;
        message = _message;
        return (true, 999);
    }
}

/*Here this is the meaning of the exercise actually. I am calling payable foo
function from another contract. Fallback and event has no meaning for this exercise.

I can change TestCall contract state variables' values by using the function below.*/
contract Call {
    function call1(address payable otherContract, string memory a, uint b) external {
        TestCall(otherContract).foo(a, b);
    }
}