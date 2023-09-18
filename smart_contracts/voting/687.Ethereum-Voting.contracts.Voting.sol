// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {
    address public owner;
    bool public flag = false;
    uint256 public resultFlag = 0;
    struct voter {
        string name;
        uint256 id;
        bool status;
        bool votted;
    }
    mapping(address => voter) public voters;
    struct candidate {
        string name;
        string party;
        uint256 age;
        uint256 votes;
    }
    candidate[] public newCandidates;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Must be Admin");
        _;
    }

    modifier check_voter() {
        require(voters[msg.sender].status, "You are not Voter");
        _;
    }

    function addVoters(string memory _name, uint256 _id) public {
        require(!voters[msg.sender].status, "You are already Added");
        voters[msg.sender] = voter(_name, _id, true, false);
    }

    function addCandidate(
        string memory _name,
        uint256 _age,
        string memory _party
    ) public ownerOnly {
        candidate memory nCandidate = candidate({
            name: _name,
            party: _party,
            age: _age,
            votes: 0
        });
        newCandidates.push(nCandidate);
    }

    function vote(uint256 index) public check_voter {
        require(!voters[msg.sender].votted, "You Already Votted");
        newCandidates[index].votes += 1;
        voters[msg.sender].votted = true;
    }

    function set_flag() public {
        flag = !flag;
        resultFlag += 1;
    }

    function get_length() public view returns (uint256) {
        return newCandidates.length;
    }

    function get_candidateList() public view returns (candidate[] memory) {
        return newCandidates;
    }

    function get_vottedDetails() public view returns (bool) {
        return (voters[msg.sender].votted);
    }
}
