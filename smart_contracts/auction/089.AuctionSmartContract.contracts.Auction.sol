
pragma solidity 0.8.11;


import "./ERC20.sol";

contract Auction {
    // static
    address public owner;
  //  uint public startBlock;
   // uint public endBlock;
    address public asset;
    // state
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    bool ownerHasWithdrawn;
  
    mapping(address => uint256) public bids;
    address public winner;
    uint public startTime;
    uint public endTime;
    ERC20 public token;

    mapping(address => uint256) public balanceOf;

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != owner);
        _;
    }

    modifier allowAfterStart {
        require(!(block.timestamp < startTime));
        _;
    }

    modifier notAfterEnd { 
        require(!(block.timestamp > endTime));
        _;
    }

    modifier onlyNotCanceled {
    //    if (canceled) throw;
        require(!canceled);
        _;
    }

    modifier onlyEndedOrCanceled {
        //if (block.number < endBlock && !canceled) throw;
        require(block.number < endTime && !canceled);
        _;
    }
    

    constructor(address _asset, uint256 createdDate, uint256 _startTime, uint256 _endTime) public {
        if (startTime >= endTime) revert("start time should be greater then end time");
        if (startTime < block.number) revert("start time is greater then block.numner");
        if (asset == address(0)) revert();

        token = ERC20(_asset);

        owner = msg.sender;
        asset = _asset;
        startTime = _startTime;
        endTime = _endTime;

    }



    function getHighestBid()
         external view
        returns (uint)
    {
        return bids[highestBidder];
    }

    function bid() 
        external
        payable
        allowAfterStart //onlyAfterStart
        notAfterEnd //onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {
        // reject payments of 0 ETH
        // if (msg.value == 0) throw;
        require(msg.value !=0);

        bids[msg.sender] = msg.value;
 
        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint newBid = bids[msg.sender] + msg.value;
        balanceOf[msg.sender] += msg.value;
        //CrosToken token = CrosToken(auction.tokenAddress);
          //  require(token.transferFrom(msg.sender, address(this), amount));

        // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
        // to do except revert the transaction.
       // if (newBid <= highestBindingBid) throw;
         require(newBid > highestBindingBid);

        // grab the previous highest bid (before updating bids, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint highestBid = bids[highestBidder];

        bids[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you've already bid.

            highestBindingBid = min(newBid, highestBid);
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn't increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid);
            }
            highestBid = newBid;
        }
        // mapping(address => uint256) public bids;
        // bids[msg.sender] = 
        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }

    function min(uint a, uint b)
        private
        view
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

    function cancelAuction()
        external
        onlyOwner
        notAfterEnd//onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }

    function resolve() external {
      
      require(block.timestamp >= endTime);

      uint256 _bal = token.balanceOf(address(this));
      if (highestBidder == address(0)) {
          require(token.transfer(owner, _bal));
      } else {
          // transfer tokens to high bidder
          require(token.transfer(highestBidder, _bal));

          balanceOf[owner] += balanceOf[highestBidder];
          balanceOf[highestBidder] = 0;

         // highBidder = 0;
      }
  }


    function withdraw()
        external
        onlyEndedOrCanceled
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = bids[withdrawalAccount];

        } else {
            // the auction finished without being canceled

            if (msg.sender == owner) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = bids[highestBidder];
                } else {
                    withdrawalAmount = bids[highestBidder] - highestBindingBid;
                }

            } else {
                // anyone who participated but did not win the auction should be allowed to withdraw
                // the full amount of their funds
                withdrawalAccount = msg.sender;
                withdrawalAmount = bids[withdrawalAccount];
            }
        }

        // if (withdrawalAmount == 0) throw;
        require(withdrawalAmount != 0);

        bids[withdrawalAccount] -= withdrawalAmount;

        // send the funds
       // if (!msg.sender.send(withdrawalAmount)) throw;
        require(payable(msg.sender).send(withdrawalAmount));

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }

   
}

