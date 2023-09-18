//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CounterV1 {
    address public implementation;
    address public admin;
    uint public count1;

    function inc1() external {
        count1 += 1;
    }
}

contract CounterV2 {
    address public implementation;
    address public admin;
    uint public count2;

    function inc2() external {
        count2 += 1;
    }

    function dec() external {
        count2 -= 1;
    }
}

contract BuggyProxy {
    address public implementation;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function upgradeTo(address _newImp) external {
        require(msg.sender == admin, "not authorized");
        implementation = _newImp;
    }

    function _delegate() private {
        (bool success, bytes memory res) = implementation.delegatecall(msg.data);
        require(success, "delegatecall failed");
    }
    fallback() external payable {
        _delegate();
    }
    receive() external payable {
        _delegate();
    }
}