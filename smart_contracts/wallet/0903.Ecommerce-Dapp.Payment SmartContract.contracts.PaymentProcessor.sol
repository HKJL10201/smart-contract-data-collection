// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract PaymentProcessor{
    address public admin;
    IERC20 public dai;
    event PaymentDone(
        address payer,
        uint paymentAmount,
        uint paymentId,
        uint date
    );
    constructor(address adminAddress, address daiAddress) public {
        admin = adminAddress;
        dai= IERC20(daiAddress);

    }
    function pay (uint _amount, uint _paymentId) external {
        dai.transferFrom(msg.sender,admin,_amount);
        emit PaymentDone(msg.sender,_amount,_paymentId,block.timestamp);

    }
}