// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * A timelock contract for calling functions of the GuardianManager
 * @notice
 */
contract GuardianExecutor is Initializable, UUPSUpgradeable {
    address public account;
    uint256 private delay;
    uint256 private expirePeriod;

    mapping(bytes32 => bool) public transactionQueue;

    event TransactionQueued(
        bytes32 txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    event TransactionExecuted(
        bytes32 txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    event TransactionCancelled(
        bytes32 txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    modifier onlyOwner() {
        require(msg.sender == account, "only owner");
        _;
    }

    /**
     * Initialize parameter of GuardianExecutor contract
     * @param _account the account address that this Guardian is protected
     * @param _delay the time delay require for a transaction request to mature
     * @param _expirePeriod the time period after eta that user could execute the transaction through GuardianExecutor
     */
    function initialize(
        address _account,
        uint256 _delay,
        uint256 _expirePeriod
    ) public initializer {
        account = _account;
        delay = _delay;
        expirePeriod = _expirePeriod;
    }

    function getDelay() public view returns (uint256) {
        return delay;
    }

    /**
     * Queue the transaction that owner wish to execute
     * @param _target the target contract that's going to be call
     * @param _value the value of the call
     * @param _signature the function signature
     * @param _data calldata of the call
     * @param _eta estimated time of arrival of this transaction
     */
    function queue(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _data,
        uint256 _eta
    ) external onlyOwner returns (bytes32) {
        require(
            _eta >= block.timestamp + delay,
            "Timelock:: queue: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );

        transactionQueue[txHash] = true;
        emit TransactionQueued(
            txHash,
            _target,
            _value,
            _signature,
            _data,
            _eta
        );
        return txHash;
    }

    /**
     * Execution call of the queued transaction
     * @param _target the target contract that going to be call
     * @param _value the value of the call
     * @param _signature the function signature
     * @param _data calldata of the call
     * @param _eta estimated time of arrival of this transaction
     */
    function execute(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _data,
        uint256 _eta
    ) external payable onlyOwner {
        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );

        require(
            transactionQueue[txHash],
            "Timelock:: execute: Transaction hasn't been queued."
        );

        require(
            block.timestamp >= _eta,
            "Timelock:: execute: Transaction hasn't surpassed time lock."
        );

        require(
            block.timestamp <= (_eta + expirePeriod),
            "Timelock:: execute: Transaction is expired."
        );

        transactionQueue[txHash] = false;

        bytes memory callData;

        if (bytes(_signature).length == 0) {
            callData = _data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(_signature))),
                _data
            );
        }

        (bool success, ) = _target.call{value: _value}(callData);

        require(success, "Timelock:: execute: Transaction execution reverted.");
        emit TransactionExecuted(
            txHash,
            _target,
            _value,
            _signature,
            _data,
            _eta
        );
    }

    /**
     * Cancel the queued transaction
     * @param _target the target contract that going to be call
     * @param _value the value of the call
     * @param _signature the function signature
     * @param _data calldata of the call
     * @param _eta estimated time of arrival of this transaction
     */
    function cancel(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _data,
        uint256 _eta
    ) external onlyOwner {
        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );
        transactionQueue[txHash] = false;
        emit TransactionCancelled(
            txHash,
            _target,
            _value,
            _signature,
            _data,
            _eta
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {
        (newImplementation);
    }
}
