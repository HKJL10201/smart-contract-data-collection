//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Voting.sol";
// import "./Token.sol";

contract ManageVoting {
    Voting voting;
    // Token token;

    address public owner;
    string[] public nameElections;
    bool isControlledVoting;

    //sets owner,
    //owner added as a stakeholder
    constructor(address _address) {
        // token = Token(_token);
        voting = Voting(_address);
        owner = msg.sender;
    }

    uint256 private electionsCount = 0;
    //EVENTS
    event CreateElection(address sender, string _electionName);
    event AddCandidate(address sender, string _electionName, string _name);
    event Vote(address sender, string _electionName, uint256 _candidateID);
    event ChangeVoteStatus(address sender, string _electionName);
    event EnableVoting(address sender);
    event StopVoting(address sender);

    event AddStakeholder(address sender);
    event AddBod(address sender);
    event AddStaff(address sender);
    event RemoveStakeholderRole(address sender);

    //MAPPING
    mapping(string => Voting) public elections;
    mapping(address => bool) public stakeholders;
    mapping(address => bool) public staff;
    mapping(address => bool) public bod;
    mapping(address => bool) public student;

    //MODIFIERS
    modifier onlyChairman() {
        require(msg.sender == owner, "Chairman only access");
        _;
    }

    // modifier staffOnly() {
    //     uint256 balance = token.balanceOf(msg.sender);
    //     require(balance > 99, "You are not a staff");
    //     _;
    // }

    // modifier bodOnly() {
    //     uint256 balance = token.balanceOf(msg.sender);
    //     require(balance > 199, "You are not a BOD");
    //     _;
    // }

    modifier stakeholderOnly() {
        require(stakeholders[msg.sender], "You are not a stakeholder");
        _;
    }

    //FUNCTIONS
    function transferChairmanRole(address _adr) public onlyChairman {
        owner = _adr;
    }

    function enableVoting(string memory _electionName) public onlyChairman {
        elections[_electionName].enableVoting();
        emit EnableVoting(msg.sender);
    }

    function disableVoting(string memory _electionName) public onlyChairman {
        elections[_electionName].disableVoting();
        emit StopVoting(msg.sender);
    }

    function allowResultCompile(string memory _electionName)
        public
        onlyChairman
    {
        elections[_electionName].allowResult();
        emit ChangeVoteStatus(msg.sender, _electionName);
    }

    //add stakeholder
    function setStakeholders(address _adr) public onlyChairman returns (bool) {
        return stakeholders[_adr] = true;
    }

    //Create new instance of the voting contract
    //only chairman can create election
    function createElection(string memory _electionName, string memory category)
        public
        onlyChairman
        returns (bool)
    {
        Voting myVote = new Voting();
        elections[_electionName] = myVote;
        elections[_electionName].setVotingAccess(category);
        //increment the number of elections added
        electionsCount++;
        nameElections.push(_electionName);
        emit CreateElection(msg.sender, _electionName);
        return true;
    }

    //add candidate
    function addCandidate(
        string memory _electionName,
        string memory _name,
        string memory _img
    ) public onlyChairman returns (bool) {
        elections[_electionName].addCandidate(_name, _img);
        emit AddCandidate(msg.sender, _electionName, _name);
        return true;
    }

    //stakeholders only vote
    function vote(string memory _electionName, uint256 _candidateID)
        public
        returns (bool)
    {
        require(stakeholders[msg.sender], "You are not a stakeholder");

        // string memory va = elections[_electionName].getVotingAccess();

        // if (keccak256(bytes(va)) == keccak256(bytes("bod"))) {
        //     uint256 balance = token.balanceOf(msg.sender);
        //     require(
        //         balance > 199 * 10**18,
        //         "You are not a member of the board of directors"
        //     );
        // }

        // if (keccak256(bytes(va)) == keccak256(bytes("staff"))) {
        //     uint256 balance = token.balanceOf(msg.sender);
        //     require(
        //         balance > 99 * 10**18,
        //         "You are not a member of the staffs"
        //     );
        // }

        // if (keccak256(bytes(va)) == keccak256(bytes("student"))) {
        //     uint256 balance = token.balanceOf(msg.sender);
        //     require(balance < 99 * 10**18, "You are not a member of student");
        // }
        address voterAddress = msg.sender;
        elections[_electionName].vote(_candidateID, voterAddress);
        emit Vote(msg.sender, _electionName, _candidateID);
        return true;
    }

    //get list of all election
    function getAllElection() public view returns (string[] memory) {
        return nameElections;
    }

    //get list of all candidate for election name argument
    function getAllCandidate(string memory _electionName)
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        return elections[_electionName].getAllCandidates();
    }

    //get result of an election name argument
    function getResults(string memory _electionName)
        public
        view
        returns (string[] memory, uint256[] memory)
    {
        return elections[_electionName].compileResult();
    }


    //number of voter
    function getNumberOfVoters(string memory _electionName) public view returns (uint) {
        return elections[_electionName].getNumberOfVoters();
    }


    //get voters voting status

    function getVoter(string memory _electionName) public view returns (bool) {
        return elections[_electionName].getVoters();
    }

    function getVotingStatus(string memory _electionName)
    public
    view returns(Voting.VotingStatus) {
        return elections[_electionName].getVotingStatus();
    }


    function giveStaffRole(address _adr) public onlyChairman {
        // token.transfer(_adr, 100 * 10**18);
        stakeholders[_adr] = true;
        staff[_adr] = true;
        emit AddStaff(_adr);
    }

    function giveBodRole(address _adr) public onlyChairman {
        // token.transfer(_adr, 200 * 10**18);
        stakeholders[_adr] = true;
        bod[_adr] = true;
        emit AddBod(_adr);
    }

    function giveStakeholderRole(address _adr) public onlyChairman {
        // token.transfer(_adr, 10 * 10**18);
        stakeholders[_adr] = true;
        emit AddStakeholder(_adr);
    }

    function removeStakeholderRole(address _adr) public onlyChairman {
        stakeholders[_adr] = false;
        emit RemoveStakeholderRole(_adr);
    }
}
