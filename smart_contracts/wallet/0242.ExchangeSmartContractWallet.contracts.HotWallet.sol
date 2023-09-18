// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './Manageable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol';

contract HotWallet is Manageable {
    using SafeMath for uint256;
    using Address for address;

    address private _coldWallet;
    address private _masterAccount;
    uint private _hotRate;

    event ColdWalletChanged(address coldWalletAddress);

    function initialize(address owner, address master) public initializer {
        __Manageable_init();
        _coldWallet = owner;
        _masterAccount = master;
        _hotRate = 25;
    }

    function setMasterAccount(address account) public onlyOwner {
        _masterAccount = account;
    }

    function getMasterAccount() public returns(address) {
        return _masterAccount;
    }

    function changeHotRate(uint hotRate) public onlyOwner {
        require(hotRate < 100 && hotRate > 0);
        _hotRate = hotRate;
    }

    function sendTokens(address[] memory tokenAddress, address[] memory target, uint256[] memory amount, uint nonce, bytes memory signature) public payable onlyManager {
        require(verify(nonce, signature));
        require(tokenAddress.length == target.length && target.length == amount.length);
        for(uint i=0 ; i<tokenAddress.length ; i++) {
            if(tokenAddress[i] == address(0)) {
                payable(target[i]).transfer(amount[i]);
            } else {
                SafeERC20.safeTransfer(IERC20(tokenAddress[i]), target[i], amount[i]);
            }
        }
    }

    function rebalancingMany(address[] memory tokens) public onlyManager {
        for(uint i=0 ; i<tokens.length ; i++) {
            rebalancing(tokens[i]);
        }
    }

    function rebalancing(address tokenAddress) public onlyManager {
        uint256 coldBalance;
        uint256 hotBalance;
        uint256 targetValue;

        if(tokenAddress == address(0)) {
            coldBalance = _coldWallet.balance;
            hotBalance = address(this).balance;

            targetValue = percent(SafeMath.add(hotBalance,coldBalance), _hotRate);
            if(hotBalance > targetValue) {
                payable(_coldWallet).transfer(SafeMath.sub(hotBalance,targetValue));
            }
        } else {
            coldBalance = IERC20(tokenAddress).balanceOf(_coldWallet);
            hotBalance = IERC20(tokenAddress).balanceOf(address(this));

            targetValue = percent(SafeMath.add(hotBalance,coldBalance), _hotRate);
            if(hotBalance > targetValue) {
                SafeERC20.safeTransfer(IERC20(tokenAddress), _coldWallet, SafeMath.sub(hotBalance, targetValue));
            }
        }
    }

    function setColdWallet(address coldWalletAddress) public onlyOwner {
        _coldWallet = coldWalletAddress;
        emit ColdWalletChanged(coldWalletAddress);
    }

    function getColdWallet() public view returns(address) {
        return _coldWallet;
    }

    function percent(uint256 _value, uint256 _percent) internal pure returns (uint256)  {
        uint256 percentage = SafeMath.mul(_percent, 100);
        uint256 roundValue = ceil(_value, percentage);
        uint256 retPercent = SafeMath.div(SafeMath.mul(roundValue, percentage), 10000);
        return retPercent;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = SafeMath.add(a,m);
        uint256 d = SafeMath.sub(c,1);
        return SafeMath.mul(SafeMath.div(d,m),m);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function getMessageHash(uint _nonce) public returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, _nonce));
    }

    function verify(uint _nonce, bytes memory signature) public returns (bool) {
        bytes32 messageHash = getMessageHash(_nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _masterAccount;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    fallback() external payable {}
}