// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBribeV2 {
    function active_period(address gauge, address reward_token) external view returns (uint);
    function add_reward_amount(address gauge, address reward_token, uint amount) external returns (bool);
}