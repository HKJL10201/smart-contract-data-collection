//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Adapter {
    function router() external returns (address);
    function swap(IERC20 from, IERC20 to, uint amount, uint minOut, address destination) external;
    function getRatio(IERC20 from, IERC20 to, uint amount) external view returns (uint);
}