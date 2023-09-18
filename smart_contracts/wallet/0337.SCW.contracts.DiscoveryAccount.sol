// SPDX-License-Identifier: GPL-3.0

/**
 * This code is based on the simpleAccount contract by Alex Beregszaszi (Infinitism.eth)
 * It can be found here: https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/SimpleAccount.sol
 */


pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';

import '@account-abstraction/contracts/core/BaseAccount.sol';
import './TokenCallbackHandler.sol';

/**
  * Discovery Account.
  * This is an abstract account that:
  *     - allows the owner to execute transactions through the entryPoint
  *     - allows the owner to set a whitelist of contracts and wallets with which he has the right to interact.
  *     - implement a simple multisig mecanism to retrieve the access to the account in case the owner loses his private key.
  */
contract DiscoveryAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    // receiver address => allowed?
    mapping(address => bool) public allowedReceivers; // used to send native tokens
    // contract address => allowed?
    mapping(address => bool) public allowedContracts; // used th interact with other contracts

    address public owner;
    address[] public authorizedAddress; 

     // the proposal to recover the account:
    // - any of the recovery addresses can propose a recovery
    // - the other recovery address must confirm the proposal
    address[2] public recover; // When a recovery is proposed, the array is filled with the proposed address and the proposer 


    uint256 public lastRecoveryRequest; // block number of the last recovery request. It is used to prevent multiple recovery requests in a short time and blocks the '
    uint256 public lastTxTimestamp; // last tx block, used to allow recovery only after a certain time
    uint256 public delay = 86400; // delay in seconds before recovery can be executed. 86400 seconds = 1 day
    uint256 public newRecoveryDelay = 86400; // delay in seconds before a new recovery can be executed. 86400 seconds = 1 day

    address public recoveryAddress1; // One of the signers allowed to recover the account
    address public recoveryAddress2; // One of the signers allowed to recover the account

    IEntryPoint private immutable _entryPoint;

    event DiscoveryAccountInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
    event RecoverySetup(
        address indexed recoveryAddress1,
        address indexed recoveryAddress2,
        uint256 delay
    );
    event OwnerChanged(address indexed newOwner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyRecover() {
        _onlyRecover();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev fallback function to receive native tokens
     */
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == owner || msg.sender == address(this),
            'only owner'
        );
    }

    function _onlyRecover() internal view {
        require(
            msg.sender == recoveryAddress1 || msg.sender == recoveryAddress2,
            'only recovery address'
        );
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        require(
            (allowedReceivers[dest] == true || allowedContracts[dest] == true),
            'operation not allowed'
        );
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length, 'wrong array lengths');
        for (uint256 i = 0; i < dest.length; i++) {
            require(
                allowedReceivers[dest[i]] || allowedContracts[dest[i]],
                'operation not allowed'
            );
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of DiscoveryAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        allowedContracts[
            address(0x9522F29A27CaF4b82C1f22d21eAD2E081A68A899)
        ] = true;
        allowedContracts[
            address(0xe70cDC67C91d5519DD4682cA162E40480773255a)
        ] = true; //aave on sepolia
        allowedContracts[
            address(this)
        ] = true;

        allowedReceivers[
            address(0x9522F29A27CaF4b82C1f22d21eAD2E081A68A899)
        ] = true;

        // recovery settings
        delay = 86400; // 86400 seconds = 1 day

        authorizedAddress.push(address(0x9522F29A27CaF4b82C1f22d21eAD2E081A68A899)); 
        authorizedAddress.push(address(0xe70cDC67C91d5519DD4682cA162E40480773255a)); 
        authorizedAddress.push(address(this)); 


        emit DiscoveryAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner,
            'account: not Owner or EntryPoint'
        );
    }

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    /**
     * calls a contract as this account
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlyOwner();
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
    }


    // edit whitelist

    /**
     * initialize the whitelists from arrays of addresses
     * Temporary locked if a recovery is proposed
     */
    function initializeAddress(
        address[] memory whitelistContract,
        address[] memory whitelistWallet
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        for (uint i; i < whitelistContract.length; i++) {
            allowedContracts[whitelistContract[i]] = true;
            authorizedAddress.push(whitelistContract[i]); 
        }

        for (uint j; j < whitelistWallet.length; j++) {
            allowedReceivers[whitelistWallet[j]] = true;
            authorizedAddress.push(whitelistWallet[j]); 
        }
    }

    /**
     * Set if an address is allowed to receive native tokens from this account
     * Temporary locked if a recovery is proposed
     */
    function setAllowedReceiver(
        address receiver,
        bool allowed
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        allowedReceivers[receiver] = allowed;
        if(allowed == true){
            authorizedAddress.push(receiver);
        }else{
            uint256 index = _findIndexUser(receiver);
            delete authorizedAddress[index];
            for (uint256 i = index; i < authorizedAddress.length - 1; i++) {
                authorizedAddress[i] = authorizedAddress[i + 1];
            }
            authorizedAddress.pop();
        }
    }

    /**
     * Set if a contract is allowed to be called by this account
     * Temporary locked if a recovery is proposed
     */
    function setAllowedContract(
        address contractAddress,
        bool allowed
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        allowedContracts[contractAddress] = allowed;
        if(allowed == true){
            authorizedAddress.push(contractAddress);
        }else{
            uint256 index = _findIndexUser(contractAddress);
            delete authorizedAddress[index];
            for (uint256 i = index; i < authorizedAddress.length - 1; i++) {
                authorizedAddress[i] = authorizedAddress[i + 1];
            }
            authorizedAddress.pop();
        }
    }

    /**
     *@notice find the index of an address in the  authorizedAddress array.
     *@param user The address of the user to find in the authorizedAddress array.
     *@return the index of the admin in the  authorizedAddress array.
     */
    function _findIndexUser(address user) internal view returns (uint256) {
        for (uint256 i; i < authorizedAddress.length; i++) {
            if (authorizedAddress[i] == user) {
                return i;
            }
        }
        return authorizedAddress.length;
    }


    /** 
     * Recovery mecanism
     *
     * The recovery mecanism is a simple multisig mecanism which involves 2 keys choosent by the owner.
     * 
     * The owner can setup the recovery mecanism by calling setupRecovery() with the 2 recovery addresses and the delay before the recovery can be executed.
     * 
     * When the owner loses his private key, or when it is compromised, the recovery addresses can propose a recovery by calling proposeRecovery(). This action
     * will temporary lock critical methods (like execute(), setAllowedReceiver(), setAllowedContract() or withdrawDepositTo()) to prevent the owner from loosing his funds.
     *
     * When one of the recovery addresses proposes a recovery, the other recovery address must confirm the recovery by calling approveRecovery(true). If the recovery
     * is not approved, the recovery can be cancelled by calling approveRecovery(false).
     */

    /**
     * setup the recovery mecanism. It can only be called by the owner.
     *
     * Temporary locked if a recovery is proposed
     * 
     * @param newRecoveryAddress1 - first recovery address
     * @param newRecoveryAddress2 - second recovery address
     * @param _delay - delay in seconds before the recovery can be executed     
     */
    function setupRecovery(
        address newRecoveryAddress1,
        address newRecoveryAddress2,
        uint256 _delay
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        require(newRecoveryAddress1 != address(0), 'invalid address');
        require(newRecoveryAddress2 != address(0), 'invalid address');
        require(newRecoveryAddress1 != newRecoveryAddress2, 'same address');
        recoveryAddress1 = newRecoveryAddress1;
        recoveryAddress2 = newRecoveryAddress2;
        delay = _delay;

        emit RecoverySetup(newRecoveryAddress1, newRecoveryAddress2, _delay);
    }

    /**
     * Allows a recover address to propose a recovery
     * 
     * Temporary locked if a recovery is proposed
     * 
     * @param newOwner - new owner address
     */
    function proposeRecovery(address newOwner) public onlyRecover {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        require(newOwner != address(0), 'invalid address');
        require(newOwner != recoveryAddress1, 'already recovery address');
        require(newOwner != recoveryAddress2, 'already recovery address');
        require(block.timestamp > lastTxTimestamp + delay, 'too soon');
        recover[0] = newOwner;
        recover[1] = msg.sender;
    }

    /**
     * Allows a recover address to approve a recovery
     * 
     * Temporary locked if a recovery is proposed
     * 
     * @param approve - true to approve the recovery, false to cancel it
     */
    function approveRecovery(bool approve) public onlyRecover {
        if(approve == false){
            recover[0] = address(0);
            recover[1] = address(0);
            newRecoveryDelay = 0;
            return;
        }
        require(block.number > lastTxTimestamp + delay, 'too soon');
        require(recover[0] != address(0), 'no recovery proposed');
        require(recover[1] == address(0), 'recovery already approved');
        owner = recover[0];
        recover[0] = address(0);
        recover[1] = address(0);
        emit OwnerChanged(owner);
    }

    /**
     * @notice Returns all the administrators of the contract.
     * @return An array of Admin objects.
     */
    function getAllAuthorizedAddress() public view returns (address[] memory) {
        return authorizedAddress;
    }
    
}
