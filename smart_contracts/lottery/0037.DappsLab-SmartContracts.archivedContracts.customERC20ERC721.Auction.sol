// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ERC20/ERC20.sol";
import "./ERC721/ERC721.sol";
import "./ERC721/IERC721Receiver.sol";

contract Auction is IERC721Receiver{
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address payable public beneficiary;
    uint public auctionEndTime;
    ERC20 private _token;
    ERC721 private _NFT;
    uint256 _tokenId;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;
    mapping(address => uint) bidderIndexes;
    uint256 minimumPrice;
    address[] private allBidders;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(uint256 tokenId, address bidder, uint amount);
    event AuctionEnded(uint256 tokenId, address winner, uint amount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        uint256 tokenId,
        uint _biddingTime,
        address _beneficiary,
        ERC20 tokenAddress,
        address NFT,
        uint256 minPrice
    ) {
        _tokenId = tokenId;
        beneficiary = payable(_beneficiary);
        auctionEndTime = block.timestamp + _biddingTime;
        _token = tokenAddress;
        _NFT = ERC721(NFT);
        minimumPrice = minPrice;
        allBidders.push(address(0));
    }

    function sendTokenToOwner() public {
        _NFT._spend(_tokenId, beneficiary);
    }

    function getPendingReturns(address _address) public view returns(uint) {
        return pendingReturns[_address];
    }

    function sendTokenToOwnerBack() public {
        _NFT._spend(_tokenId, beneficiary);
    }


    function getToken() public view returns(ERC20){
        return _token;
    }

    //  ERC20 private _token; // getters and setters
    function setToken(address tokenAddress) public {
        _token = ERC20(tokenAddress);
    }

    function getNFT() public view returns(ERC721){
        return _NFT;
    }

    //  ERC20 private _token; // getters and setters
    function setNFT(address NFTAddress) public {
        _NFT = ERC721(NFTAddress);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(uint256 amount) public payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.

        // Revert the call if the bidding
        // period is over.
        require(
            block.timestamp <= auctionEndTime,
            "Auction already ended."
        );

        // If the bid is not higher, send the
        // money back (the failing require
        // will revert all changes in this
        // function execution including
        // it having received the money).
        require(amount >= minimumPrice, "Amount is less than minimum Price!");
        require(
            amount > highestBid,
            "There already is a higher bid."
        );
        require(_token.spendFrom(_tokenId, msg.sender, amount));
        if (highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = amount;
        if(bidderIndexes[msg.sender] == 0){
            allBidders.push(msg.sender);
            bidderIndexes[msg.sender] = allBidders.length-1;
        }
        emit HighestBidIncreased(_tokenId, msg.sender, amount);
    }

    /// Withdraw a bid that was overbid.
    function withdraw()public returns(bool){
        return _withdraw(msg.sender);
    }

    function _withdraw(address bidder) private returns (bool) {
        uint amount = pendingReturns[bidder];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[bidder] = 0;

            if (!_token.transfer(bidder, amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[bidder] = amount;
                return false;
            }
        }
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public payable {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. Conditions
        require(msg.sender == beneficiary || msg.sender == highestBidder, "only owner of token can call this function");
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(_tokenId, highestBidder, highestBid);

        // 3. Interaction
        if(highestBidder != address(0)){
            _NFT._spend(_tokenId, highestBidder);
            uint256 commission = (highestBid * _NFT.getCreatorCommission()) / 100 ;
            _token.transfer(_NFT.getCreator(_tokenId), commission);
            uint256 platform = (highestBid * _NFT.getPlatformCommission()) / 100 ;
            _token.transfer(_NFT.getCreator(_tokenId), platform);
            uint256 total = commission + platform;
            _token.transfer(beneficiary, (highestBid - total));
            for (uint256 i = 1; i < allBidders.length; i++){
                _withdraw(allBidders[i]);
            }
        }else{
            _NFT._spend(_tokenId, beneficiary);
        }
        _NFT.deleteAuctionContract(_tokenId);
        _token.deleteAuctionAddress(_tokenId);
    }
}
