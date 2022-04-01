pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

contract QuickWallet {

    using ECDSA for bytes32;

    // Used to prevent execution of already executed txs
    uint256 public txCount;

    // QuickWallet owner address
    address public _owner;

    /**
     * @dev Constructor
     * @param owner The address of the wallet owner
     */
    constructor(address owner) public {
        _owner = owner;
    }

    /**
     * @dev Call a external contract and pay a fee for the call
     * @param txData encoded data that contains:
       * receiver The address of the contract to call
       * data ABI-encoded contract call to call `_to` address
       * value Amount of ETH in wei to be sent in the call
       * feeToken The token used for the fee, use this wallet address for ETH
       * feeValue The amount to be payed as fee
       * beforeTime timetstamp of the time where this tx cant be executed
       * once it passed
     * @param txSignature The signature of the wallet owner
     * @param feeReceiver The receiver of the fee payment
     */
    function call(bytes memory txData, bytes memory txSignature, address feeReceiver) public payable {
        (address receiver, bytes memory data,
            uint256 value, address feeToken,
            uint256 feeValue, uint256 beforeTime
        ) = abi.decode(txData, (address, bytes, uint256, address, uint256, uint256));
        require(beforeTime > block.timestamp, "QuickWallet: Invalid beforeTime value");
        require(feeToken != address(0), "QuickWallet: Invalid fee token");

        address _signer = keccak256(abi.encodePacked(
            address(this), txData, txCount
        )).toEthSignedMessageHash().recover(txSignature);
        require(owner() == _signer, "QuickWallet: Signer is not wallet owner");

        txCount++;

        _call(receiver, data, value);

        if (feeValue > 0) {
            bytes memory feePaymentData = abi.encodeWithSelector(
                bytes4(keccak256("transfer(address,uint256)")), feeReceiver, feeValue
            );
            _call(feeToken, feePaymentData, 0);
        }
    }

    /**
     * @dev ERC20 transfer of ETH, can only be called from this contract
     * @param receiver The address to transfer the eth
     * @param value The amount of eth in wei to be transfered
     */
    function transfer(address payable receiver, uint256 value) public {
        require(msg.sender == address(this), "QuickWallet: Transfer cant be called outside contract");
        receiver.transfer(value);
    }

    /**
     * @dev Get QuickWallet owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Call a external contract
     * @param _to The address of the contract to call
     * @param _data ABI-encoded contract call to call `_to` address.
     * @param _value The amount of ETH in wei to be sent in the call
     */
    function _call(address _to, bytes memory _data, uint256 _value) internal {
        // solhint-disable-next-line avoid-call-value
        (bool success, bytes memory data) = _to.call.value(_value)(_data);
        require(success, "QuickWallet: Call to external contract failed");
    }

}
