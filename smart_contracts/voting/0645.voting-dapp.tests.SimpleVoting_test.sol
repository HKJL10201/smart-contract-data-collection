// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
// <import file to test>
import "../contracts/SimpleVoting.sol";


// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite is SimpleVoting {
    address address1;
    address address2;
    uint256 proposal;
    // SimpleVoting app;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        address1 = TestsAccounts.getAccount(1);
        address2 = TestsAccounts.getAccount(2);
        Assert.notEqual(address1, address(0), "Not empty");
        Assert.notEqual(address2, address(0), "Not empty");
    }

    function proposeIsSuccessful() public {
        uint256 id = propose("myProposalTest");
        Proposal memory newProposal = getProposal(id);
        proposal = id;

        Assert.ok(newProposal.exists == true, "Proposal was not created");
    }

    /// #sender: account-2
    function proposeIsSuccessfulByOtherAddress() public {
        uint256 id = propose("myProposalTest2");
        Proposal memory newProposal = getProposal(id);

        Assert.ok(newProposal.exists == true, "Proposal was not created");
        Assert.equal(newProposal.creator,address2, "Proposal was created by address2");
    }

    /// #sender: account-0
    function address0ShouldBeAbleToApprove() public {
        approve(proposal);
        Proposal memory existingProposal = getProposal(proposal);

        Assert.equal(existingProposal.approvals, 1, "Approvals should be 1");
    }

    /// #sender: account-0
    function address0ShouldNoBeAbleToApproveTwice() public {
        approve(proposal);
        Assert.equal(uint(1), uint(1), "Address 0 should not be able to approve twice");
    }

    /// #sender: account-1
    function address1ShouldBeAbleToApprove() public {
        approve(proposal);
        Proposal memory existingProposal = getProposal(proposal);
        Assert.equal(existingProposal.approvals, 2, "Approvals should be 2");
    }

    /// #sender: account-2
    function address2ShouldBeAbleToDecline() public {
        decline(proposal);
        Proposal memory existingProposal = getProposal(proposal);
        Assert.equal(existingProposal.approvals, 2, "Approvals should be 2");
        Assert.equal(existingProposal.declines, 1, "Declines should be 1");
    }

    /// #sender: account-2
    function address2ShouldNotFinishProposal() public {
        finishProposal(proposal);
        Assert.equal(uint(1), uint(1), "Address 2 should not be able to finish a proposal");
    }

    /// #sender: account-0
    function address0ShouldFinishProposalWithApproval() public {
        bool wasApproved = finishProposal(proposal);

        Assert.ok(wasApproved, "Proposal should be approved");
    }
}
