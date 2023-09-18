// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract SafePayment {
    event FailedPayment(address to, uint256 amount);

    uint256 private constant GAS_LIMIT = 3_000;
    bool private _payLock = false;
    uint256 private _unclaimed;

    function safeSendETH(address to, uint256 amount)
        internal
        returns (bool success)
    {
        require(!_payLock); // solhint-disable-line reason-string
        _payLock = true;
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = payable(to).call{value: amount, gas: GAS_LIMIT}("");
        if (!success) {
            _unclaimed += amount;
            emit FailedPayment(to, amount);
        }
        _payLock = false;
    }

    function getUnclaimed(address to) internal returns (bool success) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = payable(to).call{value: _unclaimed}("");
        if (success) {
            _unclaimed = 0;
        }
    }
}
