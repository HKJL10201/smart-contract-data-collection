// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Timer.sol";

/// This contract represents abstract auction.
contract Auction {

    enum Outcome {
        NOT_FINISHED,
        NOT_SUCCESSFUL,
        SUCCESSFUL
    }

    /// Address of timer.
    Timer private timer;

    /// Address of a judge.
    address internal judgeAddress;

    /// Address of seller.
    address internal sellerAddress;

    /// Address of the highest bidder.
    /// This should be set when the auction is over.
    address internal highestBidderAddress;

    /// Indicates auction outcome.
    Outcome internal outcome;

    constructor(
        address _sellerAddress,
        address _judgeAddress,
        Timer _timer
    ) {
        timer = _timer;
        judgeAddress = _judgeAddress;
        sellerAddress = _sellerAddress;
        if (sellerAddress == address(0)) {
            sellerAddress = msg.sender;
        }
        outcome = Outcome.NOT_FINISHED;
    }

    /// Internal function used to finish an auction.
    /// Auction can finish in three different scenarios:
    /// 1.) Somebody have won the auction and seller has the rights to get the
    ///     founds on this contract.
    /// 2.) Auction finished with highest bidder, but for some reason the
    ///     highest bidder does not have rights to claim the auction item
    ///     (e.g. minimal item price is not reached).
    /// 3.) Not one bid has been placed for an item.
    ///
    /// The values that should be used with this function invocation for each of
    /// the cases are:
    /// 1.) In the case of the first outcome, contract should call this method with
    ///     _highestBidderAddress != address(0) and _outcome should be equal to
    ///     Auction.Outcome.SUCCESSFUL.
    /// 2.) In the case of the second outcome, contract should call this method
    ///     with _outcome == AuctionOutcome.NOT_SUCCESSFUL and arbitrary value
    ///     for the _highestBidderAddress parameter.
    /// 3.) In the third case when not a single bid was placed, then this function
    ///     should be called with _outcome == NOT_SUCCESSFUL and
    ///     _highestBidderAddress should be equal to address(0).
    ///
    /// @param _outcome Outcome of the auction.
    /// @param _highestBidder Address of the highest bidder or address(0) if auction did not finish successfully.
    function finishAuction(Outcome _outcome, address _highestBidder) internal {
        require(_outcome != Outcome.NOT_FINISHED);
        // This should not happen.
        outcome = _outcome;
        highestBidderAddress = _highestBidder;
    }

    /// Finalizes the auction and sends the money to the auction seller.
    /// This function can only be called when the auction has finished successfully.
    /// If no judge is specified for an auction then anybody can request
    /// the transfer of fonds to the seller. If the judge is specified,
    /// then only the judge or highest bidder can transfer the funds to the seller.
    function finalize() public {
        require(outcome == Outcome.SUCCESSFUL);
        require((judgeAddress == address(0)) || (judgeAddress != address(0) && (msg.sender == judgeAddress || msg.sender == highestBidderAddress)));

        payable(sellerAddress).transfer(address(this).balance);

    }

    // If a judge is specified, this can ONLY be called by seller or the judge.
    // Otherwise, anybody can request refund to the highest bidder.
    // Money can only be refunded to the highest bidder.
    function refund() public {
        require(outcome != Outcome.SUCCESSFUL);
        require(msg.sender == judgeAddress || msg.sender == sellerAddress);
        require(highestBidderAddress != address(0));

        payable(highestBidderAddress).transfer(address(this).balance);
    }

    // This is provided for testing
    // You should use this instead of block.number directly
    // You should not modify this function.
    function time() public view returns (uint) {
        return timer.getTime();
    }

    /// Function that returns highest bidder address or address(0) if
    /// auction is not yet over.
    function getHighestBidder() public virtual returns (address) {
        return highestBidderAddress;
    }

    // Function that returns auction outcome variable.
    function getAuctionOutcome() public virtual returns (Outcome) {
        return outcome;
    }
}
