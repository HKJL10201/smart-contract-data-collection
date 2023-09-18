// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract VotingEngine {
    enum VotingState {
        Started,
        HasLeader,
        Draw,
        FinishedWithWinner,
        FinishedWithDraw
    }

    struct Voting {
        uint votingId;
        string[] proposalIds;
        VotingState state;
        string winningProposal;
        uint winningVoteCount;
    }

    uint public votingsNumber;
    Voting[] public votings;
    mapping(string => uint) public voteCountByProposal;

    function createVoting(
        string[] memory proposalIds
    ) public payable returns (uint _id) {
        require(proposalIds.length > 0, "Proposals array can't be empty");

        uint votingId = votingsNumber++;

        votings.push(
            Voting({
                votingId: votingId,
                proposalIds: proposalIds,
                state: VotingState.Started,
                winningProposal: "",
                winningVoteCount: 0
            })
        );

        for (uint i = 0; i < proposalIds.length; i++) {
            string memory proposalId = proposalIds[i];
            voteCountByProposal[proposalId] = 0;
        }

        return votingId;
    }

    function vote(uint votingId, string memory proposalId) public payable {
        Voting storage voting = votings[votingId];
        require(
            voting.state != VotingState.FinishedWithWinner ||
                voting.state != VotingState.FinishedWithDraw,
            "Voting is already finished"
        );

        uint currentVotesCount = voteCountByProposal[proposalId];

        uint newVotesCount = currentVotesCount + 1;
        voteCountByProposal[proposalId] = newVotesCount;

        if (newVotesCount > voting.winningVoteCount) {
            voting.winningProposal = proposalId;
            voting.winningVoteCount = newVotesCount;
            voting.state = VotingState.HasLeader;
        } else if (newVotesCount == voting.winningVoteCount) {
            voting.winningProposal = ""; // Multiple winners
            voting.state = VotingState.Draw;
        }
    }

    // Maybe it's better to have list of ids in MongoDb
    function getVotingsList() public view returns (uint[] memory) {
        uint[] memory votingsIds = new uint[](votings.length);

        for (uint i = 0; i < votings.length; i++) {
            Voting memory v = votings[i];

            votingsIds[i] = v.votingId;
        }

        return votingsIds;
    }

    function getVotingInfo(
        uint id
    ) public view returns (uint, VotingState, string memory) {
        Voting memory voting = votings[id];

        uint votingId = voting.votingId;
        VotingState state = voting.state;
        string memory winningProposal = voting.winningProposal;

        return (votingId, state, winningProposal);
    }

    function endVoting(uint idVoting) public payable {
        Voting storage voting = votings[idVoting];

        require(
            voting.state != VotingState.Started,
            "Can't finish voting because no one voted yet"
        );

        if (!compare(voting.winningProposal, "")) {
            voting.state = VotingState.FinishedWithWinner;
        } else {
            voting.state = VotingState.FinishedWithDraw;
        }
    }

    function getWinningProposal(
        uint idVoting
    ) public view returns (string memory) {
        Voting memory voting = votings[idVoting];

        // Can bring to method voting.isFinished
        require(
            voting.state == VotingState.FinishedWithWinner ||
                voting.state == VotingState.FinishedWithDraw,
            "Voting is not finished yet"
        );

        return voting.winningProposal;
    }

    function getProposalIds(
        uint idVoting
    ) public view returns (string[] memory) {
        Voting memory voting = votings[idVoting];

        string[] memory proposalIds = voting.proposalIds;

        return proposalIds;
    }

    function getLastAddedVotingId() public view returns (uint) {
        Voting memory voting = votings[votings.length - 1];

        return voting.votingId;
    }

    function compare(
        string memory str1,
        string memory str2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }
}
