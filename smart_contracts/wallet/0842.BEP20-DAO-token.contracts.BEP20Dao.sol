// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BEP20DAOToken is ERC20, ERC20Votes, ERC20Pausable, Ownable {

    mapping(address => uint8) public _transferToFee;
    mapping(address => uint256) public _transferFromFee;
    address public _tokenFeeAddress;

    constructor(string memory tokenName, string memory tokenSymbol, uint supply) 
    ERC20(tokenName, tokenSymbol) 
    ERC20Permit(tokenSymbol) {
        _tokenFeeAddress = msg.sender;
        _mint(msg.sender, supply*10**18);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner override (Ownable) {
        super._transferOwnership(newOwner);
    }

    /** 
     * @dev See {ERC20-_beforeTokenTransfer}. See {ERC20Pausable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
    * @dev Update the address where the fee tokens are sent.
    */
    function updateTokenFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), 'The wallet address cannot be 0x0');
        _tokenFeeAddress = newFeeAddress;
    }

    /**
    * @dev Update the fee applied when the funds are transfered to the desired wallet.
    */
    function updateToWalletFee(address toWallet, uint8 fee) external onlyOwner {
        require(toWallet != address(0), 'The wallet address cannot be 0x0');
        _transferToFee[toWallet] = fee;
    }

    /**
    * @dev Update the fee applied when the funds are transfered from the desired wallet.
    */
    function updateFromWalletFee(address fromWallet, uint8 fee) external onlyOwner {
        require(fromWallet != address(0), 'The wallet address cannot be 0x0');
        _transferFromFee[fromWallet] = fee;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override (ERC20) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(recipient != sender, "BEP20: Transfering to yourself!");
        require(balanceOf(sender) >= amount, "BEP20: sent amount exceeds balance!");

        _beforeTokenTransfer(sender, recipient, amount);

        //Sell Fee
        if(_transferFromFee[sender] > 0) {
            uint256 fee = (amount / 100) * _transferFromFee[sender];
            super._transfer(sender, recipient, (amount - fee));
            super._transfer(sender, _tokenFeeAddress, fee);
        } //Buy Fee
        else if (_transferToFee[recipient] > 0){
            uint256 fee = (amount / 100) * _transferToFee[recipient];
            super._transfer(sender, recipient, (amount - fee));
            super._transfer(sender, _tokenFeeAddress, fee);
        }
        else{
            super._transfer(sender, recipient, amount);
        }
        
        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
    * @dev Pause token transactions.
    */
    function pauseTransactions() external onlyOwner {
        _pause();
    }

    /**
    * @dev Unpause token transactions.
    */
    function unpauseTransactions() external onlyOwner {
        _unpause();
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}