// Voting

pragma solidity >=0.7.0 <0.9.0;

//Process Objective:To enable electronic voting for any kind of application.
contract EVM {
    uint public age = 0 ; 
    uint public time_to_vote;

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted candidate
    }

    struct Candidate {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public admin;

    mapping(address => Voter) public voters;

    Candidate[] public candidates;

    //The process wants to see if the person is eligible to vote,if he/she is 18 or above 18 years
    function Age(uint _age) public {
        require(
            _age >= 18,
            "You are not eligible to vote"
        );
    }

    function DurationToVote(uint time) public {
        time_to_vote = block.timestamp + (time * 1 minutes);
    }
    // Create a new EVM to choose one of 'CandidateNames'.
    // CandidateNames names of candidates
    constructor(bytes32[] memory CandidateNames) {
        admin = msg.sender;
        voters[admin].weight = 1;

        for (uint i = 0; i < CandidateNames.length; i++) {
            // 'Candidate({...})' creates a temporary
            // Candidate object and 'candidates.push(...)'
            // appends it to the end of 'candidates'.
            candidates.push(Candidate({
                name: CandidateNames[i],
                voteCount: 0
            }));
        }
    }
      
    // Give 'voter' the right to vote on this EVM. May only be called by 'admin'.
    function authorization(address voter) public {
        require(
            msg.sender == admin,
            "Only admin can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    // Wants to delegate your vote to the voter 'to'.
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            candidates[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    // Give your vote (including votes delegated to you) to candidate 'candidates[candidate].name'.
    // candidate index of candidate in the candidates array
    function vote(uint candidate) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        require(block.timestamp < time_to_vote, "You have exceed the time limit."); //Time Limit to vote
        sender.voted = true;
        sender.vote = candidate;

        // If 'candidate' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        candidates[candidate].voteCount += sender.weight;
    }

    /* Computes the winning candidate taking all previous votes into account.
     * @return winningCandidate_ index of winning candidate in the candidates array
     */
    function winningCandidate() public view
            returns (uint winningCandidate_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winningCandidate_ = p;
            }
        }
    }
   

    /* Calls winningCandidate() function to get the index of the winner contained in the candidates array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = candidates[winningCandidate()].name;
    }
}
