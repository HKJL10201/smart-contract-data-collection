pragma solidity >0.4.23 <0.7.0;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended=false;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }
    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _beneficiary //You can use .transfer(..) and .send(..) on address payable
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }
    function bid(bytes32 _blindedBid)
        public
        payable
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }
    //you will only get a refund if your bid can be revealed correctly after the auction.
    //Refunds will be available for all topped bids, as well as invalid bids that were blinded properly:
    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) =
                    (_values[i], _fake[i], _secret[i]);
                    if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                continue;
            }
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) { //check if it is valid bid fake=false and deposited value>=value in blindedBid
                if (placeBid(msg.sender, value))
                    refund = 0; //value will be taken as highestBid
            }
            bidToCheck.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund); // all the fake auctions and lesser auctions are refunded here
    }
    function placeBid(address bidder, uint value) internal //function is internal: that means you can only call it from the contract or others derived from it.
            returns (bool success)
    {
        value=value*1000000000000000000;   
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid; //if there is already a valid highestBidder update its pending returns
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
    //the previous highestBidders(outbid offer) are refunded using withdraw function. This must be called explicitly.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require(amount>0);
        if (amount > 0) { 

            pendingReturns[msg.sender] = 0;

            msg.sender.transfer(amount);
        }
    }
    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        require (beneficiary.send(highestBid));
            
        //beneficiary.transfer(highestBid); //inorder to make sure the transfer take place only one time we set ended=true
    }
    function calculate(uint value,bool fake,bytes32 secret) public pure returns(bytes32)
    {
        bytes32  _blindedBid=keccak256(abi.encodePacked(value, fake, secret));
        return _blindedBid;
       
    }
    function stringTobytes32(string memory _str) public pure returns (bytes32){ 
    bytes memory tempBytes = bytes(_str); 
    bytes32 convertedBytes; 
    if( 0==tempBytes.length){ 
        return 0x0; 
    } 
    assembly { 
        convertedBytes := mload(add(_str, 32)) 
    } 
    return convertedBytes; 
  } 
  function curr_time()public view returns(uint)
  {
      uint time=now;
      return time;
  }
    /*convert strings to byte*/ 
  
}
