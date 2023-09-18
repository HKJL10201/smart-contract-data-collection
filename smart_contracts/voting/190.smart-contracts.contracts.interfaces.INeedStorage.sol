// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INeedStorage {
    struct FinalVoucher {
        uint256 needId;
        bytes signature;
        address signer; // reltive / خویس‌آوند
        uint256 mintValue;
        string swSignature; // social worker signature
        string content;
    }

    struct InitialVoucher {
        uint256 needId;
        string title; 
        string category; 
        uint256 paid; 
        string deliveryCode; 
        string child; 
        address signer; 
        bytes swSignature; // social worker signature
        string role;
        string content;
    }
    function getTresaryAddress() external returns (address);
}
