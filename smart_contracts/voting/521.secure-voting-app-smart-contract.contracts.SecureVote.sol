// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ballot.sol";

/// @title SecureVote: Core function for developing multiple Ballot/Election smart contract
/// @author InfinityLabsCode
/// @notice This smart contract contains all functionality for developing SecureVote smart contract

contract SecureVote {
    ///@dev owner of the smart contract
    address public owner;
    ///@dev Array of Ballots
    Ballot[] BallotArray;

    ///@dev set the owner who is deploying the smart contract
    constructor() {
        // Set the transaction sender as the owner of the contract.
        owner = msg.sender;
    }

    ///@dev modifier for to check only owner or not
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    ///@dev structure of SingleElectionStatistics for showing statistics
    struct SingleElectionStatistics {
        ///@dev name for the election
        string name;
        ///@dev description for the election
        string description;
        ///@dev vote counted for the election
        uint voteCounted;
        ///@dev voting status
        bool voteEnded;
        ///@dev name of the winning proposal
        string winningProposalName;
    }

    ///@dev create new election by the chairperson
    ///@param _electionName name of the election
    ///@param  _electionDescription description of the election
    ///@param _proposalsName list of proposals name
    function createNewElection(
        string memory _electionName,
        string memory _electionDescription,
        string[] memory _proposalsName
    ) public onlyOwner {
        Ballot ballot = new Ballot(
            msg.sender,
            _electionName,
            _electionDescription,
            _proposalsName
        );
        BallotArray.push(ballot);
    }

    ///@dev call the specific election _giveRightToVote method
    ///@param _index index of the election
    ///@param  _voter the address of the voter
    function giveRightToVote(uint _index, address _voter) public {
        BallotArray[_index]._giveRightToVote(msg.sender, _voter);
    }

    ///@dev call the specific election giveVote method
    ///@param _index index of the election
    ///@param  _proposal the proposal voted for
    function giveVote(uint _index, uint _proposal) public {
        BallotArray[_index]._giveVote(_proposal, msg.sender);
    }

    ///@dev call the specific election _endingVoting method
    ///@param _index index of the election
    function endingVoting(uint _index) public {
        BallotArray[_index]._endingVoting(msg.sender);
    }

    ///@dev call the specific election _winningProposal method
    ///@return winningProposalIndex winning proposal index
    function winningProposal(uint _index) public view returns (uint) {
        return BallotArray[_index]._winningProposal();
    }

    ///@return _proposalNames name of the proposals
    function getProposalNames(uint _index) public view returns (string[] memory) {
        return BallotArray[_index]._getProposalName();
    }

    ///@dev making statistics for all ballot/election
    ///@return results with all the information of all
    function getStatisticsOfAllVote()
        public
        view
        returns (SingleElectionStatistics[] memory )
    {

        SingleElectionStatistics[] memory results = new SingleElectionStatistics[](BallotArray.length);

        for (uint i = 0; i < BallotArray.length; i++) {
            SingleElectionStatistics memory temp = SingleElectionStatistics(
                BallotArray[i]._getName(),
                BallotArray[i]._getDescription(),
                BallotArray[i]._getTotalVoteCounted(),
                BallotArray[i]._isVotingEnded(),
                BallotArray[i]._getWinningProposalName()
            );
            results[i] = temp;
        }
        
        return results;
    }
}
