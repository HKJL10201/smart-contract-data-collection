//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract TestContract {

    uint public value;

    function complete(uint _value) external {
        value = _value;
    }

    function getData() public pure returns(bytes memory) {
        return abi.encodeWithSelector(this.complete.selector, 888);
    }
}

