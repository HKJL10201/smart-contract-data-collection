//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../vault/Vault.sol";
import "../controllers/CompoundController.sol";

contract UserWallet is ReentrancyGuard, Vault, CompoundController {
    /*
        send tokens that will be stored in their vault (recieve)
        withdraw tokens from vault (send)
        view total_vault balance
     */

    Vault private vault;
    CompoundController private compoundController;

    constructor(address _vaultAddress, address _compoundControllerAddress) {
        vault = Vault(_vaultAddress);
        compoundController = CompoundController(_compoundControllerAddress);
    }

    // token_address, TIMESTAMP, SENDER_ADDRESS
    event DepositInWallet(
        address token,
        address indexed sender,
        uint256 timestamp,
        uint256 amount
    );
    event WithdrawFromWallet(
        address token,
        address indexed recipient,
        uint256 timestamp,
        uint256 amount
    );
    event InvestedInCompound(
        address token,
        address indexed caller,
        uint256 timestamp,
        uint256 amount
    );
    event WithdrawFromCompound(
        address token,
        address indexed caller,
        uint256 timestamp,
        uint256 amount
    );

    /* 
        address_of_token, amount
    */
    function deposit(
        address tokenAddress,
        uint256 amount
    ) public nonReentrant returns (bool success) {
        UserVaultTokenDetail memory userVault = vault._getUserVault(
            msg.sender,
            tokenAddress
        );
        IERC20 paymentToken = IERC20(tokenAddress);
        require(amount > 0, "Wallet: amount cannot be 0!");
        require(
            paymentToken.transferFrom(msg.sender, address(this), amount),
            "Wallet: Deposit failed!"
        );
        require(
            paymentToken.transfer(address(vault), amount),
            "Wallet: transfer to vault failed!"
        );
        uint256 userNewBalance = userVault.totalAmount + amount;
        vault._setUserVault(msg.sender, tokenAddress, userNewBalance);

        emit DepositInWallet(tokenAddress, msg.sender, block.timestamp, amount);

        return true;
    }

    function withdrawFromVault(
        address recipient,
        address tokenAddress,
        uint256 amount
    ) public nonReentrant returns (bool success) {
        UserVaultTokenDetail memory userVault = vault._getUserVault(
            msg.sender,
            tokenAddress
        );
        require(userVault.isExists, "Wallet: Only account owner can withdraw!");
        require(
            amount > 0,
            "Wallet: withdrawal amount must be greater than zero!"
        );
        require(
            amount <= userVault.totalAmount,
            "Wallet: Insufficient token funds for user!"
        );
        IERC20 withdrawalToken = IERC20(tokenAddress);
        require(
            withdrawalToken.transferFrom(address(vault), recipient, amount),
            "Wallet: transfer to vault failed!"
        );
        uint256 userRemainingBalance = userVault.totalAmount - amount;
        vault._setUserVault(msg.sender, tokenAddress, userRemainingBalance);

        emit WithdrawFromWallet(
            tokenAddress,
            recipient,
            block.timestamp,
            amount
        );

        return true;
    }

    function investInCompound(
        address _erc20,
        address _cErc20,
        uint256 tokenAmount
    ) public nonReentrant returns (bool) {
        IERC20 paymentToken = IERC20(_erc20);
        UserVaultTokenDetail memory userVault = vault._getUserVault(
            msg.sender,
            _erc20
        );
        require(
            userVault.isExists && userVault.totalAmount != 0,
            "Wallet: fund your wallet to continue!"
        );
        require(
            tokenAmount > 0,
            "Wallet: Invest amount must be greater than zero!"
        );
        require(
            tokenAmount <= userVault.totalAmount,
            "Wallet: Insufficient token funds for user!"
        );

        // Transfer token from vault to the compoundController
        paymentToken.transferFrom(
            address(vault),
            address(compoundController),
            tokenAmount
        );
        require(
            compoundController.supplyErc20ToCompound(
                _erc20,
                _cErc20,
                msg.sender,
                tokenAmount
            ),
            "Wallet: investment in compound failed!"
        );
        // Update user vault(wallet) balance
        uint256 userRemainingBalance = userVault.totalAmount - tokenAmount;
        vault._setUserVault(msg.sender, _erc20, userRemainingBalance);

        emit InvestedInCompound(
            _erc20,
            msg.sender,
            block.timestamp,
            tokenAmount
        );
        return true;
    }

    function withdrawFromCompound(
        address _erc20,
        address _cErc20,
        uint256 tokenAmount,
        uint256 investmentId
    ) public nonReentrant returns (bool) {
        // make sure withdrawAmount isnt > userInvestmentBalance
        UserInvestedTokenDetails memory userInvestment = compoundController
            ._getUserInvestment(msg.sender, investmentId);
        require(
            userInvestment.isExists && userInvestment.tokenAmount != 0,
            "Withdraw: invest in compound to continue!"
        );
        require(
            tokenAmount > 0,
            "Withdraw: Withdrawal amount must be greater than zero!"
        );
        // require(
        //     tokenAmount <= userInvestment.tokenAmount,
        //     "Withdraw: Insufficient token funds for user!"
        // );
        require(
            compoundController.redeemCErc20Tokens(
                tokenAmount,
                false,
                _cErc20,
                _erc20,
                msg.sender,
                investmentId
            ),
            "Withdraw: Withdrawal from compound failed!"
        );
        Erc20 underlying = Erc20(_erc20);
        underlying.transferFrom(
            address(compoundController),
            address(vault),
            tokenAmount
        );

        UserVaultTokenDetail memory userVault = vault._getUserVault(
            msg.sender,
            _erc20
        );
        // Update user vault(wallet) balance
        uint256 userNewVaultBalance = userVault.totalAmount + tokenAmount;
        vault._setUserVault(msg.sender, _erc20, userNewVaultBalance);

        emit WithdrawFromCompound(
            _erc20,
            msg.sender,
            block.timestamp,
            tokenAmount
        );

        return true;
    }
}
