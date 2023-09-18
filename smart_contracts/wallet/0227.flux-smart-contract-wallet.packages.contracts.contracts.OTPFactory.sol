// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./OTP.sol";

contract OTPFactory {
    OTP[] private _otps;

    event ContractCreated(address newAddress);

    function createOTP(address _verifier, uint256 merkleRoot) public {
        OTP otp = new OTP(_verifier, merkleRoot);
        _otps.push(otp);
        emit ContractCreated(address(otp));
    }
}
