pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MyToken.sol";
import "./MultiSigWallet.sol";

contract MyTokenSender {
    MyToken private _token;
    MultiSigWallet private _multiSigWallet;

    constructor(address tokenAddress, address walletAddress) {
        _token = MyToken(tokenAddress);
        _multiSigWallet = MultiSigWallet(walletAddress);
    }

    function sendTokenToMultiSigWallet(uint256 amount) public {
        _token.sendToMultiSigWallet(address(_multiSigWallet), amount);
    }

    function getMyTokenBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}
