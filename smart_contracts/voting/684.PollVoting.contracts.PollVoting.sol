//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

/*
    A poll's ID is automatically calculated and the votes and voters arrays are updated
    as someone casts a vote to a poll.

    *Note*
    Miners can manipulate block timestamp to an extent of approx. few seconds, which is
    enough to affect business logic depending on a second-level precision.
    Business logics which depend on a much longer period can simply ignore or suppress the linter 
    warnings against it.
    Or if it fits the usecase, we can simply validate against the block number, which most linters allow.

    The strings are stored as fixed-size bytes32 values to optimize for gas.
    Use `ethers.utils.parseBytes32String( aBytesLike )`
    Which returns the decoded string represented by the Bytes32 encoded data.
*/
struct Poll {
    uint256 id;
    bytes32 title;
    // A poll can have only upto 4 options
    // but still using a dynamic array cause it could be from 2-4 in number
    bytes32[] options;
    uint256[4] votes;
    address[] voters;
    uint256 expirationTime;
    bytes32 winner;
}

contract PollVoting {
    event PollCreated(
        bytes32 indexed title,
        uint256 indexed optionLength,
        uint256 indexed timePeriod
    );
    event VoteCasted(
        address indexed creator,
        bytes32 indexed title,
        bytes32 indexed option
    );

    Poll private defaultPoll; // used only to create new polls
    mapping(address => Poll[]) private polls; // Maps the poll creator to the polls he created

    /*
        Anyone who creates a poll becomes it's creator.
        Following must be provided while creating a poll:
        a Title, 2-4 options, and an expiration time (in seconds) which should be greater than 10.

        An address can create multiple polls, and they can be differentiated using their IDs.
    */
    error InvalidTitle(bytes32 title);
    error InvalidOptionLength(uint256 length);
    error InvalidTime(uint256 time);

    function addPoll(
        bytes32 title,
        bytes32[] calldata options,
        uint256 time
    ) external {
        if (
            title ==
            0x0000000000000000000000000000000000000000000000000000000000000000
        ) revert InvalidTitle(title);
        if (options.length < 2 || options.length > 4)
            revert InvalidOptionLength(options.length);
        if (time < 10 seconds) revert InvalidTime(time);

        defaultPoll.id = polls[msg.sender].length; // use the index as the Poll ID
        defaultPoll.title = title;
        defaultPoll.options = options;
        defaultPoll.expirationTime = time + block.timestamp;

        polls[msg.sender].push(defaultPoll);

        emit PollCreated(title, options.length, time);
    }

    /*
        Once a poll is created, anyone can see it's details using just it's creator's address, and poll's ID.
    */
    error InvalidCreator(address creator);
    error InvalidPollID(uint256 ID);

    modifier checkParams(address creator, uint256 pollID) {
        if (creator == address(0)) revert InvalidCreator(creator);
        if (pollID >= polls[creator].length) revert InvalidPollID(pollID);
        _;
    }

    function getPollDetails(address creator, uint256 pollID)
        external
        view
        checkParams(creator, pollID)
        returns (
            bytes32 title,
            bytes32[] memory options,
            uint256[4] memory votes,
            address[] memory voters,
            uint256 timeRemaining,
            bytes32 winner // For cases when this function is called after the poll expires
        )
    {
        // Getting the poll msg.sender asked for
        Poll memory poll = polls[creator][pollID];

        if (poll.expirationTime < block.timestamp) {
            return (
                poll.title,
                poll.options,
                poll.votes,
                poll.voters,
                0,
                getWinner(poll.options, poll.votes)
            );
        } else {
            return (
                poll.title,
                poll.options,
                poll.votes,
                poll.voters,
                poll.expirationTime - block.timestamp,
                ""
            );
        }
    }

    /*
        Except the creator, anyone (who has not already voted) can cast their vote to an option,
        given a valid poll ID and creator address
    */
    error InvalidOption(uint256 option);
    error SelfVoteError();
    error PollExpiredError(uint256 expirationTime);
    error DuplicateVoteError(address voter);

    function castAVote(
        address creator,
        uint256 pollID,
        uint256 option // the index of the option to which a vote must be casted
    ) external checkParams(creator, pollID) {
        if (msg.sender == creator) revert SelfVoteError();

        Poll storage poll = polls[creator][pollID];

        if (option >= poll.options.length) revert InvalidOption(option);
        if (poll.expirationTime < block.timestamp)
            revert PollExpiredError(poll.expirationTime);
        if (alreadyAVoter(msg.sender, poll.voters))
            revert DuplicateVoteError(msg.sender);

        poll.voters.push(msg.sender);
        unchecked {
            poll.votes[option]++;
        }

        emit VoteCasted(creator, poll.title, poll.options[option]);
    }

    /*
        helper function to calculate the winner
        This function can be imporved to account for the cases when more than one options
        have the same no. of votes. Currently, in such cases, it'll consider the first option
        as the winner.
    */
    function getWinner(bytes32[] memory options, uint256[4] memory votes)
        private
        pure
        returns (bytes32)
    {
        uint256 winnerIndex = 0;
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < options.length; ) {
            if (votes[i] > maxVotes) {
                maxVotes = votes[i];
                winnerIndex = i;
            }

            unchecked {
                i++;
            }
        }
        return options[winnerIndex];
    }

    // helper function to check if an address is already a voter or not
    function alreadyAVoter(address v, address[] memory voters)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < voters.length; ) {
            if (v == voters[i]) return true;

            unchecked {
                i++;
            }
        }
        return false;
    }
}
