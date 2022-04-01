pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
