// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.7.0;

// // This import is automatically injected by Remix
// import "remix_tests.sol"; 

// // This import is required to use custom transaction context
// // Although it may fail compilation in 'Solidity Compiler' plugin
// // But it will work fine in 'Solidity Unit Testing' plugin
// import "remix_accounts.sol";
// import "../Auction.sol";

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Auction.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract AuctionTest is Auction{

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    
    // Define variables referring to different accounts
    address acc0; // by default acc0 is the creator of the contract: account-0
    address acc1;
    address acc2;

    // Define variable to instantiate the Auction contract
    // Auction public auctionToTest;

    function beforeAll() public {
        // Initialize user accounts (0, 1, 2)

        // acc0 = TestsAccounts.getAccount(0); 
        // acc1 = TestsAccounts.getAccount(1);
        // acc2 = TestsAccounts.getAccount(2);
        // Create a new instance of Auction contract
        // auctionToTest = Auction(DeployedAddresses.SimpleStorage());
    }

    function checkInfo() public {
        // Check description
        string memory description = getDescription();
        Assert.equal(description, "En esta subasta se ofrece un coche. Se trata de un Ford Focus de ...", "Invalid description");
    
        // Check basePrice
        uint basePrice = getBasePrice();
        Assert.equal(basePrice, 1 ether, "Invalid base price");
        
        // Check activeContract
        bool active = isActive();
        Assert.equal(active, true, "The contract must be active");
        
        // Check secondsToEnd (????)
        //secondsToEnd = getAuctionInfo();
        //Assert.equal(secondsToEnd, 86400, "Invalid seconds to end");
        
   }
    // 2000000000000000000 wei = 2 ether
    /// #value: 2000000000000000000
    /// #sender: account-1
    function checkBid() public payable{
        // First bid -> 2 ether
        bid();
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");

        // Check new highestPrice
        uint highestPrice = getHighestPrice();
        Assert.equal(highestPrice, 2 ether, "Invalid highest price");
        
        // Check new highestBidder
        address highestBidder = getHighestBidder();
        Assert.ok(highestBidder == acc1, "Invalid highest bidder");
    }

    // 3000000000000000000 wei = 3 ether
    /// #value: 3000000000000000000
    /// #sender: account-2
    function checkSecondBid() public payable{
        // Second bid -> 3 ether
        bid();
        Assert.equal(msg.sender, TestsAccounts.getAccount(2), "Invalid sender");

        // Check new highestPrice
        uint highestPrice = getHighestPrice();
        Assert.equal(highestPrice, 3 ether, "Invalid highest price");
        
        // Check new highestBidder
        address highestBidder = getHighestBidder();
        Assert.ok(highestBidder == acc2, "Invalid highest bidder");
    }

    /// #sender: account-0
    function checkStopAuction() public payable{
        stopAuction();

        // Check auction is not active
        bool active = isActive();
        Assert.notEqual(active, true, "The contract must be paused");

    }
}
