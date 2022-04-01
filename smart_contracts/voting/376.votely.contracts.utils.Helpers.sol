pragma solidity ^0.8.0;

contract Helper {
    modifier Votable(uint256 age) {
        require(age > 18, "Voter is not eligible to vote.");
        _;
    }
}
