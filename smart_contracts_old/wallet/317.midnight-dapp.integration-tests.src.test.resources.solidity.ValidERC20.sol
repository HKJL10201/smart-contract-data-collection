pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./base/StandardToken.sol";


contract ValidERC20 is StandardToken {
    address private creator;

    constructor () {
        creator = msg.sender;
    }

    function name () public pure returns (string memory) {
        return "Valid";
    }

    function symbol () public pure returns (string memory) {
        return "VLD";
    }

    function decimals () public pure returns (uint8) {
        return 18;
    }

    function giveMeSome (address _target, uint256 amount) public returns (bool) {
        require(msg.sender == creator);

        balances[_target] = balances[_target] + amount;
        increaseApproval(msg.sender, amount);
        totalSupply_ = totalSupply_ + amount;
        return true;
    }
}
