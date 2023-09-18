// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "../lib/ds-test/src/test.sol";
import "./CurveBribe.sol";

contract CurveBribeTest is DSTest {
    
    address constant BRIBE_V2 = 0x7893bbb46613d7a4FbcC31Dab4C9b823FfeE1026;
    address constant MIM_GAUGE = 0xd8b712d29381748dB89c36BCa0138d7c75866ddF;
    address constant SPELL = 0x090185f2135308BaD17527004364eBcC2D37e5F6;
    uint256 constant AMOUNT_PER_VOTE = 1000000*10**18;

    Bribe bribe;
    IERC20 spell;

    function setUp() public {
        bribe = new Bribe(SPELL, AMOUNT_PER_VOTE, MIM_GAUGE);
        spell = IERC20(SPELL);
    }

    // Should test if it is possible to deposit 'amount' in the contract.
    function test_depositIncentive() public {
        uint256 amount = 2000000*10**18;
        uint256 preBalance = spell.balanceOf(address(bribe));
        spell.approve(address(bribe), amount);
        bribe.depositIncentive(amount);
        uint256 postBalance = spell.balanceOf(address(bribe));
        assertEq(preBalance + amount, postBalance);
    }

    // Should test if it is possible to deposit 'amount' in the contract and fail since 'amount' is less than 'amountPerVote'.
    function testFail_depositIncentive_deposit_less() public {
        uint256 amount = 500000*10**18;
        spell.approve(address(bribe), amount);
        bribe.depositIncentive(amount);
    }

     // Should test if the depositor is refunded as intended when the 'amount' deposited is superior to but not a multiple of 'amountPerVote'. 
    function test_depositIncentve_refund() public {
        uint256 amount = 1300000*10**18;
        uint256 expectedRefund = amount % AMOUNT_PER_VOTE;
        spell.approve(address(bribe), amount);
        bribe.depositIncentive(amount);
        uint256 balance = spell.balanceOf(address(bribe));
        assertEq(balance, amount - expectedRefund);
    }

    // Should test if it is possible to incentivize targetGauge by asserting that the balances of bribe and BRIBE_V2 are correct.
    function test_incentivizeGauge() public {
        uint256 amount = 2000000*10**18;
        spell.approve(address(bribe), amount);
        bribe.depositIncentive(amount);
        uint256 preBalanceBribe = spell.balanceOf(address(bribe));
        uint256 preBalanceCRVBribeV2 = spell.balanceOf(BRIBE_V2);
        bribe.incentivizeGauge();
        uint256 postBalanceBribe = spell.balanceOf(address(bribe));
        uint256 postBalanceCRVBribeV2 = spell.balanceOf(BRIBE_V2);
        assertEq(preBalanceBribe - AMOUNT_PER_VOTE, postBalanceBribe);
        assertEq(preBalanceCRVBribeV2 + AMOUNT_PER_VOTE, postBalanceCRVBribeV2);
    }
    
    // Should test if it is possible to call incentivizeGauge() more than once a week and fail since called before a WEEK has passed.
    function testFail_incentivizeGauge() public {
        for (uint i=0; i<2; i++) {
            bribe.incentivizeGauge();
        }
    }
}
