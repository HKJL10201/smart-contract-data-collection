// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

contract Caller {
    receive() external payable {}

    function _call(
        address _address,
        uint256 _amount,
        bytes memory data
    ) external {
        require(address(this).balance >= _amount, "Nop");
        (bool success, ) = payable(_address).call{value: _amount}(data);
        require(success, "noop");
    }
}
