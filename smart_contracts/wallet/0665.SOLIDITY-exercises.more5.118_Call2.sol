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

contract Call {
    function call1(address payable otherContract, string memory a, uint b) external {
        TestCall(otherContract).foo(a, b);
    }

/* As a different thing than previous contract, we used "call" method to call function of a another
contract. Bytes data variable is only for you to see.
To use call method, we need to encode 1)the function name + 2)its parameters + 3)our values for parameters.
The different thing here is I didnt have to specify the address as payable.  */
    bytes public data;

    function callFoo(address _test) external payable{
        (bool success, bytes memory _data) = _test.call{value: msg.value}(abi.encodeWithSignature("foo(string,uint256)", "hello", 123));
        require(success, "failed to call");
        data = _data;
    }
}