// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Voting.sol";

// Mock ERC20 for testing purposes
contract GovCoinMock is IERC20 {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    function mint(address to, uint256 amount) public {
        balances[to] += amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(balances[sender] >= amount, "Not enough balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}

contract GovernanceTest is Test {
    Governance public governance;
    GovCoinMock public govCoinMock;

    function setUp() public {
        govCoinMock = new GovCoinMock();
        governance = new Governance(address(govCoinMock));
    }

    // tests if the proposal has been created correctly
    function testCreateProposal() public {
        uint256 duration = 600; // 10 minutes for example
        governance.createProposal("Test Proposal", duration);

        // Accessing the individual fields of the struct
        (string memory description, uint256 yesVotes, uint256 noVotes, uint256 endTime, bool closed) = governance.proposals(0);

        assertEq(description, "Test Proposal");
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
        assertTrue(endTime > block.timestamp);
        assertFalse(closed);
    }

    function testVoting() public {
        // Setup
        uint256 duration = 600;
        governance.createProposal("Test Proposal", duration);
        uint256 voteAmount = 100;
        govCoinMock.mint(address(this), voteAmount);
        govCoinMock.approve(address(governance), voteAmount);

        // Vote "Yes"
        governance.vote(0, true, voteAmount);
        (string memory description, uint256 yesVotes, uint256 noVotes,  ,  ) = governance.proposals(0);
        
        assertEq(description, "Test Proposal");
        assertEq(yesVotes, voteAmount);
        assertEq(noVotes, 0);
    }

    function testCloseVoting() public {
        // Setup
        uint256 duration = 30;  // Let's assume a very short duration, e.g., 30 seconds, for testing purposes.
        governance.createProposal("Test Close Voting", duration);

        // // Increase the time by more than duration, to ensure the voting period has ended.
        // // Note: The following line assumes you are using a test environment that can manipulate time, like Ganache.
        // hevm.warp(block.timestamp + duration + 1);

        // // Close the voting
        // governance.closeVoting(0);
        // (, , , , bool closed) = governance.proposals(0);
        // assertTrue(closed);  // Assert that the voting is now closed

        // // Try to vote now, it should fail because voting is closed
        // uint256 voteAmount = 100;
        // govCoinMock.mint(address(this), voteAmount);
        // govCoinMock.approve(address(governance), voteAmount);

        // // This vote should revert because the voting is closed
        // try governance.vote(0, true, voteAmount) {
        //     fail("Voting on a closed proposal did not revert");
        // } catch Error(string memory reason) {
        //     assertEq(reason, "Voting is closed for this proposal");
        // }
    }

}
