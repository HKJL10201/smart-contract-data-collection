pragma solidity ^0.4.11;
contract DutchAuction {


    //TODO: place your code here
    uint _startTime;
    uint _initialPrice;
    uint _offerPriceDecrement;
    address _winningBidder = 0x0000;
    uint _winningBid = 0;
    uint _biddingPeriod = 0;
    // constructor
    function DutchAuction(uint256 initialPrice,
                          uint256 biddingPeriod,
                          uint256 offerPriceDecrement,
                          bool testMode) {

        _testMode = testMode;
        _creator = msg.sender;

        //TODO: place your code here
        _startTime = getBlockNumber();
        _initialPrice = initialPrice;
        _offerPriceDecrement = offerPriceDecrement;
        _biddingPeriod = biddingPeriod;
    }

    // Return the current price of the listing.
    // This should return 0 if bidding is not open or the auction has been won.
    function currentPrice() constant returns(uint currentPrice) {
        //TODO: place your code here
        uint duration = getBlockNumber() - _startTime;
        if (biddingOpen())
            return _initialPrice - (duration * _offerPriceDecrement);
        else
            return 0;
    }

    // Return true if bidding is open.
    // If the auction has been won, should return false.
    function biddingOpen() constant returns(bool isOpen) {
        //TODO: place your code here
        uint duration = getBlockNumber() - _startTime;
        if (_winningBid != 0)
            return false;
        return (duration >= 0 && duration < _biddingPeriod);
    }

    // Return the winning bidder, if the auction has been won.
    // Otherwise should return 0.
    function getWinningBidder() constant returns(address winningBidder) {
        //TODO: place your code here
        return _winningBidder;
    }


    function bid() payable returns(address winningBidder) {
        //TODO: place your code here
        if (biddingOpen())
        {
            if (msg.value < currentPrice()) throw;
            _winningBidder = msg.sender;
            _winningBid = msg.value;
            return _winningBidder;
        }
        msg.sender.transfer(msg.value);
        throw;

    }


    function finalize() creatorOnly{
        //TODO: place your code here
        if (biddingOpen()) throw;
        //msg.sender.send(_winningBid);
        msg.sender.send(_winningBid);
        selfdestruct(_creator);

    }

    // No need to change any code below here

    uint256 _testTime;
    bool _testMode = false;
    address _creator;

    modifier creatorOnly {
            require(msg.sender == _creator);
        _;
    }

    modifier testOnly {
        require(_testMode);
        _;
    }

    function overrideTime(uint time) creatorOnly testOnly{
        _testTime = time;
    }

    function clearTime() creatorOnly testOnly{
        _testTime = 0;
    }

    function getBlockNumber() internal returns (uint) {
        if (_testTime != 0){
            return _testTime;
        }
        return block.number;
    }

}

//Testing code. You don't need to modify this code (but you may for debugging)
contract DutchAuctionTestBidder {

    DutchAuction _target;

    function DutchAuctionTestBidder(DutchAuction target) payable {
        _target = target;
    }

    //Payable function
    function () payable {

    }

    function doBid() payable returns (address){
        return _target.bid.value(200)();
    }
}

contract DutchAuctionTest {

    event FailedExceptionTest(string test);
    event FailedBiddingTest(string test);

    //Use these as needed to debug
    event LogNum(string s, uint num);
    event LogBool(string s, bool b);
    event LogAddress(string s, address a);
    event LogString(string s);

    function DutchAuctionTest() payable {
        if (msg.value <= 200) throw; // Need to create this contract with money
    }


    event FailedPriceTest(string test, int block, uint expected, uint got);

    function testPrice(DutchAuction auction, uint startTime, int block, uint price) returns (uint result){

        auction.overrideTime(uint(int(startTime) + block));
        if (auction.currentPrice() != price) {
            FailedPriceTest("Price calculated incorrectly (block, expected, got)", block, price, auction.currentPrice());
            result += 1;
        }
        auction.clearTime();
        return result;
    }

    event FailedOpenTest(string test, int block);
    function testAuctionOpen(DutchAuction auction, uint startTime, int block, bool expected) returns (uint result){

        auction.overrideTime(uint(int(startTime) + block));
        if (expected && !auction.biddingOpen()) {
            FailedOpenTest("Auction should be open but isn't (block:)", block);
            result += 1;
        }
        else if (!expected && auction.biddingOpen()) {
            FailedOpenTest("Auction shouldn't be open but is (block:)", block);
            result += 1;
        }
        auction.clearTime();
        return result;
    }


    event LogNumFailures(string test, uint num);
    function testDutchAuction() payable returns(string) {


        DutchAuction auction = new DutchAuction(200, 8, 20, true);
        address auctionAddress = address(auction);
        uint startTime = block.number;
        uint failedTests = 0;

        failedTests += testPrice(auction, startTime, 0, 200);
        failedTests += testPrice(auction, startTime, 1, 180);
        failedTests += testPrice(auction, startTime, 5, 100);
        failedTests += testPrice(auction, startTime, 7, 60);
        failedTests += testPrice(auction, startTime, 8, 0);

        failedTests += testAuctionOpen(auction, startTime, 0, true);
        failedTests += testAuctionOpen(auction, startTime, 3, true);
        failedTests += testAuctionOpen(auction, startTime, 7, true);
        failedTests += testAuctionOpen(auction, startTime, 8, false);
        failedTests += testAuctionOpen(auction, startTime, 155, false);
        failedTests += testAuctionOpen(auction, startTime, -1, false);

        if (auctionAddress.call.gas(50000).value(100)(bytes4 (keccak256("bid()"))) != false)
        {
            FailedExceptionTest("low bid() should throw an exception");
            failedTests++;
        }

            if (auctionAddress.call.gas(50000)(bytes4 (keccak256("finalize()"))) != false){
            FailedExceptionTest("early finalize() should throw an exception");
            failedTests++;
        }

        uint initialBalance = this.balance;
        DutchAuctionTestBidder bidder = new DutchAuctionTestBidder(auction);
        auction.overrideTime(uint(int(startTime) + 4));
        bidder.send(200);
        address winner = bidder.doBid();

        if (winner != address(bidder)){
            FailedBiddingTest("Auction should report bidder as winner");
            failedTests++;
        }

        if(auction.biddingOpen()){
            FailedOpenTest("Auction shouldn't be open after winning bid but is (block:)", 4);
            failedTests++;
        }

        if(bidder.balance != 80){
        {
            FailedBiddingTest("Bidder should receive surplus of 80 back, bidder balance is ");
            failedTests++;
        }

            if (auctionAddress.call.gas(50000).value(200)(bytes4 (keccak256("bid()"))) != false)
        {
            FailedExceptionTest("High bid should fail after winning bid");
            failedTests++;
        }

        auction.finalize();

        if(this.balance != initialBalance - 80){
            FailedBiddingTest("Creator should receive funds after finalize()");
            failedTests++;
        }


        if (failedTests == 0){
            return "All tests pased :-)";
        }

        LogNumFailures("Number of failed tests:", failedTests);
        return "Some tests failed. Check the log";
        }
    }
}
