// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title Ballot: Core function for developing Ballot smart contract
/// @author InfinityLabsCode
/// @notice This smart contract contains all functionality for developing Ballot smart contract

contract Ballot {
    ///@dev the user that can create new ballot and other administrator thing
    address public chairPerson;
    ///@dev name of the election
    string public electionName;
    ///@dev description of the created election
    string public electionDescription;
    ///@dev current state voting
    bool public votingEnded;
    ///@dev total vote counted for this election
    uint public totalVoteCounted;
    ///@dev name of all the proposals
    string [] proposalNames;

    ///@dev structure of voter for participate in election
    struct Voter {
        ///@dev voter weight of voting for one election
        uint weight;
        ///@dev voter voted for this proposal , it holds an index
        uint voteFor;
        ///@dev voter voted in this election or not
        bool voted;
    }

    ///@dev structure of proposal for election
    struct Proposal {
        ///@dev name of the proposal
        string name;
        ///@dev total vote accuired by this proposal
        uint voteCount;
    }

    ///@dev winning proposal after election ended
    Proposal public winningProposal;
    ///@dev index of winning proposal after election ended
    uint public winningProposalIndex;

    ///@dev map of addresses and the Voter information
    mapping(address => Voter) voters;

    ///@dev array of proposed proposals
    Proposal[] public proposals;

    ///@dev Ballot contract constractor
    ///@param _owner walletAddress for the chairperson
    ///@param _electionName the name of this election
    ///@param _electionDescription the description of this election
    ///@param _proposalsName list of proposals for this election
    constructor(
        address _owner,
        string memory _electionName,
        string memory _electionDescription,
        string[] memory _proposalsName
    ) {
        electionName = _electionName;
        electionDescription = _electionDescription;
        chairPerson = _owner;
        voters[chairPerson].weight = 1;
        votingEnded = false;
        proposalNames = _proposalsName;

        for (uint i = 0; i < _proposalsName.length; i++) {
            proposals.push(Proposal({name: _proposalsName[i], voteCount: 0}));
        }
    }

    ///@dev give right to vote to a voter by the chairperson
    ///@notice Only the chairperson wallet address can add gift give right to vote
    ///@param  _sender the walletAddress called this function
    ///@param _voter the voterAddress which will get the right to vote

    function _giveRightToVote(address _sender, address _voter) public {
        require(
            _sender == chairPerson,
            "Only chairperson can give right to vote."
        );
        require(!voters[_voter].voted, "The voter already voted.");
        require(voters[_voter].weight == 0 , "Already given the right to vote.");
        voters[_voter].weight = 1;
    }

    ///@dev give vote to a specific proposal
    ///@notice voter can vote only if the voting is not ended
    ///@param  _proposal the proposal which the voter wants to voted
    ///@param _voterAddress the address of voter who wants to vote

    function _giveVote(uint _proposal, address _voterAddress) public {
        require(!votingEnded, "Votting ended.");
        Voter storage sender = voters[_voterAddress];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.voteFor = _proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[_proposal].voteCount += sender.weight;
        totalVoteCounted += 1;
    }

    ///@dev get the winning proposal for this election
    ///@notice voting needs to ended by the chariperson for announce the winning proposal
    ///@return  winningProposal_ the index of winning proposal

    function _winningProposal() public view returns (uint winningProposal_) {
        require(votingEnded, "Votting is still processing");
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    ///@dev ending this perticular election
    ///@notice only the chairperson can call this function
    ///@param  _sender the walletAddress that calls this method
    function _endingVoting(address _sender) external {
        require(
            _sender == chairPerson,
            "Only Chiarpersone can end the voting session!"
        );
        votingEnded = true;
        winningProposalIndex = _winningProposal();
        winningProposal = proposals[winningProposalIndex];
    }

    ///@dev getter function for electionName
    ///@return  electionName name of the election
    function _getName() public view returns (string memory) {
        return electionName;
    }

    ///@dev getter function for electionDescription
    ///@return  electionDescription description of the election
    function _getDescription() public view returns (string memory) {
        return electionDescription;
    }

    ///@dev getter function for voting ended or not
    ///@return  votingEnded current status of this voting
    function _isVotingEnded() public view returns (bool) {
        return votingEnded;
    }

    ///@dev getter function for get winning proposal
    ///@return winningProposal name of the winning proposal
    function _getWinningProposalName() public view returns (string memory) {
        return winningProposal.name;
    }

    ///@dev getter function for get total vote counted
    ///@return totalVoteCounted total vote counted for this election
    function _getTotalVoteCounted() public view returns (uint) {
        return totalVoteCounted;
    }

    ///@dev getter function for get the proposals
    ///@return proposalName name of the proposals
    function _getProposalName() public view returns (string[] memory) {
        return proposalNames;
    }
}
