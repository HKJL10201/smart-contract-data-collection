//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A{

    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) external payable{
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }

}

contract B{
    /*Make sure the order of variables is totally the same as above*/
    uint public num;
    address public sender;
    uint public value;
    /*
    FUNCTION 1: If I call in below way, the variables in contract A will change.
    function setVars(address _test, uint _num) external payable{
        (bool success, ) = _test.call(abi.encodeWithSignature("setVars(uint256)", _num));
        require(success, "failed to call");
    }
    */
    //FUNCTION 2.1: If I call in below way, the variables in Contract B will change.
    //execution cost: 72k wei.
    function setVars(address _test, uint _num) external payable{
        (bool success, ) = _test.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));
        require(success, "failed to call");
    }
    //FUNCTION 2.2: execution cost is cheap comparatively, 35k wei
    function foo(address _test, uint _myNumber) external payable {
        (bool success, ) = _test.delegatecall(abi.encodeWithSelector(A.setVars.selector, _myNumber));
        require(success, "faile to call");
    }

    /*Now I understand the importance of delegatecall. By seperating function implementation from the contract, 
    you can later update the contract B without redeploying it. You will redeploy contract A instead. 
    */
}

