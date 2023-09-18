pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./IERC20.sol";

contract MockERC20 is IERC20 {

    // If not initialized the contract allows burns to be done
    bool disallowsBurns;

    constructor(bool allowsBurnsBool) {
        disallowsBurns = !allowsBurnsBool;
    }

    function totalSupply() override external view returns (uint256) {}

    function balanceOf(address account) override external view returns (uint256) {}

    function transfer(address recipient, uint256 amount) override external returns (bool) {}

    function allowance(address owner, address spender) override external view returns (uint256) {}

    function approve(address spender, uint256 amount) override external returns (bool) {}

    function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {}

    function mint(address account, uint256 amount) override external {}

    function burn(address, uint256) override view external {
        assert(!disallowsBurns);
    }

}
