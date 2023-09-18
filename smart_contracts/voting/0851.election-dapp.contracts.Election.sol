// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Election is Ownable {
    //The voter must be validated by election admin.
    //This is to ensure only authorized people can vote.
    constructor(address admin) Ownable() {
        transferOwnership(admin);
        _admin = admin;
    }

    struct Voter {
        address id;
        bool hasRightToVote;
        bool hasVoted;
        uint8 vote;
    }
    struct Proposal {
        string statement;
        uint8 voteCount;
    }

    mapping(address => Voter) private voters;
    Proposal[] private proposals;

    address private _admin;
    Voter[] private voterArr;

    modifier isValidVoter(address id) {
        require(voters[id].hasRightToVote, "No right to vote");
        require(!voters[id].hasVoted, "voter already voted");
        _;
    }

    modifier isValidProp(uint8 toProp) {
        require(toProp >= 0 && toProp < proposals.length, "Invalid");
        _;
    }

    //The vote function checks if :-
    // 1.The voter has right to vote.
    // 2.If the voter has already voted.
    // 3.The proposal which is to be voted exists or not.

    function vote(uint8 toProposal)
        public
        isValidVoter(msg.sender)
        isValidProp(toProposal)
    {
        Voter storage sender = voters[msg.sender];
        sender.hasVoted = true;
        sender.vote = toProposal;
        //TODO(change voteCount to 1 when voting for 1st time)
        proposals[toProposal].voteCount++;
    }

    function addProp(string memory _statement) public onlyOwner {
        /*
        TODO(Initialize with -1 to diff b/w 0 votes and newly added) 
        */
        proposals.push(Proposal(_statement, 0));
    }

    function addVoter(address id) public onlyOwner {
        Voter memory newVoter = Voter(id, true, false, 0);
        voterArr.push(newVoter);
        uint256 index = voterArr.length - 1;
        voters[id] = voterArr[index];
    }

    //The winning proposal must have greater than 2 votes
    //All the proposals are compared against the proposal with maximum votes.
    //After the vote counting process the winning proposal's index is returned.
    function winningProposal()
        public
        view
        onlyOwner
        returns (int256 _winningProposal)
    {
        uint8 winningVoteCount = 2;
        _winningProposal = -1;
        for (uint256 index = 0; index < proposals.length; index++) {
            if (proposals[index].voteCount > winningVoteCount) {
                winningVoteCount = proposals[index].voteCount;
                _winningProposal = int256(index);
            }
        }
        return _winningProposal;
    }

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getProp() public view returns (Proposal[] memory) {
        return proposals;
    }

    function getVoters() public view returns (Voter[] memory) {
        return voterArr;
    }

    function getElecAddr() external view returns (address) {
        return address(this);
    }

    function hasVoted() external view returns (bool) {
        return voters[msg.sender].hasVoted;
    }
}
