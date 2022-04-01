// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/LunchVenue.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/5d251ad816e804d55ac39fa146b4622f55708579/contracts/BytesLib.sol";

/*
    This test includes cases of the voting process for votes and looks at Weakness 1. 
    Tests for cases such as,
    - successful votes
    - failure cases votes
    - edge cases votes
*/
contract LunchVenueTestVotingCases is LunchVenue {
    using BytesLib for bytes;

    /// Friends: 6, Quorum: floor((5/2)+1)=3
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

    /// Ensures manager is acc0
    function managerTest() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }

    /// Add Venues Successfully
    function setLunchVenue() public {
        Assert.equal(addVenue('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addVenue('Uni Cafe'), 2, 'Should be equal to 2');
        Assert.equal(addVenue('Central Cafe'), 3, 'Should be equal to 3');
    }

    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
        Assert.equal(addFriend(acc5, 'Fred'), 5, 'Should be equal to 5');
    }

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

    /// Allows voting and checks states have changed from close (0) to open (1)
    function setOpenVote() public {
        Assert.equal(getVoteState(), 0, 'Vote should be closed (0)');
        Assert.ok(openForVoting(), 'Voting open now.');
        Assert.equal(getVoteState(), 1, 'Vote should be open (1)');
    }

    /// Simple vote from acc1
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), 'Voting result should be true');
    }

    /// acc1 trys to votes again with a different venue choice. Ensure that they can't with revert message instead of return false
    /// #sender: account-1
    function voteAgainFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can\'t vote. Already voted.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// acc5 tries to vote for a venue that isn't listed. Ensures a false return
    /// #sender: account-5
    function voteNonExistVenueFailure() public {
        Assert.equal(doVote(100), false, 'Voting result should be false');
    }

    /// Ensures that a vote wasn't add from the failed votes above
    function testCorrectNumVotes() public {
        Assert.equal(numVotes, 1, 'No. votes should be at 2');
    }
    
    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), 'Voting result should be true');
    }

    /// acc2 trys to vote again with the same venue (duplicates their first vote). Should Fail like voteAgainFailure()
    /// #sender: account-2
    function voteSameFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can\'t vote. Already voted.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// acc4 tries to vote isn't though they aren't a friend. Should revert with a valid error message
    /// #sender: account-4
    function voteFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 2));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can\'t vote. Not a friend.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// acc3 who is a friend can vote. Quorum Reached
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), 'Voting result should be true');
    }

    /// Deterministic result
    function lunchVenueTest() public {
        Assert.equal(votedVenue, 'Uni Cafe', 'Selected venue should be Uni Cafe');
    }
}