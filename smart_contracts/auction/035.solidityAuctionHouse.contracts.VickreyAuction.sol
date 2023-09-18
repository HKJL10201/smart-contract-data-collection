pragma solidity ^0.4.18;
import "./Auction.sol";

contract VickreyAuction is Auction {

    struct Record{
      bytes32 bidCommitment;
      bool refundIssued;
    }

    uint public minimumPrice;
    uint public biddingDeadline;
    uint public revealDeadline;
    uint public bidDepositAmount;
    uint internal currentHighest;
    uint internal secondHighest;

    event debug (address bidder);

    mapping (address => Record) public bidderRecord;

    // constructor
    function VickreyAuction(address _sellerAddress,
                            address _judgeAddress,
                            address _timerAddress,
                            uint _minimumPrice,
                            uint _biddingPeriod,
                            uint _revealPeriod,
                            uint _bidDepositAmount) public
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        minimumPrice = _minimumPrice;
        bidDepositAmount = _bidDepositAmount;
        biddingDeadline = time() + _biddingPeriod;
        revealDeadline = time() + _biddingPeriod + _revealPeriod;
        secondHighest = minimumPrice;

    }

    // Record the player's bid commitment
    // Make sure at least bidDepositAmount is provided (for new bids)
    // Bidders can update their previous bid for free if desired.
    // Only allow commitments before biddingDeadline
    function commitBid(bytes32 bidCommitment) public payable {
        require(time() < biddingDeadline);
        require(msg.value >= bidDepositAmount || isExistingBidder(msg.sender));

        //refund if this is a update request
        if(isExistingBidder(msg.sender) && msg.value > 0)
          msg.sender.transfer(msg.value);
        //partial refund if value > deposit requriement
        else if(msg.value > bidDepositAmount)
          msg.sender.transfer(msg.value - bidDepositAmount);

        bidderRecord[msg.sender] = Record(bidCommitment, false);
    }


    function isExistingBidder(address addr) public returns(bool isExists){
      return (bidderRecord[addr].bidCommitment!= bytes32(0x0)) ? true : false;
    }

    // Check that the bid (msg.value) matches the commitment
    // If the bid is below the minimum price, it is ignored but the deposit is returned.
    // If the bid is below the current highest known bid, the bid value and deposit are returned.
    // If the bid is the new highest known bid, the deposit is returned and the previous high bidder's bid is returned.
    function revealBid(bytes32 nonce) public payable returns(bool isHighestBidder) {
        // Make sure nonce and bid commitment matches
        require(keccak256(msg.value, nonce) == bidderRecord[msg.sender].bidCommitment);
        require(time() >= biddingDeadline && time() < revealDeadline);
        require(bidderRecord[msg.sender].refundIssued == false);

        // Prevent issuing refund twice
        bidderRecord[msg.sender].refundIssued = true;

        if(msg.value < minimumPrice)
          msg.sender.transfer(bidDepositAmount);

        else if(msg.value < currentHighest){
          msg.sender.transfer(bidDepositAmount + msg.value);
          //Update for secondHighest bid so far
          secondHighest = (msg.value > secondHighest)? msg.value: secondHighest;
        }
        else if(msg.value > currentHighest){

          //if there's a previous winner
          if(currentHighest != 0){
            secondHighest = currentHighest;
            winnerAddress.transfer(currentHighest);
          }
          currentHighest = msg.value;
          winnerAddress = msg.sender;
          msg.sender.transfer(bidDepositAmount);
        }


    }

    // finalize() must be extended here to provide a refund to the winner
    function finalize() public {
        require(time() >= revealDeadline);

        uint refund = currentHighest - secondHighest;

        if(refund > 0)
          getWinner().transfer(refund);
        // call the general finalize() logic
        super.finalize();
    }
}
