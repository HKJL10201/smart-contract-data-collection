contract Vote {
    struct Voter {
        bool voted;
        uint vote;
    }

    struct Candidate {
        string name;
        uint voteCount;
    }

    mapping(address => Voter) public voters;

    Candidate[] public candidates;

    constructor(string[] memory candidateNames) {
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }

    // vote function requires sending 1 eth to vote, also you cant vote twice
    function vote(uint candidate) public payable {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        require(msg.value == 1 ether, "You should send exactly 1 ETH to vote");
        candidates[candidate].voteCount += 1;
        sender.vote = candidate;
        sender.voted = true;
    }

    // withdraw the vote (and consequently, 1 eth) if already voted
    function withdrawVote() public {
        Voter storage sender = voters[msg.sender];
        require(sender.voted, "You haven't voted, no vote to withdraw");
        uint candidate = sender.vote;

        if (candidates[candidate].voteCount > 0) {
            candidates[candidate].voteCount -= 1;
        }
        (bool sent, ) = msg.sender.call{value: 1 ether}("");
        require(sent, "Failed to send back Ether");

        sender.voted = false;
    }

    function electionProgress() public view returns (Candidate[] memory progress_) {
        progress_ = candidates;
    }

    // get the index of the winning candidate
    function winningCandidateIndex() public view
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

    // get the winner's name
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = candidates[winningCandidateIndex()].name;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
