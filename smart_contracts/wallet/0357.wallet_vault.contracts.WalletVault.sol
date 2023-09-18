// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 @title WalletVault
 @author Mordi Goldstein
 @notice A smart contract wallet which allows the user to create vaults which increase security in the following ways:
    - User can set a max value that can be deposited into each vault
    - User can set max withdrawal and a max withdrawal frequency for each vault
    - User can lock a vault and set an unlock delay
 */

contract WalletVault {
    event CreateVault(uint256 indexed id, Vault);
    event VaultWithdrawal(
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );
    event VaultDeposit(uint256 indexed id, uint256 amount, uint256 timestamp);
    event WalletWithdrawal(
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event WalletDeposit(
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );
    event Lock(uint256 timestamp);
    event Unlock(uint256 timestamp);

    using Counters for Counters.Counter;

    Counters.Counter private _counter;

    address public owner;

    /// @dev The balance of this contract that is NOT in a vault
    uint256 public availableBalance;

    /**
    @dev
    * {Vault} struct:
        - maxValue: the maximum value that can be held in this vault
        - currentValue: the current value that is being held in this vault. Default to zero on vault creation
        - locked: whether or not this vault is locked
        - unlockInitiated: whether or not an unlock has been initiated on this vault. Default to false on vault creation
        - unlockedTime: the timestamp when the unlock was initiated. Default to zero on vault creation
        - unlockDelay: the amount of time (in seconds) for the unlock delay
        - maxWithdrawal: the maximum value that can withdraw at any one time
        - maxWithdrawalFrequency: The time (in seconds) that must be in between each withdrawal
        - lastWithdrawalTime: the timestamp of the last withdrawal. Default to zero on vault creation
     */

    struct Vault {
        uint256 maxValue;
        uint256 currentValue;
        bool locked;
        bool unlockInitiated;
        uint256 unlockedTime;
        uint256 unlockDelay;
        uint256 maxWithdrawal;
        uint256 maxWithdrawalFrequency;
        uint256 lastWithdrawal;
    }

    /**
     @dev mapping of vault IDs to vault
     @dev IDs are implemented using Open Zepplin's counter
    */
    mapping(uint256 => Vault) public idToVault;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
    @dev :
        - Add the received amount to the available balance of the contract
        - Emit the {WalletDeposit} event
     */
    receive() external payable {
        availableBalance += msg.value;
        emit WalletDeposit(msg.sender, msg.value, block.timestamp);
    }

    /**
        * @notice Create a new vault
        * @dev For params, see the {Vault} struct params
        * emits the {CreateVault} event
        * Requirements:
            - Only the owner can create a vault
    */
    function createVault(
        uint256 _maxValue,
        bool _locked,
        uint256 _unlockDelay,
        uint256 _maxWithdrawal,
        uint256 _maxWithdrawalFrequency
    ) external onlyOwner {
        _counter.increment();

        Vault memory newVault = Vault(
            _maxValue,
            0,
            _locked,
            false,
            0,
            _unlockDelay,
            _maxWithdrawal,
            _maxWithdrawalFrequency,
            0
        );

        idToVault[_counter.current()] = newVault;

        emit CreateVault(_counter.current(), newVault);
    }

    /**
        * @notice Withdraw funds from a vault
        * @param _vaultId ID of the vault from which to withdraw
        * @param _amount Amount to withdraw
        * emits the {VaultWithdrawal} event
        * Requirements:
            - Only the owner can withdraw
            - Valid vault ID
            - Vault unlocked
            - Withdrawal amount less than or equal to the current value of the vault
            - Withdrawal amount less than or equal to the vault's max withdrawal limt
            - The max withdrawal frequency time period must have passed
    */
    function withdrawFromVault(uint256 _vaultId, uint256 _amount)
        external
        onlyOwner
    {
        require(_vaultId <= _counter.current(), "invalid id");

        Vault storage currentVault = idToVault[_vaultId];

        if (
            currentVault.unlockInitiated &&
            currentVault.unlockedTime + currentVault.unlockDelay <
            block.timestamp
        ) {
            currentVault.unlockInitiated = false;
            currentVault.locked = false;
        }

        require(!currentVault.locked, "Locked");
        require(currentVault.currentValue >= _amount, "insufficient funds");
        require(
            currentVault.maxWithdrawal >= _amount,
            "withdrawal amount too large"
        );
        require(
            block.timestamp - currentVault.lastWithdrawal >=
                currentVault.maxWithdrawalFrequency,
            "not allowed to withdraw yet"
        );

        currentVault.lastWithdrawal = block.timestamp;

        currentVault.currentValue -= _amount;
        availableBalance += _amount;

        emit VaultWithdrawal(_vaultId, _amount, block.timestamp);
    }

    /**
        * @notice Deposit funds into a vault
        * @param _vaultId ID of the vault into which to deposit
        * @param _amount Amount to deposit
        * emits the {VaultDeposit} event
        * Requirements:
            - Only the owner can withdraw
            - Valid vault ID
            - The {availableBalance} of the wallet must be bigger than or equal to the deposit amount
            - Value in vault after the deposit must not exceed the max value of the vault
    */
    function depositIntoVault(uint256 _vaultId, uint256 _amount)
        external
        onlyOwner
    {
        require(_amount <= availableBalance, "insufficient balance");
        require(_vaultId <= _counter.current(), "invalid id");

        Vault storage currentVault = idToVault[_vaultId];

        require(
            currentVault.maxValue >= (currentVault.currentValue += _amount),
            "too much in one vault"
        );

        availableBalance -= _amount;
        currentVault.currentValue += _amount;

        emit VaultDeposit(_vaultId, _amount, block.timestamp);
    }

    /**
        * @notice Lock a vault
        * @param _vaultId ID of the vault to lock
        * emits the {Lock} event
        * Requirements:
            - Only the owner can lock a vault
            - Valid vault ID
   */
    function lockVault(uint256 _vaultId) external onlyOwner {
        require(_vaultId <= _counter.current(), "invalid id");

        Vault storage currentVault = idToVault[_vaultId];

        currentVault.locked = true;
        currentVault.unlockInitiated = false;

        emit Lock(block.timestamp);
    }

    /**
        * @notice Unlock a vault
        * Once unlock is initiated, the vault will be accessible and considered "unlocked" after the {unlockDelay} time period
        * @param _vaultId ID of the vault to unlock
        * emits the {Unlock} event
        * Requirements:
            - Only the owner can unlock a vault
            - Valid vault ID
   */
    function unlockVault(uint256 _vaultId) external onlyOwner {
        require(_vaultId <= _counter.current(), "invalid id");

        Vault storage currentVault = idToVault[_vaultId];

        currentVault.unlockInitiated = true;
        currentVault.unlockedTime = block.timestamp;

        emit Unlock(block.timestamp);
    }

     /**
        * @notice Send blockchain-native token to another address
        * @param _to Address of the recipient
        * @param _amount The Amount to send
        * emits the {WalletWithdrawal} event
        * Requirements:
            - Only the owner can lock a vault
            - The amount sent must be less than the available balance of the wallet
            - Address must not be Zero address
            - The sending transaction must succeed
   */
    function sendNativeToken(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= availableBalance, "not enough funds");
        require(_to != address(0), "invalid address");

        availableBalance -= _amount;
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "transaction failed");

        emit WalletWithdrawal(_to, _amount, block.timestamp);
    }
}
