// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voters {
    uint256 public numberOfVoters;

    function register(address candidate) public isRegisteredNot(candidate) {
        registeredVoter[candidate] = true;
        numberOfVoters += 1;
        emit voterRegistered(candidate);
    }

    function vote(
        string memory topic,
        address proposedBy,
        string memory date
    ) public isRegistered alreadyVotedForTopic(topic) {
        votedForProposals[msg.sender].push(
            Voted({
                topic: topic,
                voteCount: 1,
                proposedBy: proposedBy,
                dateVoted: date,
                viaProxy: false
            })
        );

        castedVoteInFavourOf[msg.sender][topic] = proposedBy;
        votedOnTopic[msg.sender][topic] = true;
        emit votedForProposal(msg.sender, "you've voted.", topic);
    }

    function voted(address addr, string memory topic)
        public
        view
        returns (bool)
    {
        return votedOnTopic[addr][topic];
    }

    function votedFor(address candidate, string memory topic)
        public
        view
        returns (address addr)
    {
        require(registeredVoter[candidate] == true, "candidate not registered");

        require(
            votedOnTopic[candidate][topic] == true,
            "candidate did not vote on topic"
        );
        addr = castedVoteInFavourOf[candidate][topic];
    }

    modifier isRegisteredNot(address candidate) {
        require(
            registeredVoter[candidate] == false,
            "candidate is registered, no need to re-register."
        );
        _;
    }

    modifier isRegistered() {
        require(
            registeredVoter[msg.sender],
            "You are not registered, Register first."
        );
        _;
    }
    modifier alreadyVotedForTopic(string memory topicName) {
        bool _voted = votedOnTopic[msg.sender][topicName];

        require(_voted == false, "alread voted for a proposal");
        _;
    }

    struct Proposition {
        string proposition;
        address proposedBy;
        string dateProposed;
    }
    struct Voted {
        string topic;
        uint256 voteCount;
        address proposedBy;
        string dateVoted;
        bool viaProxy;
    }

    mapping(address => bool) public registeredVoter;

    mapping(address => mapping(string => bool)) internal votedOnTopic;

    mapping(address => Voted[]) public votedForProposals;

    mapping(address => mapping(string => address))
        internal castedVoteInFavourOf;

    event voterRegistered(address indexed voter);
    event votedForProposal(address voter, string message, string topicVotedOn);
   
}
