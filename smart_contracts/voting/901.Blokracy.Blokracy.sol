// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "hardhat/console.sol";

contract Blokracy {

///EVERYTHING SENT FROM JS MUST BE ENCRYPTED. THERE'S NO PRIVATE INFO ON THE BLOCKCHAIN
///THERE MUST BE A FUNCTION TO DECRYPT ON THE CLIENT-SIDE

///Constructor
    constructor (address _initializer, string memory _password, uint _pin) {
        ballotNum = 1000;
        initializer = _initializer;
        password = _password;
        passwordHash = keccak256(abi.encodePacked(password));
        pin = _pin;
    }

////needs to be deleted before deployment
    function check() public view returns (address, string memory, bytes32, uint) {
        return (initializer, password, passwordHash, pin);
    }

///Structs
    struct Ballot {
        uint ballotID;
        string subcategory;
        address user;
        string post;
        uint upvotes;
        uint downvotes;
        uint abstains;
        uint voteNum;
    }

    struct Voter {
        uint ballotID;
        address user;
        bool alreadyVoted;
    }

///Mappings
    mapping (uint => Ballot) public ballot;
    mapping (uint => mapping (address => Voter)) public voter;

///Variables
    address internal initializer;
    string internal password;
    bytes32 passwordHash;
    uint pin;

    address public operator;
    uint ballotNum;
    uint upvotes;
    uint downvotes;
    uint ballot1;
    uint ballot2;
    uint ballot3;
    uint ballotLoaderPlaceholder;
    uint localPlaceholder;
    bool loadedPreviously;
    uint start;

///Events
    event Creation(string message, uint idnum);
    event Vote(uint votecount);
    event IDLoad(address poster, string postbody);
    event RecencyLoad(
        uint id1, uint id2, uint id3,
        string post1, string post2, string post3,
        address user1, address user2, address user3
        );
    event StartingFromLoad(
        uint id1, uint id2, uint id3,
        string post1, string post2, string post3,
        address user1, address user2, address user3
        );
    event GetBallotInfo(uint ballotnumber);

///Functions
///Creating a Ballot:
    function createBallot(
        string memory _subcategory, string memory _post
    ) public {

        ///Set Operator
        operator = msg.sender;

        ///Increment ballotNum
        ballotNum ++;

        ///Apply specifics to ballot
        ballot[ballotNum] = Ballot(
            ballotNum, _subcategory, operator,
            _post, 0, 0, 0, 0
        );

        ///return string and ballotNum
        emit Creation("Ballot was successfully posted!", ballotNum);
        
    }

    function castVote(
        uint _ballotID, uint _vote //can be 2 for downvote, 1 for upvote, or 0 for abstain
    ) public {
        require(voter[_ballotID][msg.sender].alreadyVoted == false, "You've already voted on this ballot. You may only vote once.");
        if (_vote == 1) {
            ballot[_ballotID].upvotes += 1;
        } else if (_vote == 0) {
            ballot[_ballotID].abstains += 1;
        } else if (_vote == 2) {
            ballot[_ballotID].downvotes += 1;
        } else {
            revert("False | incorrect input.");
        }
        voter[_ballotID][msg.sender] = Voter (
            _ballotID , msg.sender, true
        );
        upvotes = ballot[_ballotID].upvotes;
        downvotes = ballot[_ballotID].downvotes;
        ballot[_ballotID].voteNum =  upvotes - downvotes;
        emit Vote(ballot[_ballotID].voteNum);

    }

    function deleteBallot(
        bytes32 _potentialPasswordHash, uint _potentialPin, uint _ballotID
    ) public {
        require (msg.sender == initializer, "You are not the administrator of this contract.");
        require (_potentialPasswordHash == passwordHash, "Password Hash is incorrect.");
        require (_potentialPin == pin, "Pin is incorrect.");
        ballot[_ballotID] = Ballot(0, "[N/A]", address(0x0), "[DELETED BALLOT]", 0, 0, 0, 0);
    }

    function getBallotInfo() public {
        emit GetBallotInfo(ballotNum);
    }

    function loadBallotByID(uint _ballotID) public {
        require(ballot[_ballotID].user != address(0x0), "This post doesn't exist!");
        emit IDLoad(ballot[_ballotID].user, ballot[_ballotID].post);
    }

    function loadBallots(
    ) public {
        if (loadedPreviously == false)  {
            ballotLoaderPlaceholder = ballotNum;
            loadedPreviously = true;
        }
            ballot1 = ballotLoaderPlaceholder;
            ballot2 = ballotLoaderPlaceholder - 1;
            ballot3 = ballotLoaderPlaceholder - 2;
            ballotLoaderPlaceholder -= 3;
        emit RecencyLoad(
            ballot1, ballot2, ballot3,
            ballot[ballot1].post, ballot[ballot2].post, ballot[ballot3].post,
            ballot[ballot1].user, ballot[ballot2].user, ballot[ballot3].user
        );
    }

    function loadBallotsStartingFrom(
        uint _start
    ) public {
            start = _start;
            ballot2 = start - 1;
            ballot3 = start - 2;
            ballotLoaderPlaceholder = _start -3;
        emit StartingFromLoad(
            start, ballot2, ballot3,
            ballot[start].post, ballot[ballot2].post, ballot[ballot3].post,
            ballot[start].user, ballot[ballot2].user, ballot[ballot3].user
        );
    }

}
