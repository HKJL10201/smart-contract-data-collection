// SPDX-License-Identifier: MIT

pragma solidity^0.8.17;

import "./AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title Recovery of ownership implementation
 * @author Lenar Saitov
*/
contract OwnershipRecovery is Ownable, AccessControl{
    bytes32 private constant TRUSTED_ACCOUNT_ROLE = keccak256("TRUSTED_ACCOUNT_ROLE");
    uint256 private constant TIME_LOCK_PERIOD = 1 days;
    address[] private trustedAccounts;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Stuct of recovery (transfer) of ownership.
    struct Recovery{
        bool isActual;
        address candidate;
        uint256 timelockEnd;
        uint256 countApprovals;
        mapping(address => bool) approveUnique;
    }

    Recovery private recovery;

    /**
     * Invalid timestamp to approve recovery of ownership. Needed more than recovery.timestamp
     * @param _current current timestamp of block.
     * @param _minRequired min required of timestamp.
     * @param _errorMessage error message.
     */
    error InvalidTimestamp (uint256 _current, uint256 _minRequired, string _errorMessage);

    modifier notToOwner(address _accountAddress){
        require(this.owner() != _accountAddress, "Address cant be equal to address of owner (account with admin role)");
        _;
    }

    /**
     * @return count of trusted accounts.
     */
    function getCountTrustedAccounts() external view returns (uint256){
        return trustedAccounts.length;
    }

    /**
     * Only for trusted account.
     * @return does trusted account approved or not
     * @param _accountAddress address of trusted account
     */
    function isApprovedRecovery(address _accountAddress) external onlyRole(TRUSTED_ACCOUNT_ROLE) view returns (bool){
        return recovery.approveUnique[_accountAddress];
    }

    /**
     * Only for trusted account.
     * @return recovery initialized or not
     */
    function isRecoveryInitialized() external onlyRole(TRUSTED_ACCOUNT_ROLE) view returns (bool){
        return recovery.isActual;
    }

    function _resetApprovals() private{
        recovery.timelockEnd = 0;
        recovery.countApprovals = 0;

        for (uint256 i = 0; i < trustedAccounts.length; ++i) {
            recovery.approveUnique[trustedAccounts[i]] = false;
        }
    }

    /**
     * Execute init of recovery of ownership of the wallet (transfer of ownership), only for trusted account.
     * @param _candidate the address of new assumed account (new assumed owner wallets)
     */
    function initRecovery(address _candidate) external onlyRole(TRUSTED_ACCOUNT_ROLE) notToOwner(_candidate){
        _resetApprovals();

        recovery.isActual = true;
        recovery.candidate = _candidate;
    }

    /**
     * Execute reset the recovery of ownership of the wallet (only for trusted account).
     */
    function resetAnyRecovery() external onlyRole(TRUSTED_ACCOUNT_ROLE) {
        _resetApprovals();

        recovery.isActual = false;
        recovery.candidate = address(0);
    }

    /**
     * Add agreement to transfer of ownership (only for trusted account). Also transfer ownership if all trusted accounts taken agree and finalize recovery proccess.
     * @param _candidate the address of new assumed account (new assumed owner wallets)
     */
    function approveRecovery(address _candidate) external onlyRole(TRUSTED_ACCOUNT_ROLE) notToOwner(_candidate){
        require(recovery.isActual, "Recovery was not inited");
        require(!recovery.approveUnique[msg.sender], "You have already agreed");
        require(_candidate == recovery.candidate, "There is not actual candidate for recover, you can reset recovery and init new");

        if (block.timestamp < recovery.timelockEnd){
            revert InvalidTimestamp({
                _errorMessage: "Approve recovery is timelocked, try later",
                _current: block.timestamp,
                _minRequired: recovery.timelockEnd
            });
        }

        recovery.countApprovals++;
        recovery.approveUnique[msg.sender] = true;

        if (recovery.countApprovals == trustedAccounts.length){
            _revokeRole(DEFAULT_ADMIN_ROLE, this.owner());
            _setupRole(DEFAULT_ADMIN_ROLE, _candidate);
            _transferOwnership(_candidate);

            recovery.isActual = false;
        } else if (recovery.countApprovals + 1 == trustedAccounts.length){
            recovery.timelockEnd = block.timestamp + TIME_LOCK_PERIOD;
        }
    }

    /**
     * Grant trusted role (permission only for admin).
     * @param _accountAddress the address of account
     */
    function grantTrustedRole(address _accountAddress) external onlyRole(DEFAULT_ADMIN_ROLE) notToOwner(_accountAddress){
        for (uint256 i = 0; i < trustedAccounts.length; ++i) {
            require(_accountAddress != trustedAccounts[i], "This account address is already trusted account role");
        }

        _grantRole(TRUSTED_ACCOUNT_ROLE, _accountAddress);

        trustedAccounts.push(_accountAddress);
    }

    /**
     * Revoke trusted role (permission only for admin)
     * @param _accountAddress the address of account
     */
    function revokeTrustedRole(address _accountAddress) external onlyRole(DEFAULT_ADMIN_ROLE) notToOwner(_accountAddress){
        _revokeRole(TRUSTED_ACCOUNT_ROLE, _accountAddress);

        for (uint256 i = 0; i < trustedAccounts.length; ++i) {
            if (_accountAddress == trustedAccounts[i]){
                recovery.approveUnique[_accountAddress] = false;
                trustedAccounts[i] = trustedAccounts[trustedAccounts.length-1];
                trustedAccounts.pop();

                break;
            }
        }
    }

    /**
     * @param _accountAddress the address of account
     * @return Returns `true` if `account` has been granted `trusted role`.
     */
    function hasTrustedRole(address _accountAddress) external view returns (bool){
        return hasRole(TRUSTED_ACCOUNT_ROLE, _accountAddress);
    }

    /**
     * @param _accountAddress the address of account
     * @return Returns `true` if `account` has been granted `admin role`.
     */
    function hasAdminRole(address _accountAddress) external view returns (bool){
        return hasRole(DEFAULT_ADMIN_ROLE, _accountAddress);
    }
}

/**
 * @title Basic smart contract-based wallet implementation
 * @author Lenar Saitov
*/
contract CAWallet is OwnershipRecovery{
    IERC20 public token;

    constructor (IERC20 _token) {
        token = _token;
    }


    // Modifier for validate sended amount tokens with count of all tokens.
    modifier enoughTokens(uint256 _amount){
        require(_amount > 0, "Need to send at least some tokens");
        require(_amount <= totalAmountTokens(), "Not enough tokens");
        _;
    }

    /**
     * Fill fund (only by owner).
     */
    function fillFund() external onlyOwner payable{
    }

    /**
     * Get amount of funds available in the contract (only by owner).
     */
    function totalAmount() external view onlyOwner returns(uint256){
        return address(this).balance;
    }

    /**
     * Withdraw all funds (only by owner).
     */
    function withdrawAll() external onlyOwner{
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    /**
     * Get amount of tokens available in the contract (only by owner).
     */
    function totalAmountTokens() public view onlyOwner returns(uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * Withdraw all tokens from contract (only by owner).
     */
    function withdrawAllTokens() external onlyOwner {
        token.transferFrom(address(this), msg.sender, totalAmountTokens());
    }

    /**
     * Get tokens (only by owner).
     * @param _amount the amount of tokens
     */
    function getTokens(uint256 _amount) external onlyOwner enoughTokens(_amount){
        token.transfer(address(this), _amount);
    }

    /**
     * Send tokens (only by owner).
     * @param _recipient the address of recipient
     * @param _amount the amount of tokens
     */
    function sendTokens(address _recipient, uint256 _amount) external onlyOwner enoughTokens(_amount){
        token.transferFrom(address(this), _recipient, _amount);
    }

    /**
     * Approve debit tokens (only by owner).
     * @param _spender the address of spender
     * @param _amount the amount of tokens
     */
    function approveDebitTokens(address _spender, uint256 _amount) external onlyOwner enoughTokens(_amount){
        token.approve(_spender, _amount);
    }
}
