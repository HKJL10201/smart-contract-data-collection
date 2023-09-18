pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2; // to return an array of a struct

contract Voting {
    // Check address approved to gvote in smart contract
    // Use key value data structure (mapping in Solidity)
    // If address = true, can vote; if address = false, can't vote
    mapping(address => bool) public voters;
    // create a struct for each voting choice
    struct Choice {
        uint256 id;
        string name;
        uint256 votes;
    }
    // Data structure for each vote
    struct Ballot {
        uint256 id;
        string name;
        // yes, you can have an array of struct within a struct
        Choice[] choices;
        // establish when there is the end of the ballot
        uint256 end;
    }
    // Container for ballot struct
    mapping(uint256 => Ballot) ballots;
    // integer for next ballot to be created
    uint256 nextBallotId;
    // define admin variable (to use below)
    address public admin;
    // mapping of mapping (like nested object in JavaScript)
    mapping(address => mapping(uint256 => bool)) public votes;

    // Constructor function for when we deploy the smart contract
    constructor() public {
        // save address of sender of transaction and make them the admin so they can control the execution
        admin = msg.sender;
    }

    // function to add voters to the smart contract
    // add modifier so only the admin can do this
    function addVoters(address[] calldata _voters) external onlyAdmin {
        // loop through all of the _voters array and save address in voter array of smart contract
        // for loop
        for (uint256 i = 0; i < _voters.length; i++) {
            // access voters mapping and access current entry of voters argument with [i] and set it to true
            // it will check that the voter did in fact vote or not vote
            voters[_voters[i]] = true;
        }
    }

    // function to create the ballots: receive 3 arguments
    function createBallot(
        string memory name,
        string[] memory choices,
        uint256 offset
    )
        public
        // attach the modifier to only the admin can do it
        onlyAdmin
    {
        // array needs to be put in memory
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = name;
        ballots[nextBallotId].end = now + offset;
        for (uint256 i = 0; i < choices.length; i++) {
            // access ballot struct again
            // since array in storage, we have access to push method
            ballots[nextBallotId].choices.push(Choice(i, choices[i], 0));
        }
    }

    // function to be able to vote
    function vote(uint256 ballotId, uint256 choiceId) external {
        // requier that voters of the sender of the transaction is true
        // means this voter has been approved before
        require(voters[msg.sender] == true, "only voters can vote");
        // ensure past voters can't vote again...can only vote once
        require(
            votes[msg.sender][ballotId] == false,
            "voter can only vote once for a ballot"
        );
        // ensure the ballot has not already ended
        require(
            now < ballots[ballotId].end,
            "can only vote until ballot end date"
        );
        // set votes of the voter true and then prevent double voting
        votes[msg.sender][ballotId] = true;
        // allow voters here
        ballots[ballotId].choices[choiceId].votes++;
    }

    // function to get results of the ballot
    function results(uint256 ballotId) external view returns (Choice[] memory) {
        // don't want to return the vote results before ballot end
        require(
            now >= ballots[ballotId].end,
            "cannot see the ballot result before ballot end"
        );
        // return result
        return ballots[ballotId].choices;
    }

    // Need some access controls so not everyone can create a Ballot or vote in the ballots
    // Modifer so only the admin of the smart contract can run the 2 functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        // execute the function for which the modifier is attached
        _;
    }
}
