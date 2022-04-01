contract IAuctionStatus {
    function endBlock() public view returns (uint40);
    function auctionEnd() public view returns (uint40);
    function endExtension() public view returns (uint32);
    function fixedIncrement() public view returns (uint);
    function fractionalIncrement() public view returns (uint24);
    function started() public view returns (bool);
    function activeWithdrawal() internal view returns (bool);
    
    function setEndBlock(uint40) internal;
    function setAuctionEnd(uint40) internal;
    function setEndExtension(uint32) internal;
    function setFixedIncrement(uint) internal;
    function setFractionalIncrement(uint24) internal;
    function setStarted(bool) internal;
    function setActiveWithdrawal(bool) internal;

    function maximumTokenSupply() internal pure returns (uint);

    function highestBidder() public view returns (address);
    function highestBid() public view returns (uint256);

    function setHighestBid(address bidder, uint256 amount) internal;
}