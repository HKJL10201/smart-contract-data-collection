// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Timer {
    uint256 start;
    uint256 timeout;
}

library TimerLib {
    function exceeded(Timer storage t) internal view returns (bool) {
        if (t.start == 0) return false;
        return block.timestamp > t.start + t.timeout;
    }
}
