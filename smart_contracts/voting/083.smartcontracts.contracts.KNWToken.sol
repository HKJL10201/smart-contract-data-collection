pragma solidity ^0.5.15;

import "./libraries/SafeMath.sol";

/**
 * @title Knowledge-Token
 *
 * @dev Implementation of the knowledge token that is being used for knowledge-extractable voting
 * This implementation has the additional functionality of mapping an address to ids (representing 
 * a string) instead of mapping them directly to uint256 balance. It also implements locking, 
 * unlocking and minting and burning functions.
 */
contract KNWToken {
    using SafeMath for uint256;

    event Mint(address indexed who, uint256 id, uint256 value);
    event Burn(address indexed who, uint256 id, uint256 value);
    event NewLabel(uint256 indexed id, string label);

    mapping (address => mapping (uint256 => uint256)) private _balance;
    mapping (address => mapping (uint256 => uint256)) private _lockedBalance;

    uint256 private _totalSupply;
    mapping (uint256 => uint256) private _idSupply;

    string[] private _labels;
    
    string constant public symbol = "KNW";
    string constant public name = "Knowledge Token";
    uint8 constant public decimals = 18;

    address public manager;
    mapping (address => bool) public authorizedAddresses;

    constructor() public {
        manager = msg.sender;
    }

    /**
     * @dev Replaces the manager address 
     * @param _address The address of the new manager
     * @return A boolean that indicates if the operation was successful
     */
    function replaceManager(address _address) external onlyManager(msg.sender) returns (bool success) {
        require(_address != address(0));
        manager = _address;
        return true;
    }

    /**
     * @dev Adds an address that will be able to access the authorized functions
     * @param _address An address of a new authorized voting contract
     * @return A boolean that indicates if the operation was successful
     */
    function authorizeAddress(address _address) external onlyManager(msg.sender) returns (bool success) {
        require(_address != address(0), "Authorized contracts' address can't be empty");
        authorizedAddresses[_address] = true;
        return true;
    }

    /**
     * @dev Removes an address that will be able to access the authorized functions
     * @param _address An address of a new authorized voting contract
     * @return A boolean that indicates if the operation was successful
     */
    function removeAddress(address _address) external onlyManager(msg.sender) returns (bool success) {
        require(_address != address(0), "Authorized contracts' address can't be empty");
        authorizedAddresses[_address] = false;
        return true;
    }
    
    /**
     * @dev Total number of tokens for all ids
     * @return A uint256 representing the total token amount
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Number of tokens for a certain id
     * @param _id The id of the tokens
     * @return A uint256 representing the token amount for this id
     */
    function totalIDSupply(uint256 _id) external view returns (uint256 totalSupplyOfID) {
        return _idSupply[_id];
    }

    /**
     * @dev Gets the balance for a specified address for a certain id
     * @param _address The address to query the balance of
     * @param _id The id of the requested balance
     * @return A uint256 representing the amount owned be the passed address for the specified id
     */
    function balanceOfID(address _address, uint256 _id) external view returns (uint256 balance) {
        return _balance[_address][_id];
    }

    /**
     * @dev Gets the non-locked balance for a specified address for a certain id
     * @param _address The address to query the free balance of
     * @param _id The id of the requested free balance
     * @return A uint256 representing the non-locked amount owned be the passed address for the specified id
     */
    function freeBalanceOfID(address _address, uint256 _id) external view returns (uint256 freeBalance) {
        return _balance[_address][_id].sub(_lockedBalance[_address][_id]);
    }

    /**
     * @dev Gets the string label for an id
     * @param _id The id whoich label is requested
     * @return A string representing the label of the id
     */
    function labelOfID(uint256 _id) external view returns (string memory label) {
        return _labels[_id];
    }

    /**
     * @dev Gets the amount of ids
     * @return A uint256 representing the amount of ids
     */
    function amountOfIDs() external view returns (uint256 amount) {
        return _labels.length;
    }

    /**
     * @dev Locks a non-locked amount of tokens for an address at a certain id
     * @param _address The address to lock the free balance of
     * @param _id The ID of the free balance that ought to be locked
     * @param _amount The amount of tokens that ought to be locked
     * @return A boolean that indicates if the operation was successful
     */
    function lockTokens(address _address, uint256 _id, uint256 _amount) external onlyAuthorizedAddress(msg.sender) returns (bool success) {
        uint256 freeTokens = _balance[_address][_id].sub(_lockedBalance[_address][_id]);
        require(freeTokens >= _amount, "Can't lock more tokens than available");
        _lockedBalance[_address][_id] = _lockedBalance[_address][_id].add(_amount);
        return true;
    }

    /**
     * @dev Unlocks the specified amount of tokens
     * @param _address The address to unlock a certain balance of
     * @param _id The id of the amount that ought to be unlocked
     * @param _amount The amount of tokens that is requested to be unlocked
     * @return A boolean that indicates if the operation was successful
     */
    function unlockTokens(address _address, uint256 _id, uint256 _amount) external onlyAuthorizedAddress(msg.sender) returns (bool success) {
        require(_lockedBalance[_address][_id] <= _balance[_address][_id], "Cant lock more KNW than an address has");
        _lockedBalance[_address][_id] = _lockedBalance[_address][_id].sub(_amount);
        return true;
    }

    /**
     * @dev Mints new tokens according to the specified minting method and the winning percentage
     * @param _address The address to receive new KNW tokens
     * @param _id The ID that new token will be minted for
     * @param _amount The amount of tokens to be minted
     * @return A boolean that indicates if the operation was successful
     */
    function mint(address _address, uint256 _id, uint256 _amount) external onlyAuthorizedAddress(msg.sender) returns (bool success) {
        require(_address != address(0), "Address can't be empty");
        require(_id < _labels.length, "ID needs to be within range of allowed IDs");

        _totalSupply = _totalSupply.add(_amount);
        _idSupply[_id] = _idSupply[_id].add(_amount);
        _balance[_address][_id] = _balance[_address][_id].add(_amount);

        emit Mint(_address, _id, _amount);
        return true;
    }

    /**
     * @dev Burns tokens accoring to the specified burning method and the winning percentage
     * @param _address The address to receive new KNW tokens
     * @param _id The ID that new token will be minted for
     * @param _amount The amount of tokens that will be burned
     * @return A boolean that indicates if the operation was successful
     */
    function burn(address _address, uint256 _id, uint256 _amount) external onlyAuthorizedAddress(msg.sender) returns (bool success) {
        require(_address != address(0), "Address can't be empty");
        require(_id < _labels.length, "ID needs to be within range of allowed IDs");

        _totalSupply = _totalSupply.sub(_amount);
        _idSupply[_id] = _idSupply[_id].sub(_amount);
        _balance[_address][_id] = _balance[_address][_id].sub(_amount);
        
        emit Burn(_address, _id, _amount);
        return true;
    }

    /**
     * @dev Adds a new label
     * @param _newLabel The new label that ought ot be added
     * @return A boolean that indicates if the operation was successful
     */
    function addNewLabel(string calldata _newLabel) external onlyManager(msg.sender) returns (bool success) {
        _labels.push(_newLabel);
        emit NewLabel(_labels.length-1, _newLabel);
        return true;
    }

    modifier onlyAuthorizedAddress(address _address) {
        require(authorizedAddresses[_address]);
        _;
    }

    modifier onlyManager(address _address) {
        require(manager == msg.sender);
        _;
    }
}