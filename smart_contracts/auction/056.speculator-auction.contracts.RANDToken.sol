//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./RANDMinter.sol";
import "./IERC20Mintable.sol";

contract RANDToken is ERC20, RANDMinter, IERC20Mintable {
    constructor() public ERC20("RAND", "RND") {}

    function mint(address recipient, uint256 amount)
        public
        override
        onlyMinter
    {
        _mint(recipient, amount);
    }
}
