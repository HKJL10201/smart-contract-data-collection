//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    // (user_address => token_address -> amount_locked)
    mapping(address => mapping(address => UserVaultTokenDetail))
        public userVault;
    uint256 public totalInVault;

    struct UserVaultTokenDetail {
        address userAddress;
        uint256 totalAmount;
        bool isExists;
    }

    function _setUserVault(
        address userAddress,
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        IERC20 paymentToken = IERC20(tokenAddress);
        if (userVault[userAddress][tokenAddress].isExists) {
            userVault[userAddress][tokenAddress].totalAmount = amount;
        } else {
            userVault[userAddress][tokenAddress] = UserVaultTokenDetail(
                userAddress,
                amount,
                true
            );
        }
        // Approve userWallet to be able to withdraw this token from the vault when needed
        uint256 walletTokenAllowance = paymentToken.allowance(
            address(this),
            msg.sender
        );
        paymentToken.approve(msg.sender, walletTokenAllowance + amount);
    }

    function _getUserVault(address userAddress, address tokenAddress)
        public
        view
        returns (UserVaultTokenDetail memory)
    {
        if (userVault[userAddress][tokenAddress].isExists) {
            return userVault[userAddress][tokenAddress];
        } else {
            return UserVaultTokenDetail(address(0), 0, false);
        }
    }

    function _setTotalInVault(uint256 amount) internal {
        if (totalInVault == 0) {
            totalInVault = amount;
        } else {
            totalInVault += amount;
        }
    }

    function getUserTokenBalance(address userAddress, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return userVault[userAddress][tokenAddress].totalAmount;
    }
}
