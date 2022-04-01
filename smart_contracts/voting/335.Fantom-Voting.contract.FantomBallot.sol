pragma solidity ^0.5.0;

// @title Fantom Public Voting contract.
contract FantomBallot {
    // Ballot structure represents a ballot information.
    struct Ballot {
        bytes32 name;    // short name of the ballot
        string url;      // the ballot details web page URL
        uint start;      // ballot start timestamp; votes before start are rejected
        uint end;        // ballot end timestamp; votes after end are rejected
        bool finalized;  // is the ballot finalized and all weights calculated?
        uint votes;      // number of votes made
        uint feeds;      // number of weight feeds received on finalization
    }

    // Proposal structure represents an option voters can vote for.
    struct Proposal {
        bytes32 name; // short name of the option (max 32 bytes)
        uint weight;  // accumulated proposal weight in WEI across all votes favoring it
        uint votes;   // accumulated number of votes for this proposal
    }

    // Vote represents a voter's decision in the ballot.
    // Each voter can send only one vote per address, stored vote can not be changed.
    // Weight of each vote represents the amount of WEI tokens related
    // to the voter's address on the ballot closing. The weight is calculated
    // outside of the contract shortly after the ballot ends and fed in.
    // It includes available balance, delegations, rewards, and stakes
    // of the voter's address.
    struct Vote {
        uint vote;         // index of the proposal the voter voted for
        uint voted;        // timestamp of the vote; set value signals processed vote
        uint weight;       // weight of the vote in WEI
        uint weightStamp;  // timestamp of the weight updated
    }

    // chairperson represents the address of the chairperson controlling the ballot.
    address public chairperson;

    // ballot exposes the main information about this ballot.
    Ballot public ballot;

    // proposals represent an array of proposals available on this ballot.
    Proposal[] public proposals;

    // votes represent a map of votes made. Each vote stores
    // the option selected by a voter from a unique address.
    mapping(address => Vote) public votes;

    // Voted event is emitted when a valid vote is received from an address.
    event Voted(address indexed ballot, address indexed voter, uint vote);

    // Finalized event is emitted when a decision about the winning proposal is made.
    event Finalized(address indexed ballot, uint winner);

    // constructor creates a new ballot with specified list of proposals.
    constructor(
        bytes32 name,
        string memory url,
        uint start,
        uint end,
        bytes32[] memory proposalNames
    ) public {
        // make sure the ballot date range makes sense
        require(end > start, "This ballot will never happen.");

        // remember the chairperson
        // this address will feed the weights after the ballot closes
        chairperson = msg.sender;

        // setup the ballot details
        ballot = Ballot({
            name : name,
            url : url,
            start : start,
            end : end,
            finalized : false,
            votes : 0,
            feeds : 0
            });

        // push a default proposal first (will be always index 0)
        proposals.push(Proposal({
            name : "None",
            weight : 0,
            votes : 0
            }));

        // make a proposal structure for each name given
        // and add it to the proposals structure
        for (uint i = 0; i < proposalNames.length; i++) {
            // push the Proposal to the container
            proposals.push(Proposal({
                name : proposalNames[i],
                weight : 0,
                votes : 0
                }));
        }
    }

    // proposalsCount returns the number of proposals in the ballot.
    function proposalsCount() view public returns (uint) {
        return proposals.length;
    }

    // vote processes a new incoming vote to proposal
    // by the index, e.g. proposals[proposal]
    function vote(uint proposal) external {
        // check start and end of ballot criteria before deciding on the vote
        require(now >= ballot.start, "Ballot is not open yet.");
        require(now < ballot.end, "Ballot is already closed.");

        // extract the vote for the current sender address
        Vote storage sender = votes[msg.sender];

        // validate the vote
        require(sender.voted == 0, "Already voted before.");
        require(proposal < proposals.length, "The vote is out of proposals range.");

        // register the vote
        sender.voted = now;
        sender.vote = proposal;

        // advance number of votes registered
        ballot.votes++;

        // emit the voted event
        emit Voted(address(this), msg.sender, proposal);
    }

    // feedWeights updates the votes for given set of addresses with the provided
    // weight totals in WEI adjusting the corresponding voted options as well.
    // The total for each address is calculated off-chain and fed in by an off-chain
    // server after the ballot ends.
    function feedWeights(address[] memory voters, uint[] memory totals, uint[] memory stamps) external {
        // ballot has to be beyond it's end; no totals updates before it's over
        require(now > ballot.end, "Ballot is still active.");

        // no adjustments after it's finalized
        require(!ballot.finalized, "The ballot is already finalized.");

        // only chairperson can do this
        require(msg.sender == chairperson, "Only chairperson can feed weights.");

        // loop all incoming addresses and process them
        for (uint i = 0; i < voters.length; i++) {
            // extract the vote for this processed address
            Vote storage isVote = votes[voters[i]];

            // is there a valid vote for this address && is this feed new for this vote?
            // we don't accept feed for non-voters and we don't accept feed for voter already processed
            // also make sure not to overflow the accumulated total
            if ((isVote.voted > 0) && (isVote.weightStamp == 0) &&
                (proposals[isVote.vote].weight + totals[i] >= proposals[isVote.vote].weight)
            ) {
                // add the weight to the vote
                isVote.weight = totals[i];
                isVote.weightStamp = stamps[i];

                // add the total of this voter to his selected proposal
                proposals[isVote.vote].weight += totals[i];
                proposals[isVote.vote].votes++;

                // register the feed
                ballot.feeds++;
            }
        }
    }

    // _winner calculates the winning proposal fro the proposals weight.
    function _winner() view internal returns (uint) {
        // find the winner
        uint winnerIndex = 0;
        uint winnerWeight = 0;

        // loop all proposals
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].weight > winnerWeight) {
                winnerWeight = proposals[i].weight;
                winnerIndex = i;
            }
        }

        return winnerIndex;
    }

    // finalize calculates the winning proposal and locks the winner against
    // any weight manipulation.
    function finalize() external {
        // only chairperson can do this
        require(msg.sender == chairperson, "Only chairperson can finalize.");

        // ballot has to be beyond it's end; no totals updates before it's over
        require(now > ballot.end, "Ballot is still active.");

        // only one finalization allowed
        require(!ballot.finalized, "Ballot is already finalized.");

        // the number of votes and feeds must match
        require(ballot.votes == ballot.feeds, "Missing voters feeds.");

        // set the ballot as finalized now
        ballot.finalized = true;

        // emit the winner information event; we are done
        uint winnerIndex = _winner();
        emit Finalized(address(this), winnerIndex);
    }

    // winner returns the winning proposal of this ballot.
    function winner() view public returns (uint, uint, bytes32) {
        // only finalized ballots have a winner
        require(ballot.finalized, "Ballot is not finalized yet.");

        // calculate the winner
        uint winnerIndex = _winner();
        return (winnerIndex, proposals[winnerIndex].weight, proposals[winnerIndex].name);
    }
}
