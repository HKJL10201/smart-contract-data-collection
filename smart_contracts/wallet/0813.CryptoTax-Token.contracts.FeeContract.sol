// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeContract is ERC20 {
    address payable public feeWallet;
    uint256 public taxRate;
    uint256 public additionalCharge;
    uint256 public conversionRate;
    uint256 public contractBalance;

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event TokensSold(address indexed seller, uint256 tokenAmount, uint256 ethAmount);

    constructor(
        address payable _feeWallet,
        uint256 _taxRate,
        uint256 _additionalCharge,
        uint256 _conversionRate
    ) ERC20("Fee Contract", "FC") {
        require(_feeWallet != address(0), "Invalid fee wallet address");

        feeWallet = _feeWallet;
        taxRate = _taxRate;
        additionalCharge = _additionalCharge;
        conversionRate = _conversionRate;
        contractBalance = 0;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 feeAmount = (amount * (taxRate + additionalCharge)) / 100;
        uint256 transferAmount = amount - feeAmount;

        super._transfer(sender, recipient, transferAmount);
        super._transfer(sender, feeWallet, feeAmount);
    }

    function buyTokens(uint256 ethAmount) external payable {
        require(ethAmount > 0, "Invalid ETH amount");
        require(msg.value >= ethAmount, "Insufficient ETH sent");

        uint256 tokenAmount = (ethAmount * conversionRate) / (1 ether);
        require(tokenAmount > 0, "Invalid token amount");

        _mint(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, ethAmount, tokenAmount);

        uint256 feeAmount = (ethAmount * (taxRate + additionalCharge)) / 100;
        if (feeAmount > 0) {
            super._transfer(msg.sender, feeWallet, feeAmount);
        }
        contractBalance += ethAmount;
    }

    function sellTokens(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Invalid token amount");
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");

        uint256 ethAmount = (tokenAmount * (1 ether)) / conversionRate;
        require(ethAmount > 0, "Invalid ETH amount");

        _burn(msg.sender, tokenAmount);
        payable(msg.sender).transfer(ethAmount);

        emit TokensSold(msg.sender, tokenAmount, ethAmount);

        uint256 feeAmount = (tokenAmount * (taxRate + additionalCharge)) / 100;
        if (feeAmount > 0) {
            super._transfer(msg.sender, feeWallet, feeAmount);
        }
        contractBalance -= ethAmount;
    }
}
