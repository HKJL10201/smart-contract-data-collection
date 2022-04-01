// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract voting {
    ///custom data type to collect details of candidates
    struct candidateDetails {
        string name;
        string vyingPosition;
        uint256 voteCount;
    }

    ///same as above, collecting details of voters
    struct Voter {
        bool voted;
        uint256 vote; ///index of the candidate a voter votes for
        address voterAddress;
        uint256 studentId;
    }

    /*public array of data type 'candidateDetails' to
    take more than one candidate when necessary*/

    candidateDetails[] public _candidates;

    Voter[] internal allowedVoters; ///array of voters allowed to vote

    //mapping(address => Voter) public voters;

    address public electionOfficer; ///declaring address of person who calls poll creation contract

    uint256 public expireTime;

    /// display the candidates
    function showCandidates() public view returns (candidateDetails[] memory) {
        return _candidates;
    }

    function showAllowed() public view returns (Voter[] memory) {
        return allowedVoters;
    }

    /*createPoll takes to sets of array stored in memory to record 
    the details of the various candidates and whatever position the 
    candidate vies for*/

    function createPoll(
        string[] memory candidateInfo,
        string[] memory position,
        uint256 _timeLimit
    ) public {
        electionOfficer = msg.sender;

        for (uint256 i = 0; i < candidateInfo.length; i++) {
            _candidates.push(
                candidateDetails({
                    name: candidateInfo[i],
                    vyingPosition: position[i],
                    voteCount: 0
                })
            );
        }

        expireTime = block.timestamp + _timeLimit;
    }

    /*
    approvedVoters function takes addresses and student Ids of people(students) who the ballot
    creator(electionOfficer) wants to participate in the election
    */
    function approveVoters(address[] memory _voter, uint256[] memory _studentId)
        public
    {
        require(
            msg.sender == electionOfficer,
            "Only election commissioner can give rights to vote"
        );

        for (uint256 j = 0; j < _voter.length; j++) {
            allowedVoters.push(
                Voter({
                    voterAddress: _voter[j],
                    studentId: _studentId[j],
                    voted: false,
                    vote: 0
                })
            );
        }
    }

    function castVote(address _address, uint256 _choice) public {
        require(msg.sender == _address, "Incorrect transacting address");
        require(expireTime > block.timestamp, "Voting has ended");

        for (uint256 k = 0; k < allowedVoters.length; k++) {
            if (allowedVoters[k].voterAddress == _address) {
                require(!allowedVoters[k].voted, "Already voted");
                allowedVoters[k].voted = true;
                allowedVoters[k].vote = _choice;
                _candidates[_choice].voteCount += 1;
            }
        }
    }

    function winningCandidate()
        public
        view
        returns (uint256 winningCandidate_)
    {
        if (msg.sender != electionOfficer) {
            require(
                expireTime < block.timestamp,
                "You can check the winner when voting ends"
            );
        } else {
            uint256 winningVoteCount = 0;

            for (uint256 p = 0; p < _candidates.length; p++) {
                if (_candidates[p].voteCount > winningVoteCount) {
                    winningVoteCount = _candidates[p].voteCount;
                    winningCandidate_ = p;
                }
            }
        }
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     * @return vyingPosition_ the position of the winner
     */
    function winnerName()
        public
        view
        returns (
            string memory winnerName_,
            string memory vyingPosition_,
            uint256 votes
        )
    {
        winnerName_ = _candidates[winningCandidate()].name;
        vyingPosition_ = _candidates[winningCandidate()].vyingPosition;
        votes = _candidates[winningCandidate()].voteCount;
    }
}
