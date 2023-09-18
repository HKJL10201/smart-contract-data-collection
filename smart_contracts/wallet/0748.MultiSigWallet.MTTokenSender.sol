pragma solidity >=0.4.22 <0.9.0;

import "./MTToken.sol";
import "./MultiSigWallet.sol";

contract MTTokenSender {
    MTToken public token;
    MultiSigWallet public wallet;

    constructor(address _token, address _wallet) {
        token = MTToken(_token);
        wallet = MultiSigWallet(_wallet);
    }

    function sendTokenToMultiSigWallet(uint256 _amount) public {
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        token.transferFrom(msg.sender, address(wallet), _amount);
        wallet.submitTransaction(address(token), 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount));
    }
}
