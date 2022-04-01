pragma solidity ^0.4.18;


import "./Auction.sol";

contract TokenAuction is Auction {

    event AuctionStarted(address bidToken, ERC179Interface token, uint amount);

    ERC179Interface public auctionedToken;
    uint public auctionedAmount;

    function initToken(
        address _token,
        uint _amount
    ) uninitialized external
    {
        auctionedToken = ERC179Interface(_token);
        auctionedAmount = _amount;
    }

    function untrustedTransferItem(address receiver) internal {
        require(auctionedToken.transfer(receiver, auctionedAmount));
    }

    function funded() public view returns (bool) {
        return auctionedToken.balanceOf(this) >= auctionedAmount;
    }

    function logStart() internal {
        AuctionStarted(bidToken(), auctionedToken, auctionedAmount);
    }

    function untrustedTransferExcessAuctioned(address receiver, address token, uint) internal returns (bool notAuctioned) {
        if (ERC179Interface(token) == auctionedToken) {
            uint transferAmount = auctionedToken.balanceOf(this);
            if (started()) {
                transferAmount -= auctionedAmount;
            }
            auctionedToken.transfer(receiver, transferAmount);
            return false;
        } else {
            return true;
        }
    }

    function incomingFunds(address token, uint amount) internal returns (bool accepted) {
        return token == address(auctionedToken) && amount + auctionedToken.balanceOf(this) == auctionedAmount;
    }
}