// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BlockRoomCoin
 * @author javadyakuza
 * @notice this ERC-20 token is used as a test payment token to test the functionality of the BlockRoom
 */
contract BlockRoomCoin is ERC20, Ownable {
    constructor() ERC20("BlockRoomCoin", "BRC") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
