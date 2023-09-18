// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./vectorLib.sol";

contract PAVCalculator {
    
    int256 constant private _DENOMINATOR = 1e18;
    function denominator() public pure returns (int256) { return _DENOMINATOR; }

    function calcVotingPower(int256[] memory vote, int256[] memory option) public pure returns (int256){
        int256 votingPower = 0;
        int256 matchingCounter = 0;

        matchingCounter = vectorLib.dot(vote, option);

        if(matchingCounter > 0) {
            for (int256 i = 1; i < matchingCounter + 1; i++) {
                votingPower += _DENOMINATOR / i;
            }
        }
        return votingPower;

    }
}
