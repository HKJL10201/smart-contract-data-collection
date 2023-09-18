/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract to agree on the lunch venue
contract LunchVenue_updated {

    struct Friend {
        string name ;
        bool voted ;
    }

    struct Vote {
        address voterAddress ;
        uint venue ;
    }

    mapping( uint => string ) public venues ; // List of venues ( venue no , name )

    // ISSUE 1
    // use friends mapping to determine if they already voted in doVote function call
    mapping( address => Friend ) public friends ; // List of friends ( address , Friend )

    uint public numVenues = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    address public manager ; // Manager of lunch venues
    string public votedVenue = ""; // Where to have lunch

    mapping( uint => Vote ) private votes ; // List of votes ( vote no , Vote )
    mapping( uint => uint ) private results ; // List of vote counts ( venue no , no of votes )
    bool public voteOpen = true ; // voting is open

    // ISSUE 2
    // use voteStarted variable as a check to prevent adding new friends and venues when vote has started
    bool voteStarted = false; // voting has started

    // ISSUE 3
    // starting block time
    uint public startingBlockNum = block.number;

    // ISSUE 4
    // definition of currentState determines whether contract is cancelled
    enum VotingState { OPEN, CLOSE }
    VotingState public currentState = VotingState.OPEN;

    // ISSUE 5
    // track most voted venue and most votes
    uint mostVotes = 0;
    uint mostVotedVenue;
    mapping( uint => uint ) private venue_votes ; // venue and their votes ( venue , votes )
    bool firstVote = true; //track whether this is the first vote

    // Creates a new lunch venue contract
    constructor() {
        manager = msg.sender ; // Set contract creator as manager
    }

    /// @notice Add a new lunch venue
    /// @dev To simplify the code duplication of venues is not checked
    /// @param name Name of the venue
    /// @return Number of lunch venues added so far
    function addVenue( string memory name ) public restricted returns ( uint ){
        // ISSUE 2
        if ( voteStarted == true ) // return current numVenues if voting already started
            return numVenues ;
        numVenues++;
        venues[numVenues] = name ;
            return numVenues ;
    }

    /// @notice Add a new friend who can vote on lunch venue
    /// @dev To simplify the code duplication of friends is not checked
    /// @param friendAddress Friend ’s account address
    /// @param name Friend ’s name
    /// @return Number of friends added so far
    function addFriend( address friendAddress , string memory name ) public restricted returns ( uint ){
        // ISSUE 2
        if ( voteStarted == true ) // return current numFriends if voting already started
            return numFriends ;
        Friend memory f;
        f.name = name;
        f.voted = false;
        friends[friendAddress] = f;
        numFriends++;
        return numFriends;
    }

    /// @notice Vote for a lunch venue
    /// @dev To simplify the code multiple votes by a friend is not checked
    /// @param venue Venue number being voted
    /// @return validVote Is the vote valid ? A valid vote should be from a registered friend and to a registered venue

    function doVote( uint venue ) public votingOpen returns ( bool validVote ){
        voteStarted = true;
        validVote = false ; // Is the vote valid ?

        if ( bytes( friends[msg.sender].name ).length != 0) { // Does friend exist ?
            if ( bytes(venues[venue]).length != 0) { // Does venue exist ?
                // ISSUE 1
                if( friends[msg.sender].voted == true ) { // check whether friend has voted
                    return validVote; // Return false if voted
                }
                validVote = true ;
                friends[msg.sender].voted = true ;
                Vote memory v;
                v.voterAddress = msg.sender ;
                v.venue = venue ;
                numVotes++;
                votes[numVotes] = v;

                // ISSUE 5
                // track most voted venue during doVote calls instead of calculating at the end with finalResult for efficiency
                venue_votes[venue] += 1;
                if (firstVote) {
                    firstVote = false;
                    mostVotedVenue = venue;
                    mostVotes = 1;
                } else {
                    if ( venue_votes[venue] > mostVotes ) {
                        mostVotedVenue = venue;
                        mostVotes = venue_votes[venue];
                    }
                }
            }
        }

        if ( numVotes >= numFriends /2 + 1) { // Quorum is met
            // no longer need to loop through votes in finalVotes() to calculate mostVoted
            votedVenue = venues[mostVotedVenue]; // Chosen lunch venue
            voteOpen = false ; // Voting is now closed
            //finalResult() ;
        }
        return validVote ;
    }

    // ISSUE 5
    //finalResult no longer needed
    /// @notice Determine winner venue
    /// @dev If top 2 venues have the same no of votes , final result depends on vote order
    /*
    function finalResult() private {
        uint highestVotes = 0;
        uint highestVenue = 0;

        for ( uint i = 1; i <= numVotes ; i++) { // For each vote
            uint voteCount = 1;
            if( results[ votes[i].venue ] > 0) { // Already start counting
                voteCount += results[votes[i].venue];
            }
            results[votes[i].venue] = voteCount ;

            if ( voteCount > highestVotes ){ // New winner
                highestVotes = voteCount ;
                highestVenue = votes[i].venue ;
            }
        }
        votedVenue = venues[highestVenue]; // Chosen lunch venue
        voteOpen = false ; // Voting is now closed
    }
    */

    // ISSUE 3
    /// @notice cancel state if contract times out after 60 blocks since start
    function setTimeout () public returns ( VotingState) {
        if ( block.number >= startingBlockNum + 120 ) {
            currentState = VotingState.CLOSE;
        }
        return currentState;
    }

    // ISSUE 4
    /// @notice disableContract by setting vote open to false
    function disableContract () public restricted {
        voteOpen = false;
        currentState = VotingState.CLOSE;
    }

    // ISSUE 4
    /// @notice selfdestruct contract to disable restricted
    function kill () public restricted {
        selfdestruct(payable(msg.sender));
    }

    /// @notice Only manager can do
    modifier restricted() {
        require ( msg.sender == manager , "Can only be executed by the manager");
        _;
    }

    /// @notice Only whenb voting is still open
    modifier votingOpen() {
        require ( voteOpen == true , "Can vote only while voting is open.") ;
        _;
    }
}
