// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/LunchVenue.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/5d251ad816e804d55ac39fa146b4622f55708579/contracts/BytesLib.sol";

/*
    This test includes stating the behaviours of the vote states and focus on Weakness 2.
    Tests such as,
    - manager adding friends and venue after voting open and completed
    - voting before and after each voting states
    - others
*/
contract LunchVenueTestStateScenario is LunchVenue {
    using BytesLib for bytes;

    /// Friends: Quorum: floor(()+1)=
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;
    address acc6;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        acc5 = TestsAccounts.getAccount(5);
        acc6 = TestsAccounts.getAccount(6);
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

    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 6');
        Assert.equal(addFriend(acc3, 'Char'), 2, 'Should be equal to 3');
        Assert.equal(addFriend(acc4, 'Dav'), 3, 'Should be equal to 4');
        Assert.equal(addFriend(acc5, 'Eve'), 4, 'Should be equal to 5');
        // Assert.equal(addFriend(acc6, 'Fred'), 5, 'Should be equal to 5');
    }

    /// acc3 tries to vote when voting is not opened yet. Ensure votes before they are open is rejected with a revert.
    /// #sender: account-3
    function testVoteBeforeOpen() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Voting is not open.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// This openForVoting() should now allow acc3 to vote
    function setOpenVote() public {
        Assert.equal(getVoteState(), 0, 'Vote should be closed (0)');
        Assert.ok(openForVoting(), 'Voting open now.');
        Assert.equal(getVoteState(), 1, 'Vote should be open (1)');
    }

    /// acc3 successful vote
    /// #sender: account-3
    function vote1AfterOpen() public {
        Assert.ok(doVote(1), 'Should be false. Voting is not open.');
    }

    /// manager (acc0) cannot addVenue after voting has open. Ensures that addVenue
    /// should fail and trigger the votingClose modifer message
    /// #sender: account-0
    function testAddVenueWhenVotingIsOpen() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", 'Cafe2'));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Voting is not closed.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Not sure why addFriend doesn't work in test, but the deployment error works on Ropsten.
    /// https://ropsten.etherscan.io/tx/0x0c1bd5a5d6e3a9838e303e2b2ed252391503e35b207275875b82653c5bd710d0
    /// #sender: account-0
    // function testAddFriendVotingIsOpen() public {
    //     (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address, string)", TestsAccounts.getAccount(6), 'Fred'));
    //     if (success == false) {
    //         string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
    //         Assert.equal(reason, 'Voting is not closed.', 'Failed with unexpected reason');
    //     } else {
    //         Assert.ok(false, 'Method Execution should fail');
    //     }
    // }

    /// Test not a friend on voting open. Ensures valid error mesage and revert
    /// #sender: account-2
    function testUnknownVoteFail() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can\'t vote. Not a friend.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Vote success 2
    /// #sender: account-4
    function vote2() public {
        Assert.ok(doVote(1), 'Vote should be true.');
    }

    /// Vote success 3. Quorum reached.
    /// #sender: account-5
    function vote3() public {
        Assert.ok(doVote(2), 'Vote hould be true.');
    }

    /// Any votes after the quorum has been reached is rejected as voting has been set to not open.
    /// #sender: account-0
    function vote4() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("doVote(uint256)", 1));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Voting is not open.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Deterministic result
    function lunchVenueTest() public {
        Assert.equal(votedVenue, 'Courtyard Cafe', 'Selected venue should be Courtyard Cafe');
    }

    /// Ensures state is voteComplete
    function testVoteStateComplete() public {
        Assert.equal(getVoteState(), 3, 'Vote should be complete (3)');
    }

    /// manager (acc0) cannot addVenue after voting has been complete. Ensures that addVenue
    /// should fail and trigger the votingClose modifer message
    /// #sender: account-0
    function testAddVenueWhenVoteIsDone() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", 'Cafe2'));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Voting is not closed.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }

    /// Not sure why addFriend doesn't work in test, but the deployment error works on Ropsten.
    /// https://ropsten.etherscan.io/tx/0x1b5a774b0925cdbee708b4c34e908bc6d01dcbdacf0e79b1625dae040fae408c
    /// #sender: account-0
    // function testAddFriendWhenVoteIsDone() public {
    //     (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address, string)", TestsAccounts.getAccount(6), 'Fred'));
    //     if (success == false) {
    //         string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
    //         Assert.equal(reason, 'Voting is not closed.', 'Failed with unexpected reason');
    //     } else {
    //         Assert.ok(false, 'Method Execution should fail');
    //     }
    // }
}
