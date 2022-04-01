pragma solidity ^0.4.18;

import "./Auction.sol";
import "./interfaces/EIP20/ERC20Interface.sol";

contract TokenBidAuction is Auction {

    ERC20Interface public bidToken;

    function initTokenBid(
        address _token
    ) uninitialized external
    {
        bidToken = ERC20Interface(_token);
        require(bidToken.totalSupply() <= maximumTokenSupply());
    }
 
    function increaseBid(uint amount) external {
        setActiveWithdrawal(true);
        require(bidToken.transferFrom(msg.sender, this, amount));
        setActiveWithdrawal(false);
        registerBid(msg.sender, amount);
    }

    // Transfers a bid.
    function untrustedTransferBid(address receiver, uint256 amount) internal {
        if (amount != 0) {
            require(bidToken.transfer(receiver, amount));
        }
    }

    function bidBalance() internal view returns (uint) {
        return bidToken.balanceOf(this);
    }
}