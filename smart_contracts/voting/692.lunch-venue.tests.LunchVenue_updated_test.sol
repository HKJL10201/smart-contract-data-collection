// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/LunchVenue_updated.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol";

/// ------------------------ EXTENSION 1 ------------------------
/// Test extension 1 works as expected.
/// acc1 attempts to vote more than once. Their second vote should not be counted.
///
/// *This test also tests general functionality as seen in /tests/LunchVenue_test.sol*
///     This includes:
///         - Checking manager is correctly set.
///         - Setting lunch venue as a user other than manager.
///         - Adding friends as a user other than manager.
///         - Voting as a user not in the friends list.
/// -------------------------------------------------------------
contract LunchVenueTestExt1 is LunchVenue {
    using BytesLib for bytes;

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Account at zero index (account-0) is the default account, so manager will be set to acc0
    function managerTest() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }

    /// Add lunch venue as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is considered as the sender
    function setLunchVenue() public {
        Assert.equal(addVenue('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addVenue('Uni Cafe'), 2, 'Should be equal to 2');
    }

    /// Try to add lunch venue as a user other than manager. This should fail
    /// #sender: account-1
    function setLunchVenueFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", "Atomic Cafe"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Set friends as account-0
    /// #sender doesn't need to be specified explicitly for account-0
    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }

    /// Try adding friend as a user other than manager. This should fail
    /// #sender: account-2
    function setFriendFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address,string)", acc4, "Daniels"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Start voting
    /// Test that state transitions correctly
    function startVotingStage() public {
        Assert.equal(uint(state), uint(State.Planning), "State should be Planning");
        startVoting();
        Assert.equal(uint(state), uint(State.Voting), "State should be Voting");
    }

    /// Vote as Bob (acc1)
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    // ------------------------ EXTENSION 1 ------------------------
    // acc1 attempts to vote more than once. Their second vote should not be counted.
    // -------------------------------------------------------------
    /// Vote as Bob again (acc1)
    /// #sender: account-1
    function voteAgainFailure() public {
        Assert.equal(doVote(2), false, "acc-1 should not be allowed to vote twice");
        Assert.equal(numVotes, 1, "There should be 1 vote");
    }

    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), "Voting result should be true");
    }

    /// Try voting as a user not in the friends list. This should fail
    /// #sender: account-4
    function voteFailure() public {
        Assert.equal(doVote(1), false, "Voting result should be false");
    }

    /// Vote as Eve
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Verify lunch venue is set correctly
    function lunchVenueTest() public {
        Assert.equal(votedVenue, 'Uni Cafe', 'Selected venue should be Uni Cafe');
    }

    /// Verify voting is now closed
    function voteOpenTest() public {
        Assert.equal(uint(state), uint(State.Finished), 'Voting should be closed');
    }

    /// Verify voting after vote closed. This should fail
    /// #sender: account-2
    function voteAfterClosedFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Finished state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }
}


/// ------------------------ EXTENSION 2 ------------------------
/// Test extension 2 works as expected.
/// Check that functions can only be called in certain states.
/// -------------------------------------------------------------
contract LunchVenueTestExt2 is LunchVenue {
    using BytesLib for bytes;

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Verify initial state.
    // -------------------------------------------------------------
    /// Check initial state is `Planning`
    function testInitialState() public {
        Assert.equal(uint(state), uint(State.Planning), "Initial state should be Planning");
    }

    /// Add lunch venue as manager
    function setLunchVenue() public {
        Assert.equal(addVenue('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addVenue('Uni Cafe'), 2, 'Should be equal to 2');
    }

    /// Set friends as account-0
    /// #sender doesn't need to be specified explicitly for account-0
    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Voting` action in `Planning` phase.
    // -------------------------------------------------------------
    /// Attempt to vote before Voting phase
    /// #sender: account-1
    function voteBeforeVotingStage() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Planning state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Voting` action in `Planning` phase.
    // -------------------------------------------------------------
    /// Attempt to modify timeout before Voting phase using `setTimeout`
    /// Timeout only comes into effect once Voting begins
    function changeTimeoutBeforeVoting() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("setTimeout(uint256)", block.number + 500));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Planning state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Voting` action in `Planning` phase.
    // -------------------------------------------------------------
    /// Attempt to modify timeout before Voting phase using `extendTimeout`
    /// Timeout only comes into effect once Voting begins
    function changeTimeoutBeforeVoting2() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("extendTimeout(uint256)", 500));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Planning state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Voting` action in `Planning` phase.
    // -------------------------------------------------------------
    /// Attempt to modify timeout before Voting phase using `reduceTimeout`
    /// Timeout only comes into effect once Voting begins
    function changeTimeoutBeforeVoting3() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("reduceTimeout(uint256)", 5));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Planning state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Check only manager can `startVoting()`.
    // -------------------------------------------------------------
    /// Attempt to start voting as a user other than manager
    /// #sender: account-1
    function startVotingStageFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("startVoting()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Check `startVoting()` transitions state from `Planning` to `Voting`.
    // -------------------------------------------------------------
    /// Start voting
    /// Test that state transitions correctly
    function startVotingStage() public {
        Assert.equal(uint(state), uint(State.Planning), "State should be Planning");
        startVoting();
        Assert.equal(uint(state), uint(State.Voting), "State should be Voting");
    }

    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Planning` action in `Voting` phase.
    // -------------------------------------------------------------
    /// Attempt to add a venue in the Voting state
    function addVenueWhenVoting() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", "My Cafe"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Voting state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Planning` action in `Voting` phase.
    // -------------------------------------------------------------
    /// Attempt to add a friend in the Voting state
    function addFriendWhenVoting() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address,string)", acc4, "My Cafe"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Voting state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Vote as Bob (acc1)
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), "Voting result should be true");
    }

    /// Vote as Eve
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    // ------------------------ EXTENSION 2 ------------------------
    // Verify automatic transition to `Finished` state.
    // -------------------------------------------------------------
    /// Check that the quorum has been met and we are now in `Finished` state
    function testFinishedState() public {
        Assert.equal(uint(state), uint(State.Finished), "Voting should be Finished");
    }

    /// Verify lunch venue is set correctly
    function lunchVenueTest() public {
        Assert.equal(votedVenue, 'Uni Cafe', 'Selected venue should be Uni Cafe');
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Planning` action in `Finished` phase.
    // -------------------------------------------------------------
    /// Attempt to add a venue in the Finished state
    function addVenueWhenFinished() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", "My Cafe"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Finished state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Planning` action in `Finished` phase.
    // -------------------------------------------------------------
    /// Attempt to add a friend in the Finished state
    function addFriendWhenFinished() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address,string)", acc4, "John"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Finished state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Voting` action in `Finished` phase.
    // -------------------------------------------------------------
    /// Attempt to vote in the Finished state
    /// account-0 has not yet voted
    /// #sender: account-0
    function doVoteWhenFinished() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Finished state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 2 ------------------------
    // Performing a `Voting` action in `Finished` phase.
    // -------------------------------------------------------------
    /// Attempt to extend timeout in the Finished state
    function extendTimeoutWhenFinished() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("extendTimeout(uint256)", 200));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Finished state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }
}


/// ------------------------ EXTENSION 3 ------------------------
/// Test extension 3 works as expected.
///
/// We test the following:
///     - Setting timeout as a user other than manager.
///     - Setting timeout to a block in the past.
///     - Attempting to change timeout once we have already timed out.
///     - Setting timeouts successfully.
///     - If we timeout with no votes, selected venue should be "<UNDECIDED>".
/// -------------------------------------------------------------
contract LunchVenueTestExt3 is LunchVenue {
    using BytesLib for bytes;

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Add lunch venue as manager
    function setLunchVenue() public {
        Assert.equal(addVenue('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addVenue('Uni Cafe'), 2, 'Should be equal to 2');
    }

    /// Set friends as account-0
    /// #sender doesn't need to be specified explicitly for account-0
    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }

    // ------------------------ EXTENSION 3 ------------------------
    // When we start voting the timeout should be correctly set.
    // -------------------------------------------------------------
    /// Start voting
    /// Test that state transitions correctly
    /// Test that timeout is set correctly
    function startVotingStage() public {
        // ----- EXTENSION 3 -----
        Assert.equal(timeoutBlock, 0, "timeoutBlock should not yet be set");
        uint currBlock = block.number;

        Assert.equal(uint(state), uint(State.Planning), "State should be Planning");
        startVoting();
        Assert.equal(uint(state), uint(State.Voting), "State should be Voting");

        // ----- EXTENSION 3 -----
        Assert.equal(timeoutBlock, currBlock + 280, "timeoutBlock not correctly set");
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Setting timeout to a block in the past.
    // -------------------------------------------------------------
    /// Attempt to set timeout to block 0
    function setTimeoutToPast() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("setTimeout(uint256)", 0));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Timeout block cannot be in the past', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Setting timeout to a block in the past.
    // -------------------------------------------------------------
    /// Attempt to reduce timeout to block 0
    function reduceTimeoutToPast() public {
        uint reduceAmt = timeoutBlock;
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("reduceTimeout(uint256)", reduceAmt));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Timeout block cannot be in the past', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Setting timeout as a user other than manager.
    // -------------------------------------------------------------
    /// Attempt to set timeout as account-1
    /// #sender: account-1
    function changeTimeoutAsNonManagerFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("extendTimeout(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Extending timeout successfully.
    // -------------------------------------------------------------
    /// Extend timeout by 100 blocks
    function extendTimeoutSuccess() public {
        uint expected = timeoutBlock + 100;
        extendTimeout(100);
        Assert.equal(timeoutBlock, expected, "Timeout is not as expected");
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Reducing timeout successfully.
    // -------------------------------------------------------------
    /// Reduce timeout by 1 block
    function reduceTimeoutSuccess() public {
        uint expected = timeoutBlock - 1;
        reduceTimeout(1);
        Assert.equal(timeoutBlock, expected, "Timeout is not as expected");
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Setting timeout successfully.
    // -------------------------------------------------------------
    /// Set timeout to 5 blocks in the future.
    function setTimeoutSuccess() public {
        uint target = block.number + 5;
        setTimeout(target);
        Assert.equal(timeoutBlock, target, "Timeout is not as expected");
    }

    /// Force a timeout
    function forceTimeout() public {
        setTimeout(block.number + 1);
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Changing the timeout once already timed out.
    // -------------------------------------------------------------
    /// Attempt to extend timeout by 100 blocks after timeout
    function extendTimeoutAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("extendTimeout(uint256)", 100));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'We have already timed out', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Changing the timeout once already timed out.
    // -------------------------------------------------------------
    /// Attempt to reduce timeout by 1 block after timeout
    function reduceTimeoutAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("reduceTimeout(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'We have already timed out', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Changing the timeout once already timed out.
    // -------------------------------------------------------------
    /// Attempt to set timeout after timeout
    function setTimeoutAfterTimeout() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("setTimeout(uint256)", block.number + 5));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'We have already timed out', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Voting after timeout.
    // This triggers the state transition to `Finished` and invalidates the vote.
    // -------------------------------------------------------------
    /// Attempt to vote after timeout then check that state is `Finished`
    /// #sender: account-1
    function voteAfterTimeout() public {
        Assert.equal(doVote(1), false, 'Cannot vote after timeout');
        Assert.equal(uint(state), uint(State.Finished), "State should be Finished");
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Voting after timeout.
    // State is now `Finished` so this should revert.
    // -------------------------------------------------------------
    /// Attempt to vote after timeout in Finished state
    /// #sender: account-2
    function voteAfterTimeout2() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Function cannot be called in the Finished state', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Timeout reached with no votes.
    // -------------------------------------------------------------
    /// Verify lunch venue is undecided
    function lunchVenueUndecidedTest() public {
        Assert.equal(votedVenue, '<UNDECIDED>', 'Selected venue should be <UNDECIDED>');
    }
}


/// ------------------------ EXTENSION 4 ------------------------
/// Test extension 4 works as expected.
/// Once contract is cancelled all functions should be disabled.
/// Also the `votedVenue` should be "<CANCELLED>".
/// -------------------------------------------------------------
contract LunchVenueTestExt4 is LunchVenue {
    using BytesLib for bytes;

    // Variables used to emulate different accounts
    address acc0;
    address acc1;

    /// 'beforeAll' runs before all other tests
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
    }

    // ------------------------ EXTENSION 4 ------------------------
    // Cancel contract as a user other than manager.
    // -------------------------------------------------------------
    /// Cancel contract as acc1. This should fail
    /// #sender: account-1
    function cancelLunchFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("disable()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 4 ------------------------
    // Cancel contract and check state is `Cancelled`.
    // -------------------------------------------------------------
    /// Cancel contract
    function cancelLunch() public {
        Assert.equal(uint(state), uint(State.Planning), "State should be Planning");
        disable();
        Assert.equal(uint(state), uint(State.Cancelled), "State should be Cancelled");
    }

    // ------------------------ EXTENSION 3 ------------------------
    // Attempt to call some functions after contract is cancelled.
    // -------------------------------------------------------------
    /// Try and use cancelled contract
    function useCancelledContract() public {
        // add venue
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", "Uni Cafe"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'The contract is disabled and the team lunch has been cancelled', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }

        // add friend
        (success, result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address,string)", acc0, "James"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'The contract is disabled and the team lunch has been cancelled', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }

        // start voting
        (success, result) = address(this).delegatecall(abi.encodeWithSignature("startVoting()"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'The contract is disabled and the team lunch has been cancelled', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }

        // do vote
        (success, result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'The contract is disabled and the team lunch has been cancelled', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    // ------------------------ EXTENSION 4 ------------------------
    // Check `votedVenue` is "<CANCELLED>" after cancelling.
    // -------------------------------------------------------------
    /// Check what the voted venue is
    function checkVotedVenue() public {
        Assert.equal(votedVenue, "<CANCELLED>", "The voted venue should be <CANCELLED>");
    }
}
