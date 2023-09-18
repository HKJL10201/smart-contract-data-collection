// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../BaseWallet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
  * minimal wallet.
  *  this is sample minimal wallet.
  *  has execute, eth handling methods
  *  has a single signer that can send requests through the entryPoint.
  */
contract OperaSmartWallet is BaseWallet, IERC1271, AccessControlEnumerableUpgradeable {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;

    //explicit sizes of nonce, to fit a single storage cell with "owner"
    uint96 private _nonce;
    address public owner;
    bytes32 public OWNER_ROLE; // solhint-disable-line var-name-mixedcase
    bytes32 public GUARDIAN_ROLE; // solhint-disable-line var-name-mixedcas

    function nonce() public view virtual override returns (uint256) {
        return _nonce;
    }

    function entryPoint() public view virtual override returns (EntryPoint) {
        return _entryPoint;
    }

    modifier onlyEntryPoint() {
        require(msg.sender == entryPoint().create2factory(), "Wallet: Not from EntryPoint");
        _;
    }

    EntryPoint private _entryPoint;

    event EntryPointChanged(address indexed oldEntryPoint, address indexed newEntryPoint);

    receive() external payable {}

    constructor(EntryPoint anEntryPoint, address anOwner, address[] memory _guardians) {
        _entryPoint = anEntryPoint;
        owner = anOwner;

        OWNER_ROLE = keccak256("OWNER_ROLE");
        GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
        _setRoleAdmin(GUARDIAN_ROLE, OWNER_ROLE);
        _grantRole(OWNER_ROLE, anOwner);
        for (uint256 i = 0; i < _guardians.length; i++) {
            _grantRole(GUARDIAN_ROLE, _guardians[i]);
        }
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the entryPoint (which gets redirected through execFromEntryPoint)
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    /**
     * transfer eth value to a destination address
     */
    function transfer(address payable dest, uint256 amount) external onlyOwner {
        dest.transfer(amount);
    }

    /**
     * execute a transaction (called directly from owner, not by entryPoint)
     */
    function exec(address dest, uint256 value, bytes calldata func) external onlyOwner {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transaction
     */
    function execBatch(address[] calldata dest, bytes[] calldata func) external onlyOwner {
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * change entry-point:
     * a wallet must have a method for replacing the entryPoint, in case the the entryPoint is
     * upgraded to a newer version.
     */
    function _updateEntryPoint(address newEntryPoint) internal override {
        emit EntryPointChanged(address(_entryPoint), newEntryPoint);
        _entryPoint = EntryPoint(payable(newEntryPoint));
    }

    function _requireFromAdmin() internal view override {
        _onlyOwner();
    }

    /**
     * validate the userOp is correct.
     * revert if it doesn't.
     * - must only be called from the entryPoint.
     * - make sure the signature is of our supported signer.
     * - validate current nonce matches request nonce, and increment it.
     * - pay prefund, in case current deposit is not enough
     */
    function _requireFromEntryPoint() internal override view {
        require(msg.sender == address(entryPoint()), "wallet: not from EntryPoint");
    }

    // called by entryPoint, only after validateUserOp succeeded.
    function execFromEntryPoint(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /// implement template method of BaseWallet
    function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
        require(_nonce++ == userOp.nonce, "wallet: invalid nonce");
    }

    /// implement template method of BaseWallet
    function _validateSignature(UserOperation calldata userOp, bytes32 requestId) internal view override {
        bytes32 hash = requestId.toEthSignedMessageHash();
        require(owner == hash.recover(userOp.signature), "wallet: wrong signature");
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current wallet deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this wallet in the entryPoint
     */
    function addDeposit() public payable {

        (bool req,) = address(entryPoint()).call{value : msg.value}("");
        require(req);
    }

    /**
     * withdraw value from the wallet's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function getOwnerCount() external view returns (uint256) {
        return getRoleMemberCount(OWNER_ROLE);
    }

    function getOwner(uint256 index) external view returns (address) {
        return getRoleMember(OWNER_ROLE, index);
    }

    function getGuardianCount() external view returns (uint256) {
        return getRoleMemberCount(GUARDIAN_ROLE);
    }

    function getGuardian(uint256 index) external view returns (address) {
        return getRoleMember(GUARDIAN_ROLE, index);
    }

    function grantGuardian(address guardian) external onlyOwner() {
        require(!hasRole(OWNER_ROLE, guardian), "Wallet: Owner cannot be guardian");
        _grantRole(GUARDIAN_ROLE, guardian);
    }

    function revokeGuardian(address guardian) external onlyOwner() {
        _revokeRole(GUARDIAN_ROLE, guardian);
    }

    function transferOwner(address newOwner) external onlyOwner() {
        _revokeRole(OWNER_ROLE, getRoleMember(OWNER_ROLE, 0));
        _grantRole(OWNER_ROLE, newOwner);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4)    {
        require(
            hasRole(OWNER_ROLE, hash.recover(signature)),
            "Wallet: Invalid signature"
        );
        return IERC1271.isValidSignature.selector;
    }
}
