//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
    using SafeMath for uint256;

    event AllowanceChanged(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 previousBalance,
        uint256 newBalance
    );

    mapping(address => uint256) public allowance;

    //  an exposed function to check if the msg.sender is the owner
    function isOwner() public view returns (bool) {
        return owner() == msg.sender;
    }

    modifier owenerOrAllowedUser(uint256 amount) {
        require(
            isOwner() || allowance[msg.sender] >= amount,
            "You aren't allowed to withdraw."
        );
        _;
    }

    // function to set allowance for external users, only owner is allowed
    function setAllowance(address forAddress, uint256 amount) public onlyOwner {
        emit AllowanceChanged(
            owner(),
            forAddress,
            allowance[forAddress],
            amount
        );
        allowance[forAddress] = amount;
    }

    // function to reduce allowance for external users
    function reduceAllowance(address fromAddress, uint256 amount)
        internal
        owenerOrAllowedUser(amount)
    {
        emit AllowanceChanged(
            fromAddress,
            msg.sender,
            allowance[fromAddress],
            allowance[fromAddress].sub(amount)
        );
        allowance[fromAddress] = allowance[fromAddress].sub(amount);
    }

    // overriding renounce ownership function to avoid renouncing ownership
    function renounceOwnership() public view override onlyOwner {
        revert("This smart contract prohibits renouncing ownership");
    }
}
