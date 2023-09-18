
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Compound {

    function compound (uint principal, uint rate, uint periods) public pure returns (uint) {
        for ( uint i=0; i<periods; i++ ) {
            uint yield = principal*rate/100 ;
            principal += yield;
        }
        return principal;
    }
}