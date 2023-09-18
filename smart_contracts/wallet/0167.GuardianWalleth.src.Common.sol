// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Common{
    struct TransactionUIData{
        address user;
        uint transactionIndex;
        address to;
        uint amount;
        bool voteStatus;
    }

    enum TransactionType {
        None,
        Eth,
        Token
    }
}
