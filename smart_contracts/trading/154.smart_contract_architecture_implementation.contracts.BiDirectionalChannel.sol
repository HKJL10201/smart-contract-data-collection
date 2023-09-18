// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./Hashing.sol";

/**
@title BiDirectionalChannel
A contract that implements a bi-directional channel for managing balances between two users.
*/
contract BiDirectionalChannel is Hashing {
    event Withdraw(address indexed to, uint amount);
    event ExpiresAtChanged(uint expiresAt);
    event Deposit(address indexed from, uint amount);
    event VerificationResult(bool indexed success, address indexed contractAddress, address indexed signature);
    event BalanceChanged(address _address, uint256 _nonce, uint256 _balance1, uint256 _balance2);
    event WithdrawAmount(address _address, uint256 _amount);

    address[2] public users;
    mapping(address => bool) public isUser;
    mapping(address => uint256) public balances;
    uint256 public nonce;
    uint256 public endDate;
    uint256 public period;

    /**
    Modifier to check if the contract has sufficient balance to cover the provided balances.
    @param _balances The array of balances.
    */
    modifier checkBalance(uint256[2] memory _balances) {
        require(
            address(this).balance >= _balances[0] + _balances[1],
            "Balance of contract must be greater or equal to the balances of users !!"
        );
        _;
    }

    /**
    Modifier to check if the sender is a valid user.
    */
    modifier onlyUser() {
        require(isUser[msg.sender], "Only valid users are required");
        _;
    }

    /**
    Modifier to check the validity of the provided signatures against the message hash and balances.
    @param _signatures The array of signatures.
    @param _nonce The nonce value.
    @param _balances The array of balances.
    */
    modifier checkSignatures(
        bytes[2] memory _signatures,
        uint256 _nonce,
        uint256[2] memory _balances
    ) {
        address[2] memory signers;
        for (uint256 i = 0; i < 2; i++) signers[i] = users[i];

        for (uint256 i = 0; i < 2; i++) {
            bytes32 message = getMessage(address(this), _balances, _nonce);
            bool ver = verify(signers[i], message, _signatures[i]);
            require(ver, "Invalid Signature !!");
        }
        _;
    }

    /**
    Modifier to check the validity of the provided signatures against a given message hash, nonce, and balances.
    @param _msgHash The message hash.
    @param _signatures The array of signatures.
    @param _nonce The nonce value.
    @param _balances The array of balances.
    */
    modifier checkSignaturesWithHash(
        bytes32 _msgHash,
        bytes[2] memory _signatures,
        uint256 _nonce,
        uint256[2] memory _balances
    ) {
        address[2] memory signers;
        for (uint256 i = 0; i < 2; i++) signers[i] = users[i];

        for (uint256 i = 0; i < 2; i++) {
            bool ver = verify(signers[i], _msgHash, _signatures[i]);
            require(ver, "Invalid Signature !!");
        }
        _;
    }

    /**
    Constructs a new BiDirectionalChannel contract.
    @param _users The array of user addresses.
    @param _balances The array of initial balances.
    @param _endDate The end date of the channel.
    @param _period The duration of the channel.
    */
    constructor(
        address payable[2] memory _users,
        uint256[2] memory _balances,
        uint256 _endDate,
        uint256 _period
    ) payable checkBalance(_balances) {
        require(_endDate > block.timestamp, "End date must be ahead of now !!");
        require(_period > 0, "The period should be a valid range !!");

        for (uint8 i = 0; i < users.length; i++) {
            require(_users[0] != _users[1], "Duplicate addresses not allowed !!");

            users[i] = _users[i];
            isUser[users[i]] = true;

            // Deposit the initial balance for each user
            //deposit();

            // Add the initial balance to the user's deposit
            balances[users[i]] += _balances[i];
        }

        endDate = _endDate;
        period = _period;
    }

    /**
    Returns the balance of the contract.
    @return The balance of the contract.
    */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
    Changes the balances of the users and updates the nonce.
    @param _msgHash The message hash.
    @param _signatures The array of signatures.
    @param _nonce The nonce value.
    @param _balances The array of new balances.
    */
    function changeBalance(
        bytes32 _msgHash,
        bytes[2] memory _signatures,
        uint256 _nonce,
        uint256[2] memory _balances
    ) public onlyUser checkSignaturesWithHash(_msgHash, _signatures, _nonce, _balances) checkBalance(_balances) {
        require(block.timestamp < endDate, "Executing an expired contract !!");
        require(nonce < _nonce, "Nonce should be correct");

        for (uint256 i = 0; i < 2; i++) balances[users[i]] = _balances[i];
        nonce = _nonce;

        endDate = block.timestamp + period;

        emit BalanceChanged(msg.sender, nonce, balances[users[0]], balances[users[1]]);
    }

    //TODO: Only allow valid users to close the channel
    /**
    Allows a user to withdraw their balance after the channel expires.
    */
    function withdraw() public {
        require(block.timestamp >= endDate, "Period is not expired yet !!");

        uint256 amount = balances[msg.sender];
        require(amount > 0, "User has no balance");
        balances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{ value: amount }("");
        require(success, "Amount Transfer is failed !!");

        emit WithdrawAmount(msg.sender, amount);
    }

    /**
     * Allows a user to withdraw their balance after the channel expires.
     * @param _userAddress The address of the user.
     */
    function withdrawByUser(address payable _userAddress) public {
        require(block.timestamp >= endDate, "Period is not expired yet !!");

        uint256 amount = balances[_userAddress];
        require(amount > 0, "User has no balance");

        balances[_userAddress] = 0;

        (bool success, ) = payable(_userAddress).call{ value: amount }("");
        require(success, "Amount Transfer failed !!");

        emit WithdrawAmount(_userAddress, amount);
    }

    /**
    Sets the expiration date of the channel.
    @param _newExpiresAt The new expiration date.
    */
    function setExpiresAt(uint256 _newExpiresAt) public onlyUser {
        require(_newExpiresAt > block.timestamp, "Expiration must be > now");
        endDate = _newExpiresAt;
        emit ExpiresAtChanged(endDate);
    }

    /**
    Allows a user to deposit funds into the channel.
    */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * Allows a specific user to deposit funds into the channel.
     * @param _userAddress The address of the user.
     */
    function depositByUser(address payable _userAddress) public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[_userAddress] += msg.value;
        emit Deposit(_userAddress, msg.value);
    }

    /**
    Returns the current block timestamp.
    @return The current block timestamp.
    */
    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
