// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Storage {
    uint256  public number = 0 ;

    function setter(uint256 _number) external {
        number = _number;
    }

    function getter() external view returns (uint256) {
        return number;
    }
}