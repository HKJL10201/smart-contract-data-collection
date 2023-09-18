pragma solidity >=0.4.21 <0.7.0;

import './GenericERC20.sol';

/**
 * This contract manages generic wallet applications. Every new application creates a new ERC20 Token.
 * The owner can grant/revoke to accounts to manage his application.
 * The owner and/or granted accounts can manage these tokens by 
 *   creating new token (mint)
 *   remove token (burn)
 *   transfer token between accounts (transfer / transferBulk)
 */
contract GenericWallet {
    address payable private owner;
    
    // strings used by Privalege event
    string constant GRANTED = "Granted";
    string constant REVOKED = "Revoked";

    uint constant PAYMENT_AMOUNT = 500 finney;
    uint8 constant MAX_BULK_TRANSFER = 126;

    struct Application {
        string name;
        GenericERC20 appERC20;
        mapping(address => bool) grantedAccounts;
        mapping(address => uint) accountsExpirationDate;
    }
    
    mapping(address => Application) applications;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyApplicationOwner {
        require(bytes(applications[msg.sender].name).length != 0, "Only Application Owner can call this function");
        _;
    }
    
    modifier onlyGrantedAccounts(address ownerAddress) {
        require(bool(applications[ownerAddress].grantedAccounts[msg.sender]) == true, "Only granted accounts can call this function.");
        require(applications[ownerAddress].accountsExpirationDate[msg.sender] >= now,"Expired access account.");
        _;
    }

    /**
     * Create a new application for the sender address
     * 
     * @param name The name of the new application
     * @param grantAccessToOwner Indicates if the owner (sender) wants to have grant access to manage his application
     * @param expirationDate Timestamp when the owner grant access will expire
     * 
     * Emits an { ApplicationCreated } event
     * 
     * Requirements:
     *  This function require an address without an application in this contract
     *  parameter name must be a non-empty string
     */
    function newApplication(
        string memory name,
        bool grantAccessToOwner, uint expirationDate
    ) 
        public payable
    {
        require(bytes(applications[msg.sender].name).length == 0, "Address already have an application.");
        require(bytes(name).length != 0, "Parameter 'name' is empty");

        applications[msg.sender] = Application(name, new GenericERC20());
        if (grantAccessToOwner) {
            grantAccess(msg.sender, expirationDate);
        }
        receiveDeposit();
        emit ApplicationCreated(msg.sender, name);
    }
    
    /**
     * Grant access for an account until  expireGrantAccessDate.
     * Can be used to update the expireGrantAccessDate.
     * 
     * @param account Address to grant access for an account.
     * @param expirationDate Timestamp to when this gant will expire.
     *
     * Emits a {Privilege} event.
     * 
     * Requirements:
     *   expirationDate must be greater than now
     *   only the application owner address can call this function
     */
    function grantAccess(address account, uint expirationDate) public onlyApplicationOwner {
        require(expirationDate > now, "expireGrantAccess value is lower than now");

        applications[msg.sender].grantedAccounts[account] = true;
        applications[msg.sender].accountsExpirationDate[account] = expirationDate;
        emit Privilege(account, GRANTED, msg.sender, applications[msg.sender].accountsExpirationDate[account]);
    }
    
    /**
     * Revoke access for an `account`.
     * 
     * @param account Address to revoke access for an account.
     *
     * Emits a {Privilege} event.
     * 
     * Requirements:
     *   only the application owner address can call this function
     */
    function revokeAccess(address account) public onlyApplicationOwner {
        applications[msg.sender].grantedAccounts[account] = false;
        applications[msg.sender].accountsExpirationDate[account] = 0;
        emit Privilege(account, REVOKED, msg.sender, applications[msg.sender].accountsExpirationDate[account]);
    }
    
    /** 
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply for an especific application `ownerAddress`.
     *
     * Emits a {Tansfer} event on ERC20 contract for `ownerAddress` application with `from` set to the zero address.
     * 
     * Requirements
     * - `account` cannot be the zero address.
     * -  only accounts with grant access can call this function
     */
    function mint(address account, uint256 amount, address ownerAddress) public onlyGrantedAccounts(ownerAddress) {
        applications[ownerAddress].appERC20.mint(account, amount);
        emit Transfer(address(0), account, amount, ownerAddress);
    }
    
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event on ERC20 contract for `ownerAddress` application with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * -  only accounts with grant access can call this function
     */
    function burn(address account, uint256 amount, address ownerAddress) public onlyGrantedAccounts(ownerAddress) {
        applications[ownerAddress].appERC20.burn(account, amount);
        emit Transfer(account, address(0), amount, ownerAddress);
    }

     /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function transfer(address sender, address recipient, uint256 amount, address ownerAddress) public onlyGrantedAccounts(ownerAddress) {
        applications[ownerAddress].appERC20.transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount, ownerAddress);
    }
    
    
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     * 
     * Emits a {Transfer} event for each transfer created.
     *
     * Requirements:
     *
     * - all address from `senders` cannot be the zero address.
     * - all address from `recipients` cannot be the zero address.
     * - all address from `senders` must have a balance of at least respective amount from `amounts` .
     */
    function transferBulk(
        address[] memory senders,
        address[] memory recipients,
        uint256[] memory amounts,
        address ownerAddress
    ) 
        public 
        onlyGrantedAccounts(ownerAddress)
    {
        require(
            recipients.length == amounts.length &&
            senders.length == recipients.length,
            "senders, recipients and amounts must have equals length."
        );
        require(
            senders.length <= MAX_BULK_TRANSFER &&
            recipients.length <= MAX_BULK_TRANSFER &&
            amounts.length <= MAX_BULK_TRANSFER,
            "senders, recipients must be lower than 127 address."
        );

        uint8 i = 0;
        while(i < senders.length) {
            applications[ownerAddress].appERC20.transfer(senders[i], recipients[i], amounts[i]);
            emit Transfer(senders[i], recipients[i], amounts[i], ownerAddress);
            i++;
        }
    }
    
    /**
     * @dev Returns the amount of tokens owned by `account` for application `ownerAddress`.
     */ 
    function balanceOf(address account, address ownerAddress) public view returns (uint256 balance) {
        return applications[ownerAddress].appERC20.balanceOf(account);
    }
    
    /**
     * @dev Returns the total supply from a application `ownerAddress`
     */
    function totalSupply(address ownerAddress) public view returns (uint256 total)  { 
        return applications[ownerAddress].appERC20.totalSupply();
    }
    
    /**
     * @dev Returns the expirateDate of an account from an application `ownerAddress`
     */
    function expireTimeOf(address account, address ownerAddress) public view returns (uint expire) {
        return applications[ownerAddress].accountsExpirationDate[account];
    }
    
    /**
     * @dev Returns if an account is grated for an application `ownerAddress`
     */ 
    function grantedAccessOf(address account, address ownerAddress) public view returns (bool hasGrant) {
        return applications[ownerAddress].grantedAccounts[account];
    }

    function receiveDeposit() private {
        require(msg.value == PAYMENT_AMOUNT, "You must send 0.5 ether.");
        (bool success, ) = owner.call.value(msg.value)("");
        require(success, "Transfer failed.");
    }
    
    /**
     * @dev Emitted when a new application with a `name` is create by the owner {ownerAddress}
     */
    event ApplicationCreated(address indexed ownerAddress, string name);
    
    /**
     * @dev Emitted when an account is grant or revoke in an application.
     */
    event Privilege(address indexed account,string privilege, address indexed ownerAddress, uint expirationDate);
    
    /** @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`) in an especific application.
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value, address indexed ownerAddress);

}