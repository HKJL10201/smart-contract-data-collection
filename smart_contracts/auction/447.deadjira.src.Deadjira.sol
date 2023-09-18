// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "open-zeppelin/contracts/access/Ownable.sol";
import { Pausable } from "open-zeppelin/contracts/security/Pausable.sol";

/// @title DeadjiraAuction
/// @author WhiteOakKong
/// @notice A contract for conducting an auction of limited edition Deadjira ordinals.
/// @dev Inherits from the OpenZeppelin Ownable and Pausable contracts.

contract DeadjiraAuction is Ownable, Pausable {
    uint256 public constant AUCTION_SUPPLY = 50;
    uint256 public constant STARTING_PRICE = 3.33 ether;
    uint256 public constant ENDING_PRICE = 1.11 ether;
    uint256 private constant INCREMENT_VALUE = 0.11 ether;
    uint256 private constant INCREMENT_TIME = 213 seconds;

    uint256 public startTime;

    address public withdrawAddress;

    address[] public buyers;
    mapping(address => uint256) public purchased;

    /// @notice Event emitted when a new auction purchase is made.
    /// @param minter The address of the buyer.
    /// @param btcAddress The buyer's BTC address.
    /// @param discordID The buyer's Discord ID.
    /// @param purchaseID The unique ID of the purchase.
    event AuctionPurchase(address minter, string btcAddress, string discordID, uint256 purchaseID);

    event AuctionStarted(uint256 startTime);
    event WithdrawAddressSet(address _address);
    event RefundComplete();

    error IncorrectValue();
    error AuctionSupplyReached();
    error AlreadyPurchased();
    error AuctionAlreadyStarted();
    error AuctionNotStarted();
    error WithdrawAddressNotSet();
    error InvalidAddress();
    error TransferFailed();
    error InvalidFinalPrice();

    /// @dev Constructor to initialize the contract and set it to a paused state.
    constructor() {
        _pause();
    }

    // USER FUNCTIONS //

    /// @notice Allows users to purchase a token during the auction.
    /// @dev Function can only be called when the contract is not paused.
    /// @param btcAddress The buyer's BTC address.
    /// @param discordID The buyer's Discord ID.
    function purchaseAuction(string calldata btcAddress, string calldata discordID) external payable whenNotPaused {
        if (msg.value < calculatePrice()) revert IncorrectValue();
        if (buyers.length >= AUCTION_SUPPLY) revert AuctionSupplyReached();
        if (purchased[msg.sender] != 0) revert AlreadyPurchased();
        buyers.push(msg.sender);
        purchased[msg.sender] = msg.value;
        emit AuctionPurchase(msg.sender, btcAddress, discordID, buyers.length);
    }

    // ACCESS CONTROLLED FUNCTIONS //

    /// @notice Starts the auction by setting the start time and unpausing the contract.
    /// @dev Can only be called by the contract owner.
    function startAuction() external onlyOwner {
        if (startTime != 0) revert AuctionAlreadyStarted();
        _unpause();
        startTime = block.timestamp;
        emit AuctionStarted(startTime);
    }

    /// @notice Toggles the pause state of the contract.
    /// @dev Can only be called by the contract owner.
    function togglePause() external onlyOwner {
        if (startTime == 0) revert AuctionNotStarted();
        if (paused()) _unpause();
        else _pause();
    }

    /// @notice Allows the contract owner to withdraw the contract balance.
    /// @dev Can only be called when the contract is paused and by the contract owner.
    function withdraw() external whenPaused onlyOwner {
        if (withdrawAddress == address(0)) revert WithdrawAddressNotSet();
        (bool success,) = payable(withdrawAddress).call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    ///@notice Change the address to which funds can be withdrawn.
    ///@dev Can only be called by the contract owner and cannot be the zero address.
    ///@param _address The new address to set as the withdrawal address.
    function setWithdrawAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidAddress();
        withdrawAddress = _address;
        emit WithdrawAddressSet(_address);
    }

    /// @notice Allows the contract owner to issue refunds to buyers after the auction has ended.
    /// @dev Can only be called when the contract is paused and by the contract owner.
    /// @param finalPrice The final price of the tokens at the end of the auction.
    function refund(uint256 finalPrice) external whenPaused onlyOwner {
        if (finalPrice < ENDING_PRICE) revert InvalidFinalPrice();
        address[] memory _buyers = buyers;
        for (uint256 i = 0; i < _buyers.length; i++) {
            uint256 refundValue = purchased[_buyers[i]] - finalPrice;
            if (refundValue > 0) {
                (bool success,) = payable(_buyers[i]).call{ value: refundValue }("");
                require(success, "Transfer failed.");
            }
        }
        emit RefundComplete();
    }

    // VIEW FUNCTIONS //

    /// @notice Calculates the current price of the tokens based on the elapsed time since the auction started.
    /// @return The current price of the tokens.
    function calculatePrice() public view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 increments = timeSinceStart / INCREMENT_TIME;
        if (increments * INCREMENT_VALUE > STARTING_PRICE - ENDING_PRICE) return ENDING_PRICE;
        uint256 price = STARTING_PRICE - (increments * INCREMENT_VALUE);
        return price;
    }

    /// @notice Retrieves the purchase data for a specific user.
    /// @param buyer The address of the buyer.
    /// @return The purchase value of the specified buyer.
    function getUserPurchaseData(address buyer) external view returns (uint256) {
        return purchased[buyer];
    }

    /// @notice Retrieves the total number of purchases made during the auction.
    /// @return The total number of purchases.
    function getTotalPurchased() external view returns (uint256) {
        return buyers.length;
    }

    receive() external payable { }
}
