// SPDX-License-Identifier: MIT only

pragma solidity ^0.8.0;

import "./interfaces/IService.sol";
import "../IWallet.sol";

contract BaseService {

    event ServiceCreated(bytes32 name);

    modifier onlyWhenLocked(address _wallet) {
        require(_isLocked(_wallet), "BM: wallet must be locked");
        _;
    }

    modifier onlyWhenUnlocked(address _wallet) {
        require(!_isLocked(_wallet), "BM: wallet locked");
        _;
    }

    modifier onlySelf() {
        require(_isSelf(msg.sender), "Must be service");
        _;
    }

    modifier onlyWalletOwnerOrSelf(address _wallet) {
        require(_isSelf(msg.sender) || _isOwner(_wallet, msg.sender), "Must be wallet owner/self");
        _;
    }

    modifier onlyWallet(address _wallet) {
        require(msg.sender == _wallet, "Caller must be wallet");
        _;
    }

    constructor(
        bytes32 _name
    ) {
        emit ServiceCreated(_name);
    }
    
    function _isOwner(address _wallet, address _addr) internal view returns (bool) {
        return IWallet(_wallet).owner() == _addr;
    }

    function _isLocked(address _wallet) internal view returns (bool) {
        return IWallet(_wallet).locked();
    }

    function _isSelf(address _addr) internal view returns (bool) {
        return _addr == address(this);
    }

    /**
     * @notice Helper method to invoke a wallet.
     * @param _wallet The target wallet.
     * @param _to The target address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory _res) {
        bool success;
        (success, _res) = _wallet.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _value, _data));
        if (success && _res.length > 0) { 
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        } else if (!success) {
            revert("Wallet invoke reverted");
        }
    }
}