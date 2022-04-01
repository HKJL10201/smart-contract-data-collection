// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";

import "../contracts/ElectionFactory.sol";

contract TestElectionFactory {
    ElectionFactory voteContract;
    string[] namesList;

    function beforeEach() public {
        delete namesList;
        namesList.push("George H. W. Bush");
        namesList.push("Bill Clinton");
        namesList.push("Ross Perot");

        voteContract = new ElectionFactory();
    }


    function test_Election_Creation() public {
        voteContract.createElection("USA president election", namesList);

        Assert.equal(uint(voteContract.electionsCount()), uint(1), "Count of election should be 1");
    }
}