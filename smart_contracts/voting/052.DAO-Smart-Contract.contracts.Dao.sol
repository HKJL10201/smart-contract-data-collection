pragma solidity >=0.7.0 <0.9.0;

contract Dao {
    struct Member {
        uint256 weight;
        bool voted;
        address delegate;
        uint256 vote;
        address member;
        uint256 location;
    }

    struct Proposal {
        bytes32 name;
        uint256 voteCount;
        address reciever;
    }

    address public chairperson;
    uint256 public balance;
    uint256 public numberOfMembers;

    mapping(address => Member) public members;

    Proposal[] public proposals;
    Member[] public members_list;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        Member memory chairpersonStruct = Member(
            1,
            false,
            address(0),
            0,
            msg.sender,
            0
        );
        members[chairperson] = chairpersonStruct;
        members_list.push(members[chairperson]);

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({
                    name: proposalNames[i],
                    voteCount: 0,
                    reciever: msg.sender
                })
            );
        }
        numberOfMembers = 1;
    }

    function joinDao() public payable {
        require(msg.value >= 200, "correctAmountNotDeposited");
        Member memory newMember = Member(
            0,
            false,
            address(0),
            0,
            msg.sender,
            numberOfMembers
        );
        members[msg.sender] = newMember;
        members_list.push(members[msg.sender]);
        balance += msg.value;
        numberOfMembers += 1;
    }

    function giveRightToVote(address member) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(!members[member].voted, "The member has already voted.");
        require(members[member].weight == 0);
        require(members[member].location != 0);
        members[member].weight = 1;
    }

    function getMembers() public view returns (address[] memory) {
        address[] memory _members_list = new address[](numberOfMembers);
        for (uint256 i = 0; i < members_list.length; i++) {
            _members_list[i] = members_list[i].member;
        }
        return _members_list;
    }

    function delegate(address to) external {
        Member storage sender = members[msg.sender];
        require(!sender.voted, "You already Voted!");
        require(to != msg.sender, "Self Delegation Disallowed");

        while (members[to].delegate != address(0)) {
            to = members[to].delegate;
            require(to != msg.sender, "Found loop in delegation");
        }

        sender.voted = true;
        sender.delegate = to;
        Member storage delegate_ = members[to];

        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint256 proposal) external {
        Member storage sender = members[msg.sender];
        require(sender.weight != 0, "No right to vote");
        require(!sender.voted, "Already Voted");

        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winingProposal() public view returns (uint256 winingProposal_) {
        uint256 winingVoteCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            winingVoteCount = proposals[i].voteCount;
            winingProposal_ = i;
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winingProposal()].name;
    }

    function newProposal(bytes32[] memory proposalNames) public {
        require(chairperson == msg.sender);

        members[chairperson].weight = 1;
        delete proposals;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({
                    name: proposalNames[i],
                    voteCount: 0,
                    reciever: msg.sender
                })
            );
        }

        for (uint256 i = 0; i < members_list.length; i++) {
            members_list[i].weight = 1;
            members[members_list[i].member] = members_list[i];
        }
    }
}
