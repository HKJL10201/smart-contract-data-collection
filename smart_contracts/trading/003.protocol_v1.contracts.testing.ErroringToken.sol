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

import { TestToken } from "./TestToken.sol";


contract ErroringToken is TestToken {

    function transfer(address, uint256) public returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public returns (bool) {
        return false;
    }

    function approve(address, uint256) public returns (bool) {
        return false;
    }
}
