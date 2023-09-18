// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/* Errors */
error Auction__BidTooLow();

/**@title AdvertisementAuction
 * @author Devival
 * @notice This contract allows anyone to pay more ETH than the last person
 * to change the text and image link on the website
 * @dev
 */

contract Auction is Ownable {
    /* State variables */

    uint256 private lastBid;
    address private bidder;

    /* Events */
    event BidPlaced(address indexed bidder, uint256 indexed newBid);

    /* Functions */

    function bidHigher() public payable {
        // require(msg.value > lastBid, "Bid too low");
        if (msg.value < lastBid) {
            revert Auction__BidTooLow();
        }
        // store a bid winner
        bidder = address(msg.sender);
        lastBid = msg.value;

        // Emit an event
        emit BidPlaced(bidder, lastBid);
    }

    // allows an owner to withdraw whole contract balance
    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function getLastBid() public view returns (uint256) {
        return lastBid;
    }

    function getHigestBidder() public view returns (address) {
        return bidder;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}
}
