// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "../lib/ds-test/src/test.sol";
import "./VotiumBribe.sol";

contract VotiumBribeTest is DSTest {

    address constant FLX = 0x6243d8CEA23066d098a15582d81a598b4e8391F4;
    uint256 constant AMOUNT_PER_VOTE = 50*10**18;
    
    Incentive incentive;
    IERC20 flx;

    function setUp() public {
        incentive = new Incentive(FLX, AMOUNT_PER_VOTE, address(0x1), 34);
        flx = IERC20(FLX);
    }
    
    // Should test if it is possible to deposit 'amount' in the contract.
    function test_depositIncentive() public {
        uint256 amount = 100*10**18;
        uint256 preBalance = flx.balanceOf(address(incentive));
        flx.approve(address(incentive), amount);
        incentive.depositIncentive(amount);
        uint256 postBalance = flx.balanceOf(address(incentive));
        assertEq(preBalance + amount, postBalance);
    }

    // Should test if it is possible to deposit 'amount' in the contract and fail since depositing less than amountPerVote.
    function testFail_depositIncentive_deposit_less() public {
        uint256 amount = 40*10**18;
        flx.approve(address(incentive), amount);
        incentive.depositIncentive(amount);
    }

    // Should test if the depositor is refunded as intended when the 'amount' deposited is superior to but not a multiple of 'amountPerVote'. 
    function test_depositIncentve_refund() public {
        uint256 amount = 70*10**18;
        uint256 expectedRefund = amount % AMOUNT_PER_VOTE;
        flx.approve(address(incentive), amount);
        incentive.depositIncentive(amount);
        uint256 balance = flx.balanceOf(address(incentive));
        assertEq(balance, amount - expectedRefund);
    }
}
