// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract LunchVenue {

    struct Friend {
        string name;
        uint venue;
        bool voted;
    }

    struct Vote {
        address voterAddress;
        uint venue;
    }

    mapping (uint => string) public venues;
    mapping (address => Friend) public friends;
    uint public numVenues = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    address public manager;
    string public votedVenue = "";

    mapping (uint => Vote) private votes;
    mapping (uint => uint) private results;

    bool voteOpen = true;

    constructor () {
        manager = msg.sender;
    }

    function addVenue(string memory name) public restricted returns (uint) {
        numVenues++;
        venues[numVenues] = name;
        return numVenues;
    }

    function addFriend(address friendAddress, string memory name) public restricted returns(uint) {
        Friend memory f;
        f.name = name;
        f.voted = false;
        friends[friendAddress] = f;
        numFriends++;
        return numFriends;
    }

    function doVote(uint venue) public votingOpen returns (bool validVote) {
        validVote = false;
        if(bytes(friends[msg.sender].name).length != 0) {
            if(bytes(venues[venue]).length != 0) {
                validVote = true;
                friends[msg.sender].voted = true;
                Vote memory v;
                v.voterAddress = msg.sender;
                v.venue = venue;
                numVotes++;
                votes[numVotes] = v;
            }
        }

        if(numVotes >= numFriends/2 + 1) {
            finalResult();
        }

        return validVote;
    }

    function finalResult() private {
        uint highestVotes = 0;
        uint highestVenue = 0;

        for(uint i=1; i<=numVotes; i++) {
            uint voteCount = 1;
            if(results[votes[i].venue] > 0) {
                voteCount += results[votes[i].venue];
            }
            results[votes[i].venue] = voteCount;

            if(voteCount > highestVotes) {
                highestVotes = voteCount;
                highestVenue = votes[i].venue;
            }
        }

        votedVenue = venues[highestVenue];
        voteOpen = false;
    }


    modifier hasVoted() {
        require(msg.sender == manager, "Can only be executed by the manager");
        _;
    }

    modifier restricted() {
        require(msg.sender == manager, "Can only be executed by the manager");
        _;
    }

    modifier votingOpen() {
        require(voteOpen == true, "Can vote only while voting is open");
        _;
    }
}