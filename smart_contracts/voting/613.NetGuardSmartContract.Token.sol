pragma solidity ^0.6.0;

import {ERC20} from "./ERC20.sol";

contract NGT is ERC20 {
    function decimals() public pure returns (uint8) {
        return 10;
    }

    function rounding() public pure returns (uint8) {
        return 2;
    }

    function name() public pure returns (string memory) {
        return "Netguard Tokens";
    }

    function symbol() public pure returns (string memory) {
        return "NGT";
    }
}
