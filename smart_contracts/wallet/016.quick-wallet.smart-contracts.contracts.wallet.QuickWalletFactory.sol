pragma solidity ^0.5.0;

import "../utils/Create2.sol";
import "./QuickWallet.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract QuickWalletFactory {

    using BytesLib for bytes;

    bytes public baseContractCode;

    /**
     * @dev Constructor
     * @param _baseContractCode The base bytecode used for the wallet
     */
    constructor(bytes memory _baseContractCode) public {
        baseContractCode = _baseContractCode;
    }

    /**
     * @dev Deploy a QuickWallet contract, execute a call and pay a fee
     * @param walletOwner The owner of the wallet to deploy
     * @param txData encoded data that contains:
       * receiver The address of the contract to call
       * data ABI-encoded contract call to call `_to` address
       * value Amount of ETH in wei to be sent in the call
       * feeToken The token used for the fee, use this wallet address for ETH
       * feeValue The amount to be payed as fee
       * beforeTime timetstamp of the time where this tx cant be executed
       * once it passed
     * @param txSignature The signature of the tx and fee payment
     * @param feeReceiver The receiver of the fee payment
     */
    function deployQuickWallet(
        address walletOwner, bytes memory txData, bytes memory txSignature, address feeReceiver
    ) public {
        require(walletOwner != address(0), "QuickWalletFactory: Invalid wallet owner");
        QuickWallet wallet = QuickWallet(_deploy(keccak256(abi.encodePacked(walletOwner)), abi.encode(walletOwner)));
        wallet.call(txData, txSignature, feeReceiver);
    }

    /**
     * @dev Deploy a Wallet contract
     * @param _salt The hex salt used for the wallet creation
     * @param _constructorData The ABI encoded data parameters for the costructor
     */
    function _deploy(
        bytes32 _salt, bytes memory _constructorData
    ) internal returns (address) {
        bytes memory _code = baseContractCode.concat(_constructorData);
        return Create2.deploy(_salt, _code);
    }

}
