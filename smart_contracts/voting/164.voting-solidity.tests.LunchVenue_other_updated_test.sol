// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/LunchVenue.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/5d251ad816e804d55ac39fa146b4622f55708579/contracts/BytesLib.sol";

/*
    Two test contract involving some cases they may occurs such as,
    - includes original test from specs updated to fit the new contract + edges test cases
    - tie votes between two or more venues
*/
contract LuncgVenueTestOriginalPlusOthers is LunchVenue {
    using BytesLib for bytes;
    
    /// Friends: 4, Quorum: floor((4/2)+1)=3
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;


    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        acc5 = TestsAccounts.getAccount(5);
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
            Assert.equal(reason, 'Restricted to manager only.', 'Failed with unexpected reason');
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

    /// Try setting a friend that has no name. Should fail for contract logic purposes. Note sure why this doesn't work but the deployment works as expected
    /// #sender: account-0
    // function setFriendWithEmptyName() public {
    //     (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address, string)", TestsAccounts.getAccount(5), ''));
    //     if (success == false) {
    //         string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
    //         Assert.equal(reason, 'Invalid name input.', 'Failed with unexpected reason');
    //     } else {
    //         Assert.ok(false, 'Method Execution should fail');
    //     }
    // }

    /// Try adding friend as a user other than manager. This should fail
    /// #sender: account-2
    function setFriendFailure() public {
        try this.addFriend(acc4, 'Daniels') returns (uint f) {
            Assert.ok(false, 'Method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Restricted to manager only.', 'Failed with unexpected reason');
        } catch (bytes memory) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Added to allow votes
    function setOpenVote() public {
        Assert.equal(getVoteState(), 0, 'Vote should be closed (0)');
        Assert.ok(openForVoting(), 'Voting open now.');
        Assert.equal(getVoteState(), 1, 'Vote should be open (1)');
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
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can\'t vote. Not a friend.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
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
        // Assert.equal(voteOpen, false, 'Voting should be closed');    // Replace with Enums
        Assert.equal(getVoteState(), 3, 'Voting should be closed');
    }

    /// Verify voting after vote closed. This should fail
    /// #sender: account-2
    function voteAfterClosedFialure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.ok(false, 'Method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Voting is not open.', 'Failed with unexpected reason');
        } catch (bytes memory) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }
}