pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract Throw {
    function justThrow() pure public {
        assert(false);
    }
}
