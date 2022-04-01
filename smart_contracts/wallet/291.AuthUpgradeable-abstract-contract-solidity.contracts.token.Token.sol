
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20 Token Contract
 * @author Beau Williams (@beauwilliams)
 * @dev Smart contract for Token
 */
contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {
    }
}
