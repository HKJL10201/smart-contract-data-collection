// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Auction {
    // events
    event bidMade(address bidder);
    event bidRevealed(address bidder, uint256 value, bool isValid);
    event BiddingClosed();
    event AuctionClosed(address barbossa, uint256 winnings);

    bool public biddingClosed;
    bool public auctionClosed;
    address payable public barbossa;

    address[] public validBidders;
    mapping(address => bytes32) public hashedEscrow;
    mapping(address => uint256) public escrow;

    constructor() public {
        biddingClosed = false;
        auctionClosed = false;
        barbossa = msg.sender;
    }

    /**
     * commitBid :- Initial commitment to bid sent in by the bidders
     *
     * @param {bytes32} commit -  This is the hash of [bin_encoding(nonce+random_number)]
     */
    function commitBid(bytes32 commit) external {
        require(!biddingClosed);

        hashedEscrow[msg.sender] = commit;

        emit bidMade(msg.sender);
    }

    /**
     * getCommitHash :- Returns hashed value given bid amount and random number
     *
     * @param {uint256} value -  Monetary amount thats been commited
     * @param {uint256} nonce -  Random number initially sent with the monetary commitment
     */
    function getCommitHash(uint256 value, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(value, nonce));
    }

    /**
     * revealBid :- Takes money from bidder and checks if its equal to the commited amount
     *
     * @param {uint256} nonce -  Initial hash value sent in the commit phase
     */
    function revealBid(uint256 nonce) external payable {
        require(biddingClosed);
        require(getCommitHash(msg.value, nonce) == hashedEscrow[msg.sender]);

        escrow[msg.sender] = msg.value;
        validBidders.push(msg.sender);

        emit bidRevealed(msg.sender, msg.value, true);
    }

    /**
     * highestBid :- Returns the second highest bid amount
     *
     */
    function highestBid() internal returns (uint256) {
        address tempWinner;
        uint256 highestBidAmt = 0;
        uint256 secondHighestBidAmt = 0;
        for (uint256 index = 0; index < validBidders.length; index++) {
            if (escrow[validBidders[index]] > highestBidAmt) {
                tempWinner = validBidders[index];

                secondHighestBidAmt = highestBidAmt;
                highestBidAmt = escrow[tempWinner];
            }
        }

        escrow[tempWinner] -= secondHighestBidAmt;
        return secondHighestBidAmt;
    }

    /**
     * closeBidding :- Only can be called by host of the auction to close the bidding. No further commitments are accepted past this
     *
     */
    function closeBidding() external {
        require(msg.sender == barbossa);

        biddingClosed = true;

        emit BiddingClosed();
    }

    /**
     * closeAuctionAndCollectWinningBid :- After winner is determined, closes auction and pays the host the second highest bid amount
     *
     */
    function closeAuctionAndCollectWinningBid() external {
        require(!auctionClosed);
        require(biddingClosed);
        require(msg.sender == barbossa);

        auctionClosed = true;

        uint256 winningBid = highestBid();

        barbossa.transfer(winningBid);

        emit AuctionClosed(barbossa, winningBid);
    }

    /**
     * closeAuctionAndCollectWinningBid :- After winner is determined, closes auction and pays the host the second highest bid amount
     *
     */
    function withdrawBid() external returns (uint256) {
        require(auctionClosed);

        uint256 amount;

        if (escrow[msg.sender] > 0) {
            msg.sender.transfer(escrow[msg.sender]);
            amount = escrow[msg.sender];
            escrow[msg.sender] = 0;
        }

        return amount;
    }
}
