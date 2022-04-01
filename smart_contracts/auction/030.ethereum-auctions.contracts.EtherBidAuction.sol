pragma solidity ^0.4.18;

import "./Auction.sol";

contract EtherBidAuction is Auction {

    function increaseBid() external payable {
        registerBid(msg.sender, msg.value);
    }

    // Transfers a bid.
    function untrustedTransferBid(address receiver, uint256 amount) internal {
        if (amount != 0) {
            receiver.transfer(amount);
        }
    }

    function bidToken() public view returns (address) {
        return 0x0;
    }

    function bidBalance() internal view returns (uint) {
        return this.balance;
    }
}