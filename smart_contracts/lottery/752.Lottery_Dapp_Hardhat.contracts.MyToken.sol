// SPX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MyToken is Context, ERC20 {
    constructor () ERC20("LotteryToKen", "LTK") {
        _mint(_msgSender(), 100000 * (10 ** 18));
    }
}