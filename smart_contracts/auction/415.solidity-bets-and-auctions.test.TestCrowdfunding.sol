// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestFramework.sol";


contract TestCrowdfunding {

    event PrintEvent(string msg);

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 100000000 wei;

    uint256 constant public investorInitialBalance = 10000 wei;

    MockTimer private timer;
    Crowdfunding private crowdfunding;

    FounderCrowdfunding private CrowdfundingCreator;
    Investor private alice;
    Investor private bob;

    //can receive money
    receive() external payable {}

    fallback() external payable {}

    constructor() {}

    function setupContracts() public {
        timer = new MockTimer(0);
        CrowdfundingCreator = new FounderCrowdfunding();
        crowdfunding = new Crowdfunding(
            address(CrowdfundingCreator),
            timer,
            1000 wei, // 1000 wei
            10        // at day 10
        );
        CrowdfundingCreator.setCrowdfunding(crowdfunding);

        bob = createInvestor(crowdfunding);
        alice = createInvestor(crowdfunding);
    }

    function createInvestor(Crowdfunding _crowdfunding) internal returns (Investor) {
        Investor investor = new Investor(_crowdfunding);
        payable(investor).transfer(investorInitialBalance);
        return investor;
    }

    modifier setup {
        setupContracts();
        _;
    }

    function testCreateCrowdfundingContracts() public{}

    // Investments tests

    function testInvest() public setup {
        timer.setTime(2); // Still not finished
        Assert.isTrue(bob.invest(100 wei), "Valid investment should pass.");
        Assert.isTrue(address(bob).balance == investorInitialBalance - 100 wei, "Investor balance should be reduced by investment value.");
        Assert.isTrue(crowdfunding.investments(address(bob)) == 100 wei, "All investments should be there");
    }

    function testInvestAfterEnd() public setup {
        timer.setTime(20); // Finished
        Assert.isFalse(bob.invest(100 wei), "Investment should not be made after crowdfunding has finished.");
        Assert.isTrue(address(bob).balance == investorInitialBalance, "Investor should have all of its funds.");
    }

    function testInvestMultipleTimes() public setup {
        bob.invest(100 wei);
        bob.invest(100 wei);
        bob.invest(100 wei);
        Assert.isTrue(address(bob).balance == investorInitialBalance - 300 wei, "Investor should be able to invest multiple times.");
        Assert.isTrue(crowdfunding.investments(address(bob)) == 300 wei, "All investments should be there");
    }

    // Claim tests

    function testClaimWhenGoalNotReachedAndNotFinished() public setup {
        timer.setTime(2); // Still not finished
        require(bob.invest(100 wei), "Investor must be able to invest");
        require(alice.invest(100 wei), "Investor must be able to invest");
        Assert.isFalse(CrowdfundingCreator.claimFunds(), "Investments claim should not be able before campaign is active.");
        Assert.isTrue(address(CrowdfundingCreator).balance == 0, "No investments should be claimed.");
    }

    function testClaimWhenGoalNotReachedAndFinished() public setup { // Claim not possible
        require(bob.invest(100 wei), "Investor must be able to invest");
        require(alice.invest(100 wei), "Investor must be able to invest");
        timer.setTime(20); // Finished
        Assert.isFalse(CrowdfundingCreator.claimFunds(), "Can not claim funds when goal not reached.");
        Assert.isTrue(address(CrowdfundingCreator).balance == 0, "No investments should be claimed.");
    }

    function testNonOwnerClaimWhenGoalReachedAndFinished() public setup { // Claim not possible
        require(bob.invest(500 wei));
        require(alice.invest(500 wei)); // Goal Reached
        timer.setTime(20);              // Finished
        Assert.isFalse(bob.claimFunds(), "Non Owner can not claim funds.");
        Assert.isTrue(address(bob).balance == investorInitialBalance - 500 wei, "Funds should not be claimed.");
        Assert.isTrue(address(crowdfunding).balance == 1000 wei, "Funds should not be claimed.");
    }

    function testClaimWhenGoalReachedAndNotFinished() public setup { // Claim not possible
        require(bob.invest(500 wei));
        require(alice.invest(500 wei)); // Goal Reached
        timer.setTime(5);               // Finished
        Assert.isFalse(CrowdfundingCreator.claimFunds(), "Investments claim should not be able before campaign is active.");
        Assert.isTrue(address(CrowdfundingCreator).balance == 0, "No investments should be claimed.");
    }

    function testClaimWhenGoalReachedAndFinished() public setup { // Claim possible
        require(bob.invest(500 wei));
        require(alice.invest(500 wei)); // Goal Reached
        timer.setTime(20);              // Finished
        Assert.isTrue(CrowdfundingCreator.claimFunds(), "Crowdfunding creator should be able to claim funds.");
        Assert.isTrue(address(CrowdfundingCreator).balance == 1000, "Funds should be claimed");
        Assert.isTrue(address(crowdfunding).balance == 0, "No funds should be a part of crowdfunding after they were claimed.");
    }

    // Refund tests

    function testRefundGoalNotReachedAndNotFinished() public setup { // Refund not possible
        timer.setTime(2); // Still not finished
        Assert.isTrue(bob.invest(100 wei), "Investor must be able to invest.");
        Assert.isFalse(bob.refund(), "Investor should not be able to refund before campaign finish.");
        Assert.isTrue(address(bob).balance == investorInitialBalance - 100 wei, "Investor shouldn't be able to get refund.");
    }

    function testRefundWhenGoalReachedButNotFinished() public setup { // Refund not possible
        bob.invest(500 wei);
        alice.invest(500 wei);
        timer.setTime(5);         // Not yet finished
        Assert.isFalse(bob.refund(), "Investor should not be able to refund before campaign finish and goal reached.");
        Assert.isTrue(address(bob).balance == investorInitialBalance - 500 wei, "Investor shouldn't be able to get refund.");
        Assert.isFalse(alice.refund(), "Investor should not be able to refund before campaign finish and goal reached.");
        Assert.isTrue(address(alice).balance == investorInitialBalance - 500 wei, "Investor shouldn't be able to get refund.");
    }

    function testRefundWhenGoalNotReachedButFinished() public setup { // Refund possible
        bob.invest(500 wei); // Goal not reached
        timer.setTime(20);    // Not yet finished
        Assert.isTrue(bob.refund(), "Investor must be able to refund if goal not reached.");
        Assert.isTrue(address(bob).balance == investorInitialBalance, "Investor should be refunded.");
    }

    function testRefundWhenGoalReachedAndFinished() public setup { // Refund not possible
        bob.invest(500 wei);
        alice.invest(500 wei);
        timer.setTime(20); // Passed
        Assert.isFalse(bob.refund(), "Investor should not be able to refund before campaign finish and goal reached.");
        Assert.isTrue(address(bob).balance == investorInitialBalance - 500 wei, "Investor shouldn't be able to get refund.");
        Assert.isFalse(alice.refund(), "Investor should not be able to refund before campaign finish and goal reached.");
        Assert.isTrue(address(alice).balance == investorInitialBalance - 500 wei, "Investor shouldn't be able to get refund.");
    }
}