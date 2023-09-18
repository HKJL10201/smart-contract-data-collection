// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DAO is AccessControl {
    address public token;
    uint256 public minQuorum;
    uint256 public votingDuration;
    uint256 public proposalID;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address _tokenAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        token = _tokenAddress;
        minQuorum = 1000;
        votingDuration = 3;
    }

    struct Proposal {
        address recepient;
        string description;
        bytes selector;
        bool accepted;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
    }

    struct Voter {
        uint256 deposit;
        uint256 usedTokens;
        uint256[] votedProposals;
    }

    mapping(address => Voter) private _voters;
    mapping(uint256 => Proposal) public proposals;

    event VotingFinished(
        uint256 indexed _id,
        bool accepted,
        uint256 votesFor,
        uint256 votesAgainst,
        address indexed recepient,
        string description
    );

    event ExecutionResult(bool success, bytes result);
    event ProposalAdded(
        uint256 indexed _id,
        address indexed recepient,
        uint256 startTime,
        string description
    );
    event MinQuorumChanged(uint256 oldQuorum, uint256 newQuorum);
    event VotingPeriodChanged(uint256 oldPeriod, uint256 newPeriod);

    function getVoterDeposit(address _voter)
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (uint256)
    {
        return _voters[_voter].deposit;
    }

    function getVoterUsedTokens(address _voter)
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (uint256)
    {
        return _voters[_voter].usedTokens;
    }

    function addProposal(
        bytes calldata _data,
        address _recepient,
        string memory _description
    ) external onlyRole(ADMIN_ROLE) {
        Proposal memory new_proposal = Proposal(
            _recepient,
            _description,
            _data,
            false,
            0,
            0,
            block.timestamp
        );
        proposals[proposalID] = new_proposal;
        proposalID += 1;
    }

    function deposit(uint256 _amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        _voters[msg.sender].deposit += _amount;
    }

    function vote(uint256 _id, bool _vote) external {
        require(_voters[msg.sender].deposit > 0, "Please make a deposit first");
        require(
            proposals[_id].startTime != 0,
            "Proposal id is invalid or voting has closed"
        );

        uint256 votingTokens = _voters[msg.sender].deposit -
            _voters[msg.sender].usedTokens;
        if (_vote) {
            proposals[_id].votesFor += votingTokens;
        } else {
            proposals[_id].votesAgainst += votingTokens;
        }

        _voters[msg.sender].votedProposals.push(_id);

        _voters[msg.sender].usedTokens += votingTokens;
    }

    function _checkFinished() internal view returns (bool) {
        for (
            uint256 i = 0;
            i < _voters[msg.sender].votedProposals.length;
            i++
        ) {
            if (
                proposals[_voters[msg.sender].votedProposals[i]].startTime != 0
            ) {
                return false;
            }
        }
        return true;
    }

    function withdraw() external {
        require(_checkFinished());

        IERC20(token).transfer(msg.sender, _voters[msg.sender].deposit);
        delete _voters[msg.sender];
    }

    function finishProposal(uint256 _id) external {
        require(
            proposals[_id].startTime + votingDuration * 1 days <
                block.timestamp,
            "Voting period is not over yet"
        );

        if (proposals[_id].votesFor + proposals[_id].votesAgainst > minQuorum) {
            if (proposals[_id].votesFor > proposals[_id].votesAgainst) {
                proposals[_id].accepted = true;
                (bool success, bytes memory returnData) = address(
                    proposals[_id].recepient
                ).call(proposals[_id].selector);
                require(success, "Call failed");

                emit ExecutionResult(success, returnData);
            }
        }

        emit VotingFinished(
            _id,
            proposals[_id].accepted,
            proposals[_id].votesFor,
            proposals[_id].votesAgainst,
            proposals[_id].recepient,
            proposals[_id].description
        );
        delete proposals[_id];
    }

    function changeVotingDuration(uint256 _newtime) external {
        require(msg.sender == address(this), "Restricted access");
        uint256 oldPeriod = votingDuration;
        votingDuration = _newtime;
        emit VotingPeriodChanged(oldPeriod, votingDuration);
    }

    function changeMinQuarum(uint256 _newMinQuarum) external {
        require(msg.sender == address(this), "Restricted access");
        uint256 oldQuorum = minQuorum;
        minQuorum = _newMinQuarum;
        emit MinQuorumChanged(oldQuorum, minQuorum);
    }

    function getProposalData(uint256 _id)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            proposals[_id].description,
            proposals[_id].votesFor,
            proposals[_id].votesAgainst,
            proposals[_id].startTime
        );
    }
}
