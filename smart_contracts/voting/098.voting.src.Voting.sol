// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voting {

    /**
    Economia, Orçamento, Finanças, Administração pública, Fomento
    Trabalho e Previdência Social
    Segurança pública, Defesa e Justiça
    Educação, Ciência e Tecnologia
    Saúde, Lazer e Desporto
    Infraestrutura e Transportes
    Meio Ambiente
    Minas e Energia
    Outros
    */
    // enum Subject { Treasury, Labor, Security, Education, Health, Infra, Environmental, Energy, Others }
    enum ProposalStatus { Open, Canceled, Approved, Rejected }
    enum VoteStatus { NotVoted, VotedYes, VotedNo, Abstention }

    struct Subject {
        uint subjectId;
        string description;
    }

    struct Proposal {
        uint proposalId;
        address proposer;
        string link;
        Subject subject;
        ProposalStatus status;
        uint yesVotes;
        uint noVotes;
        uint abstention;
        mapping(address => VoteStatus) votes;
    }

    struct Voter {
        // subjectId => weight
        mapping(uint => uint) weight;
        // subjectId => address of delegated
        mapping(uint => address) delegated;
        string name;
    }

    event RightToVoteDelegated(address indexed owner, address indexed delegatedTo, Subject subject);
    event RightToVoteRevoked(address indexed owner, address indexed revoked, Subject subject);
    event VoteRegistered(uint proposalId, uint amount);
    event ProposalCreated(uint proposalId, Subject subject);
    event ProposalApproved(uint proposalId, Subject subject);
    event ProposalRejected(uint proposalId, Subject subject);

    address private admin;

    mapping(address => Voter) private voters;

    Subject[] public subjects;
    Proposal[] public proposals;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function giveRightToVote(address voter, uint subjectId) public onlyAdmin {
        voters[voter].weight[subjectId] = 1;
    }

    function delegateRightToVote(address delegatedTo, uint subjectId) public {
        require(delegatedTo != msg.sender, "Self-delegation is disallowed.");
        Voter storage sender = voters[msg.sender];
        require(sender.delegated[subjectId] == address(0), "You have already delegated this subject.");
        require(sender.weight[subjectId] > 0, "You don't have right to vote on this subject.");
        require(voters[delegatedTo].weight[subjectId] > 0, "Delegated address don't have rigth to vote.");

        Voter storage receiver = voters[delegatedTo];
        sender.delegated[subjectId] = delegatedTo;
        receiver.weight[subjectId] += 1;
        sender.weight[subjectId] -= 1;

        // Navigate in open proposals already voted by delegte or by sender,
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].status == ProposalStatus.Open) { 
                if (proposals[p].votes[delegatedTo] != VoteStatus.NotVoted && proposals[p].votes[msg.sender] == VoteStatus.NotVoted) {
                    // Delegate already voted: sum sender vote in delegate vote
                    VoteStatus delegateVote = proposals[p].votes[delegatedTo];
                    addVoteToProposal(delegateVote, proposals[p], 1);
                } else if (proposals[p].votes[delegatedTo] == VoteStatus.NotVoted && proposals[p].votes[msg.sender] != VoteStatus.NotVoted) {
                    // Sender already voted: remove sender vote
                    VoteStatus senderVote = proposals[p].votes[msg.sender];
                    subVoteToProposal(senderVote, proposals[p], 1);
                    proposals[p].votes[msg.sender] = VoteStatus.NotVoted;
                } else if (proposals[p].votes[delegatedTo] != VoteStatus.NotVoted && proposals[p].votes[msg.sender] != VoteStatus.NotVoted) {
                    // Sender and delegate already voted: transfer sender vote
                    VoteStatus delegateVote = proposals[p].votes[delegatedTo];
                    VoteStatus senderVote = proposals[p].votes[msg.sender];
                    if (delegateVote != senderVote) {
                        // If voted diferently, transfer vote
                        subVoteToProposal(senderVote, proposals[p], 1);
                        addVoteToProposal(delegateVote, proposals[p], 1);
                    }
                    proposals[p].votes[msg.sender] = VoteStatus.NotVoted;
                }
            }
        }

        emit RightToVoteDelegated(msg.sender, delegatedTo, subjects[subjectId]);
    }

    function revokeRightToVote(uint subjectId) public {
        Voter storage sender = voters[msg.sender];
        require(sender.delegated[subjectId] != address(0), "You haven't delegated this subject.");

        address delegatedTo = sender.delegated[subjectId];
        Voter storage receiver = voters[delegatedTo];
        sender.delegated[subjectId] = address(0);
        receiver.weight[subjectId] -= 1;
        sender.weight[subjectId] += 1;

        // Navigate in open proposals already voted by delegte or by sender,
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].status == ProposalStatus.Open) { 
                if (proposals[p].votes[delegatedTo] != VoteStatus.NotVoted && proposals[p].votes[msg.sender] == VoteStatus.NotVoted) {
                    // Delegate already voted: subtract sender vote
                    VoteStatus delegateVote = proposals[p].votes[delegatedTo];
                    subVoteToProposal(delegateVote, proposals[p], 1);
                }
            }
        }

        emit RightToVoteRevoked(msg.sender, delegatedTo, subjects[subjectId]);
    }

    function addVoteToProposal(VoteStatus voteStatus, Proposal storage proposal, uint amount) private {
        if (voteStatus == VoteStatus.VotedYes) {
            proposal.yesVotes += amount;
        } else if (voteStatus == VoteStatus.VotedNo) {
            proposal.noVotes += amount;
        } else {
            proposal.abstention += amount;
        }
        emit VoteRegistered(proposal.proposalId, amount);
    }

    function subVoteToProposal(VoteStatus voteStatus, Proposal storage proposal, uint amount) private {
        if (voteStatus == VoteStatus.VotedYes) {
            proposal.yesVotes -= amount;
        } else if (voteStatus == VoteStatus.VotedNo) {
            proposal.noVotes -= amount;
        } else {
            proposal.abstention -= amount;
        }
    }

    function vote(uint proposalId, VoteStatus senderVote) private {
        require(senderVote != VoteStatus.NotVoted);

        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Open, "This proposal is closed.");

        Voter storage sender = voters[msg.sender];
        require(sender.weight[proposal.subject.subjectId] > 0, "Has no right to vote");
        require(proposal.votes[msg.sender] == VoteStatus.NotVoted, "Already voted.");

        uint weight = sender.weight[proposal.subject.subjectId];
        addVoteToProposal(senderVote, proposal, weight);
        proposal.votes[msg.sender] = senderVote;
    }

    function voteForYes(uint proposalId) public {
        vote(proposalId, VoteStatus.VotedYes);
    }

    function voteForNo(uint proposalId) public {
        vote(proposalId, VoteStatus.VotedNo);
    }

    function abstain(uint proposalId) public {
        vote(proposalId, VoteStatus.Abstention);
    }

    function unvote(uint proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Open, "This proposal is closed.");

        Voter storage sender = voters[msg.sender];
        require(sender.weight[proposal.subject.subjectId] > 0, "Has no right to vote");
        VoteStatus senderVote = proposal.votes[msg.sender];
        require(senderVote != VoteStatus.NotVoted, "Not voted yet.");

        uint weight = sender.weight[proposal.subject.subjectId];
        subVoteToProposal(senderVote, proposal, weight);
        proposal.votes[msg.sender] = VoteStatus.NotVoted;
    }

    function createSubject(string memory description) public onlyAdmin returns (uint) {
        Subject storage newSubject = subjects.push();
        newSubject.subjectId = subjects.length - 1;
        newSubject.description = description;

        return newSubject.subjectId;
    }

    function createProposal(string memory link, uint subjectId) public onlyAdmin returns (uint) {
        Proposal storage newProposal = proposals.push();
        newProposal.proposalId = proposals.length - 1;
        newProposal.proposer = msg.sender;
        newProposal.link = link;
        newProposal.subject = subjects[subjectId];
        newProposal.status = ProposalStatus.Open;

        emit ProposalCreated(newProposal.proposalId, newProposal.subject);

        return newProposal.proposalId;
    }

    function closeProposal(uint proposalId) public onlyAdmin {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Open, "This proposal is already closed.");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = ProposalStatus.Approved;
            emit ProposalApproved(proposalId, proposal.subject);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalRejected(proposalId, proposal.subject);
        }
    }
}
