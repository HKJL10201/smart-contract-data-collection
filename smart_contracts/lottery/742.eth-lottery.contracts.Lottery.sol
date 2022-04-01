//
// Copyright David Killen 2021. All rights reserved.
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice This contract allows players to enter and the lottery
 * owner to draw once all entries are sold. Only one entry per address.
 * @dev It is intended that an instance of this contract will be deployed 
 * by a factory contract
 */
contract Lottery is Pausable, AccessControl, ReentrancyGuard {

    /// @dev AccessControl roles
    bytes32 public constant LOTTERY_OWNER_ROLE = keccak256("LOTTERY_OWNER_ROLE");
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN_ROLE");    

    /// @dev The amount to be paid for a single entry (in wei).
    uint256 public entryFee;

    /// @dev The total of the lottery pool (in wei).
    uint256 public pool;

    /// @dev The number of entries required before the lottery can be drawn.
    uint64 public maxEntries;
   
    /// @dev The number of entries.
    uint64 public entryCount;

    /**
     * @dev To calculate the fees for the lottery owner and the platform.
     * Expressed in basis points.
     * E.g. 
     * a value of 50 equates to 0.5%
     * a value of 150 equates to 1.5%
     */
    uint64 public lotteryFee;   
    uint64 public platformFee;
   
    /// @dev Has the lottery been drawn?
    bool public drawn;

    /// @dev Platform administrator.
    address payable public platformAdmin;
   
    /// @dev Lottery owner.
    address payable public lotteryOwner;
   
    /// @dev The players - used to check whether an address has entered.
    mapping(address => bool) public players;
   
    /// @dev An array of the addresses entered.
    address[] public entries;
   
    /// @dev Mapping to aid tracking pending withdrawals
    mapping(address => uint) public pendingWithdrawals;
   
    /**
     * @dev Emitted when an entry is submitted.
     * `player` is the address that submitted an entry.
     */
    event Entered(address player);
   
    /**
     * @dev Emitted when a lottery winner is selected.
     * `winner` is the winning address.
     * `winnings` is the amount won by the winner.
     */ 
    event Winner(address winner, uint winnings);
   
    /**
     * @dev Emitted if eth recieved by receiver function.
     * `sender` The address eth received from.
     * `value` is The amount of eth reveived.
     */
    event Received(address sender, uint value);
   
    /**
     * @dev Emitted when funds are withdrawn from the contract.
     * `payee` is the address withdrawing funds.
     * `amount` is the amount of funds withdrawn by the payee.
     */
    event FundsWithdrawn(address payee, uint amount);

    /**
     * @dev If an address has already entered, reject it. Only one entry per address.
     */ 
    modifier oneEntryPerAddress {
       require(!players[msg.sender], "Address already entered!");
       _;
    }
   
    /**
     * @notice Lottery contract constructor.
     * @param _platformAdmin The address of the lottery platform administrator.
     * @param _lotteryOwner The address of the lottery owner (owner of the lottery).
     * @param _maxEntries The number of entries required before the lottery can be drawn.
     * @param _entryFee The required deposit (in wei) for each entry into the lottery.
     * @param _lotteryFee Used to calculate the lottery owner's fee.
     * @param _platformFee Udes to calculate the lottery platform fee.
     */
    constructor(
        address payable _platformAdmin, 
        address payable _lotteryOwner, 
        uint64 _maxEntries, 
        uint256 _entryFee, 
        uint64 _lotteryFee, 
        uint64 _platformFee 
    ) {
        platformAdmin = _platformAdmin;
        _setupRole(PLATFORM_ADMIN_ROLE, platformAdmin);

        lotteryOwner = _lotteryOwner;
        _setupRole(LOTTERY_OWNER_ROLE, lotteryOwner);

        maxEntries = _maxEntries;
        entryFee = _entryFee;
        lotteryFee = _lotteryFee;
        platformFee = _platformFee;

        entryCount = 0;
        pool = 0;
        drawn = false;
   }
   
    /**
     * @notice Allow a player to enter the lottery.
     * @dev Only one entry allowed per address.
     */
    function enter() public payable oneEntryPerAddress whenNotPaused {
        require(
            msg.value == entryFee,
            "The entry fee is incorrect!"
        );
        require(entryCount < maxEntries, "Maximum entries: no further entries allowed!");

        entries.push(msg.sender);
        players[msg.sender] = true;
        pool = pool + msg.value;
        entryCount++;

        emit Entered(msg.sender);
   }
   
   /**
    * @notice Allow administrators to draw the lottery once all entries are complete
    * @dev Note that this function presently uses the contract's getRandomNumber() function
    * The getRandomNumber function is to be replaced by a call to a Chainlink VRF
    */
    function drawWinner() public whenNotPaused {
        require(
            hasRole(LOTTERY_OWNER_ROLE, msg.sender) || hasRole(PLATFORM_ADMIN_ROLE, msg.sender), 
            "You are not authorized to draw a winner!"
        );

        require(entryCount >= maxEntries, "Not enough entries to draw the winner!");
       
        // Temporary - winner address
        address winner = entries[getRandomNumber() % entryCount];
       
        // Lottery owner's fee
        uint lotteryFeeTotal = calculateFee(pool, lotteryFee);
        pendingWithdrawals[lotteryOwner] = lotteryFeeTotal;
       
        // Platform fee
        uint platformFeeTotal = calculateFee(pool, platformFee);
        pendingWithdrawals[platformAdmin] = platformFeeTotal;
       
        // Winnings
        uint winnings = pool - (pendingWithdrawals[lotteryOwner] + pendingWithdrawals[platformAdmin]);
        pendingWithdrawals[winner] = winnings;

        pool = pool - lotteryFeeTotal - platformFeeTotal - winnings;

        drawn = true;
        emit Winner(winner, winnings);
    }

    /**
     * @dev It is advisable not to use this contract while random numbers are sourced from this function.
     * The getRandomNumber() function is to be replaced with a call to a Chainlink VRF.
     */
    function getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, entryCount)));
    }

    /**
     * @notice Calculate a fee being a percentage (expressed as basis points) of an amount
     * @dev this could have problems with very small numbers but, not numbers within the
     * range expected in a lottery's prize pool. A number that is too small will fail the
     * bound check and revert.
     */
    function calculateFee(uint amount, uint basisPoints) private pure returns (uint256) {
        require((amount / 10000) * 10000 == amount, "Unable to calculate fee: amount too small");
        return amount * basisPoints / 10000;
    }

    /**
     * @notice Withdraw funds from the contract.
     * @dev It is anticipated that this function will be called by the lottery owner, 
     * platform administrator or a lottery winner
     */
    function withdraw() public whenNotPaused nonReentrant {
        require(
            pendingWithdrawals[msg.sender] > 0,
            "No funds to withdraw!"
        );

        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
     
        // payable(msg.sender).transfer(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed!");

        emit FundsWithdrawn(msg.sender, amount);
    }
   
    /**
     * @dev Withdraw the contract balance. This should only be called by the platform 
     * administrator once the lottery is drawn.
     */
    function withdrawBalance() public nonReentrant {
        require(
            hasRole(PLATFORM_ADMIN_ROLE,msg.sender), 
            "You are not authorised!"
        );
        require(drawn == true, "The lottery has not been drawn!");

        uint amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
   
    /**
     * @dev Check the balance on the contract
     */
    function checkBalance() public view returns (uint) {
        require(
            hasRole(PLATFORM_ADMIN_ROLE, msg.sender),
            "You are not authorised!"
        );

        return address(this).balance;
    }

    /**
     * @dev Call _pause function inherited from Pausable to pause the contract
     */
    function pause() public whenNotPaused {
        require(
            hasRole(LOTTERY_OWNER_ROLE, msg.sender) || hasRole(PLATFORM_ADMIN_ROLE, msg.sender),
            "You are not authorized to take this action!"
        );
        _pause();
    }

    /**
     * @dev Call _unpause() inherited from Pausable to unpause the contract
     */
    function unpause() public whenPaused {
        require(
            hasRole(LOTTERY_OWNER_ROLE, msg.sender) || hasRole(PLATFORM_ADMIN_ROLE, msg.sender),
            "You are not authorized to take this action!"
        );
        _unpause();
    }
   
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
