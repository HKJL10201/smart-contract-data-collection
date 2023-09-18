//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract CollectorDAO {
    struct Proposal {
        uint256 voteEnd;
        uint256 executionEnd;
        uint256 votesInFavor;
        uint256 votesAgainst;
        bool executed;
        // address => has already voted
        mapping(address => bool) voters;
    }
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 public constant VOTE_TYPEHASH =
        keccak256(
            abi.encodePacked("Vote(uint256 proposalID,bool isVoteInFavor)")
        );
    string public constant NAME = "CollectorDao";
    string public constant VERSION = "1";
    uint256 public constant MEMBERSHIP_REQ = 1 ether;
    string private constant INVALID_FORMAT = "Invalid input format";
    uint256 public constant quorumPercentage = 25;
    // total combined voting power
    uint256 public totalVotingPower;
    // Proposal id => proposal
    mapping(uint256 => Proposal) public proposals;
    // address -> votes bought
    mapping(address => uint256) private votingPower;

    function buyVotingPower() external payable returns (uint256) {
        votingPower[msg.sender] += msg.value;
        totalVotingPower += msg.value;
        emit VotingPowerPurchased(
            msg.sender,
            msg.value,
            votingPower[msg.sender]
        );
        return votingPower[msg.sender];
    }

    function getVotingPower() external view returns (uint256) {
        return votingPower[msg.sender];
    }

    function castVote(uint256 proposalID, bool isVoteInFavor)
        external
        returns (uint256)
    {
        return _castVote(msg.sender, proposalID, isVoteInFavor);
    }

    function _castVote(
        address voterAddress,
        uint256 proposalID,
        bool isVoteInFavor
    ) private returns (uint256) {
        require(
            votingPower[voterAddress] >= MEMBERSHIP_REQ,
            "Need at least 1 ETH in DAO to vote"
        );
        require(proposals[proposalID].voteEnd != 0, "Proposal does not exist");
        require(proposals[proposalID].voteEnd > block.timestamp, "Voting over");
        // if already voted, then skip this execution
        if (proposals[proposalID].voters[voterAddress]) {
            return 0;
        }
        if (isVoteInFavor) {
            proposals[proposalID].votesInFavor += votingPower[voterAddress];
        } else {
            proposals[proposalID].votesAgainst += votingPower[voterAddress];
        }
        proposals[proposalID].voters[voterAddress] = true;
        emit VoteCasted(proposalID, voterAddress, votingPower[voterAddress]);
        return votingPower[voterAddress];
    }

    function checkFunctionLengths(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) private pure returns (bool) {
        require(targets.length == values.length, INVALID_FORMAT);
        require(targets.length == calldatas.length, INVALID_FORMAT);
        require(targets.length > 0, INVALID_FORMAT);
        return true;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            votingPower[msg.sender] > MEMBERSHIP_REQ,
            "Need voting power to propse"
        );
        checkFunctionLengths(targets, values, calldatas);
        uint256 proposalID = hashFunctionExecutions(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
        Proposal storage proposal = proposals[proposalID];
        require(proposal.voteEnd == 0, "Proposal already exists");
        proposal.voteEnd = block.timestamp + 7 days;
        proposal.executionEnd = block.timestamp + 14 days;
        emit ProposalCreated(
            proposalID,
            msg.sender,
            targets,
            values,
            calldatas,
            description,
            proposal.voteEnd,
            proposal.executionEnd,
            proposal.votesInFavor
        );

        return proposalID;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string calldata description
    ) external {
        uint256 proposalID = hashFunctionExecutions(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
        Proposal storage proposalToExecute = proposals[proposalID];
        checkFunctionLengths(targets, values, calldatas);
        require(proposalToExecute.voteEnd != 0, "Does not exist");
        require(proposalToExecute.executed == false, "Already executed");
        require(
            proposalToExecute.votesInFavor + proposalToExecute.votesAgainst >
                (totalVotingPower * quorumPercentage) / 100,
            "Did not reach quorum"
        );
        require(
            proposalToExecute.votesInFavor > proposalToExecute.votesAgainst,
            "Not enough votes in favor"
        );
        require(
            proposalToExecute.executionEnd > block.timestamp,
            "Too late to execute"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            require(success, "Call failed");
        }
        proposalToExecute.executed = true;
        emit ProposalExecuted(
            proposalID,
            msg.sender,
            targets,
            values,
            calldatas,
            description
        );
    }

    function hashFunctionExecutions(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(targets, values, calldatas, descriptionHash)
                )
            );
    }

    function verify(
        address signer,
        uint256 proposalID,
        bool isVoteInFavor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                1, // chain id
                this
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(VOTE_TYPEHASH, proposalID, isVoteInFavor)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        return signatory == signer;
    }

    function multiVerifyAndVote(
        address[] memory signers,
        uint256[] memory proposalIDs,
        bool[] memory isVoteInFavor,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external {
        require(signers.length == proposalIDs.length, INVALID_FORMAT);
        require(proposalIDs.length == isVoteInFavor.length, INVALID_FORMAT);
        require(isVoteInFavor.length == v.length, INVALID_FORMAT);
        require(v.length == r.length, INVALID_FORMAT);
        require(r.length == s.length, INVALID_FORMAT);

        for (uint256 i = 0; i < signers.length; i++) {
            bool isVerified = verify(
                signers[i],
                proposalIDs[i],
                isVoteInFavor[i],
                v[i],
                r[i],
                s[i]
            );
            if (isVerified) {
                _castVote(signers[i], proposalIDs[i], isVoteInFavor[i]);
            } else {
                emit UnverifiedSigner(signers[i], proposalIDs[i]);
            }
        }
    }

    event ProposalCreated(
        uint256 proposalID,
        address creator,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description,
        uint256 voteEnd,
        uint256 executionEnd,
        uint256 votesInFavor
    );
    event ProposalExecuted(
        uint256 proposalID,
        address executor,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description
    );
    event VoteCasted(uint256 proposalID, address voter, uint256 votesInFavor);
    event UnverifiedSigner(address signer, uint256 proposalID);

    event VotingPowerPurchased(
        address addr,
        uint256 valueIncreased,
        uint256 totalUserValue
    );
}
