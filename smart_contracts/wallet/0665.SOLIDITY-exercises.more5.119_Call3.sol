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

    function getBalance() external view returns(uint){
        return address(this).balance;
    }
}

contract Call {
    //CALL ANOTHER CONTRACT FUNCTION IN OLD REGULAR STYLE
    function call1(address payable otherContract, string memory a, uint b) external {
        TestCall(otherContract).foo(a, b);
    }

    //CALL ANOTHER CONTRACT FUNCTION BY USING CALL METHOD
    bytes public data;

    function callFoo(address _test) external payable{
        (bool success, bytes memory _data) = _test.call{value: msg.value}(abi.encodeWithSignature("foo(string,uint256)", "hello", 123));
        require(success, "failed to call");
        data = _data;
    }

    //CALL ANOTHER CONTRACT FUNCTION(WHICH DOESNT EXIST) BY USING CALL METHOD
    //Our purpose is to trigger fallback. Because we cannot trigger fallback by using the old regular style.
    //If I make value: msg.value, then I need to declare the callFoo2 as payable
    //If I delete the fallback function above, then this transaction will fail, because
    //it means I cannot send 123 wei to anywhere.
    function callFoo2(address _test) external {
        (bool success, bytes memory _data) = _test.call{value: 123}(abi.encodeWithSignature("asdf(string,uint256", "farmhouse", 569));
        require(success, "failed to call");
        data = _data;
    }

}