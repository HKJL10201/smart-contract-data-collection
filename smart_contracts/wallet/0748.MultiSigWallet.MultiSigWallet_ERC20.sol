pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MultiSigWallet.sol";

contract MyToken is ERC20 {
    address private _owner;
    MultiSigWallet private _multiSigWallet;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, address walletAddress) ERC20(name, symbol) {
        _owner = owner;
        _multiSigWallet = MultiSigWallet(walletAddress);
        _mint(owner, initialSupply);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(_multiSigWallet), "Transfer to the multisig wallet is not allowed");
        super.transfer(recipient, amount);
        return true;
    }

    function sendToMultiSigWallet(address wallet, uint256 amount) public returns (bool) {
        require(msg.sender == _owner, "Only the owner of the token can send tokens to the multisig wallet");
        super.transfer(wallet, amount);
        _multiSigWallet.confirmTransaction(address(this), wallet, amount);
        return true;
    }

    function getMultiSigWalletAddress() public view returns (address) {
        return address(_multiSigWallet);
    }
}
