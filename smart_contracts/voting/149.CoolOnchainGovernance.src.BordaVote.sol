// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface GovToken {
    function snapshot() external view returns (address[] memory);
}

contract Borda {
    Proposal[] public proposals;

    struct Proposal {
        address owner;
        address tokenAddr;
        uint256 candidateCount;
        address[] snapshot;
        mapping(address => uint8[]) votes;
        address[] voters;
        mapping(uint8 => string) candidateData;
        mapping(uint8 => uint8) results;
        bool lock;
    }

    function NewProposal(address _votetoken, uint256 _candidateCount)
        external
        returns (uint256)
    {
        GovToken token = GovToken(_votetoken);
        address[] memory snapshot = token.snapshot();
        Proposal storage newProposal = proposals.push();
        newProposal.owner = msg.sender;
        newProposal.tokenAddr = _votetoken;
        newProposal.candidateCount = _candidateCount;
        newProposal.snapshot = snapshot;
        return proposals.length - 1;
    }

    function Vote(uint256 _proposalId, uint8[] memory vote) external {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.lock);
        bool check;
        for (uint256 i = 0; i < proposal.snapshot.length; i++) {
            if (proposal.snapshot[i] == msg.sender) {
                check = true;
                break;
            }
        }

        require(check, "not in snapshot");
        require(vote.length == proposal.candidateCount, "wrong length");
        if (proposal.votes[msg.sender].length == 0) {
            proposal.voters.push(msg.sender);
        }
        proposal.votes[msg.sender] = vote;
    }

    //this is horrible i don' even if this will work
    function result(uint256 _proposalId)
        external
        view
        returns (uint8[] memory)
    {
        Proposal storage proposal = proposals[_proposalId];
        uint8[] memory record;
        for (uint256 i = 0; i < proposal.voters.length; i++) {
            for (uint8 j = 0; j < proposal.candidateCount; j++) {
                record[proposal.votes[proposal.voters[i]][i]] =
                    record[proposal.votes[proposal.voters[i]][i]] +
                    uint8((proposal.candidateCount - j));
            }
        }
        return record;
    }
}
