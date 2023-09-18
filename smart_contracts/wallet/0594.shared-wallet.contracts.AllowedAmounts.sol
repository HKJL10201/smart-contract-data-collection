// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract AllowedAmounts is Ownable {
    mapping(address => uint256) amountsToWithdraw;

    modifier allowedToWithDraw(uint256 _amount) {
        require(
            owner() == msg.sender || _amount <= amountsToWithdraw[msg.sender],
            "Not allowed to withdraw such amount."
        );
        _;
    }

    event AllowedAmountChanged(
        address indexed _from,
        address indexed _subject,
        uint256 _oldAmount,
        uint256 _newAmount
    );

    function changeAllowance(address _subject, uint256 _amount)
        public
        onlyOwner
    {
        emit AllowedAmountChanged(
            msg.sender,
            _subject,
            amountsToWithdraw[_subject],
            _amount
        );

        amountsToWithdraw[_subject] = _amount;
    }

    function reduceAmountToWithdraw(address _subject, uint256 _amount)
        internal
    {
        emit AllowedAmountChanged(
            msg.sender,
            _subject,
            amountsToWithdraw[_subject],
            amountsToWithdraw[_subject] - _amount
        );

        amountsToWithdraw[_subject] -= amountsToWithdraw[_subject];
    }
}
