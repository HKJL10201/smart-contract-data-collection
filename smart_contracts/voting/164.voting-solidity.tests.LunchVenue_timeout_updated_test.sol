// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/LunchVenue.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/5d251ad816e804d55ac39fa146b4622f55708579/contracts/BytesLib.sol";

/*
    IMPORTANT: To run for this case of timeout scenario, need to set in the 
    LunchVenue constructor with the setTimeout(10); This is done to ensure
    the test will have a short timeout period which is catered for this test.
*/
contract LunchVenueTestTimeOut is LunchVenue {
    using BytesLib for bytes;
    
    /// Friends: 10 Quorum: floor((10/2)+1)=6
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;
    address acc6;
    address acc7;
    address acc8;
    address acc9;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        acc5 = TestsAccounts.getAccount(5);
        acc6 = TestsAccounts.getAccount(6);
        acc7 = TestsAccounts.getAccount(7);
        acc8 = TestsAccounts.getAccount(8);
        acc9 = TestsAccounts.getAccount(9);
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
        Assert.equal(addVenue('A Cafe'), 3, 'Should be equal to 3');                
        Assert.equal(addVenue('The Cafe'), 4, 'Should be equal to 4');              
        Assert.equal(addVenue('New Cafe'), 5, 'Should be equal to 5');             
    }          

    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');          
        Assert.equal(addFriend(acc3, 'Char'), 2, 'Should be equal to 2');         
        Assert.equal(addFriend(acc4, 'Dav'), 3, 'Should be equal to 3');          
        Assert.equal(addFriend(acc5, 'Eve'), 4, 'Should be equal to 4');           
        Assert.equal(addFriend(acc6, 'Fred'), 5, 'Should be equal to 5');          
        Assert.equal(addFriend(acc1, 'Bob'), 6, 'Should be equal to 6');          
        Assert.equal(addFriend(acc2, 'Giveon'), 7, 'Should be equal to 7');       
        Assert.equal(addFriend(acc7, 'Happy'), 8, 'Should be equal to 8');  
        Assert.equal(addFriend(acc8, 'Itzy'), 9, 'Should be equal to 9');  
        Assert.equal(addFriend(acc9, 'John'), 10, 'Should be equal to 10');  
    }       

    function setOpenVote() public {
        Assert.equal(getVoteState(), 0, 'Vote should be closed (0)');
        Assert.ok(openForVoting(), 'Voting open now.');                     
        Assert.equal(getVoteState(), 1, 'Vote should be open (1)');
    }  
    
    /// #sender: account-1
    function vote1() public {
        Assert.equal(doVote(1), true, 'Should be false');                          
    }
    
    /// #sender: account-4
    function vote2() public {
        Assert.equal(doVote(2), true, 'Should be false');                          
    }
    
    function addBlockNumber() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", 'Cafe2'));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Voting is not closed.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }
    
    function addBlockNumberAgain() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", 'Cafe2'));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Voting is not closed.', 'Failed with unexpected reason');
        } else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }
    
    /// #sender: account-5
    function vote3() public {
        Assert.equal(doVote(2), true, 'Should be true');          
    }
    
    /// On Vote 4 the timeout has been reached. Since it has reached timeout. This vote in not counted
    /// #sender: account-6
    function vote4() public {
        Assert.equal(doVote(1), false, 'Should be true');
    }
    
    /// After this timeout. If a vote is enter. It'll be rejected, since it is considered closed again
    /// #sender: account-8
    function vote5() public {
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
        Assert.equal(votedVenue, 'Uni Cafe', 'Selected venue should be Courtyard Cafe');
    }
    
    /// Contract should be set to voteState Timeout because the vote was voted based of a timeout
    function checkState() public {
        Assert.equal(getVoteState(), 2, 'Vote should be timeout (2)');
    }

}