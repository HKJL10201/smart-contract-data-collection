// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/LunchVenue.sol";

contract LuncgVenueTest is LunchVenue {
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Account at zero index (account-0) is default account, so manager will be set to acc0
    function managerTest() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }

    /// Add lunch venue as manager
    /// When msg.sender isn’t specified , default account (i.e., account-0) is considered as the sender
    function setLunchVenue() public {
        Assert.equal(addVenue('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addVenue('Uni Cafe'), 2, 'Should be equal to 2');
    }

    /// Try to add lunch venue as a user other than manager. This should fail
    /// #sender: account-1
    function setLunchVenueFailure() public {
        try this.addVenue('Atomic Cafe') returns (uint v) {
            Assert.ok(false, 'Method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch (bytes memory) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }

    /// Try adding friend as a user other than manager. This should fail
    /// #sender: account -2
    function setFriendFailure() public {
        try this.addFriend(acc4, 'Daniels') returns (uint f) {
            Assert.ok(false, 'Method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch (bytes memory) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    /// Vote as Bob (acc1)
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), 'Voting result should be true');
    }

    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), 'Voting result should be true');
    }

    /// Try voting as a user not in the friends list. This should fail
    /// #sender: account-4
    function voteFailure() public {
        Assert.equal(doVote(1), false, 'Voting result should be false');
    }

    /// Vote as Eve
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), 'Voting result should be true');
    }

    function lunchVenueTest() public {
        Assert.equal(votedVenue, 'Uni Cafe', 'Selected venue should be Uni Cafe');
    }

    function voteOpenTest() public {
        Assert.equal(voteOpen, false, 'Voting should be closed');
    }

    /// Verify voting after vote closed. This should fail
    /// #sender: account-2
    function voteAfterClosedFialure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.ok(false, 'Method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Can vote only while voting is open', 'Failed with unexpected reason');
        } catch (bytes memory) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }


}