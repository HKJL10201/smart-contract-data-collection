/*

    Copyright 2018 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.4.24;
pragma experimental "v0.5.0";

import { MathHelpers } from "../lib/MathHelpers.sol";
import { InterestImpl } from "../margin/impl/InterestImpl.sol";


contract TestInterestImpl {

    uint256 test = 1; // to keep these functions as non-pure for testing

    function getCompoundedInterest(
        uint256 tokenAmount,
        uint256 interestRate,
        uint256 secondsOfInterest
    )
        public
        returns (
            uint256
        )
    {
        if (false) {
            test = 1;
        }
        return InterestImpl.getCompoundedInterest(
            tokenAmount,
            interestRate,
            secondsOfInterest
        );
    }
}
