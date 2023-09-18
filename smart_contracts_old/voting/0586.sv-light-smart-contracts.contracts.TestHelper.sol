pragma solidity ^0.4.24;

import {upgradePtr, payoutAllCSettable} from "./SVCommon.sol";

contract TestHelper is upgradePtr {
    // note: a test relies on this contract having no owner or controller method / public var

    struct DataAndValue {
        bytes data;
        uint value;
    }

    mapping (address => bytes) public justData;
    mapping (address => DataAndValue) public dataAndValue;
    mapping (address => uint) public justValue;

    function() external payable {
        require(msg.value != 1999, "cannot deposit 1999 wei as special value");
        justValue[msg.sender] = msg.value;
    }

    function willThrow() external payable {
        revert();
    }

    function storeData(bytes data) external {
        justData[msg.sender] = data;
    }

    function storeDataAndValue(bytes data) external payable {
        dataAndValue[msg.sender] = DataAndValue(data, msg.value);
    }

    function reentrancyHelper(address to, bytes data, uint value) external payable {
        require(to.call.value(value)(data), "tx should succeed");
    }

    function destroy(address a) external {
        selfdestruct(a);
    }
}


contract ControlledTest {
    address public controller;
    constructor() public {
        controller = msg.sender;
    }
}


contract payoutAllCSettableTest is payoutAllCSettable {
    // you can use this to send balances to a contract by first sending eth then calling selfdestruct
    // in this case _this_ contracts payTo doesn't matter
    constructor (address initPayTo) payoutAllCSettable(initPayTo) {

    }

    function() payable public {
        // do nothing
    }

    function setPayTo(address a) external {
        _setPayTo(a);
    }

    function sendTo(address to, bytes data, uint value) external payable {
        doSafeSendWData(to, data, value);
    }

    function selfdestruct(address a) external {
        selfdestruct(a);
    }
}
