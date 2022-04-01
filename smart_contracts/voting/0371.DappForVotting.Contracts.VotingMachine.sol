//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./Roles.sol";
import "./voter.sol";
import "./Nomine.sol";

contract VotingMachine {
    // using Roles for Roles.Role;
    // Roles.Role private machine;

    Voter voter = new Voter();
    Nomine nomine = new Nomine();
    address nomineAddress;
    address _ownerOfContract;

    mapping(address => bool) voted; // for checking if perosn alreadyVoted
    mapping(address => uint64) votes; // for checking number of votes

    event doneVoting(address _address);

    constructor() {
        _ownerOfContract = msg.sender;
    }

    modifier onlyOwner() {
        require(_ownerOfContract == msg.sender);
        _;
    }

    modifier alreadyVoted(address _address) {
        // check if person is alreadyVoted
        require(!personAlreadyVoted(_address));
        _;
    }

    modifier isPersonVoter(address _address) {
        //check is person is voter
        require(voter.isAlreadyVoter(_address));
        _;
    }

    modifier isAreaMatch(address _voterPersonAddress) {
        // string memory voterAdd = voter.getVoterArea(_voterPersonAddress);
        // string memory nomineAdd = nomine.getNomineArea(nomineAddress);
        require(isAreadMached(_voterPersonAddress));
        _;
    }

    function destoryContract() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function isAreadMached(address _voterPersonAddress)
        private
        view
        returns (bool)
    {
        return
            keccak256(
                abi.encodePacked(voter.getVoterArea(_voterPersonAddress))
            ) == keccak256(abi.encodePacked(nomineAddress));
    }

    function loadNomineAddress(uint128 _nomineeNumber) private {
        nomineAddress = nomine.getNomineAddress(_nomineeNumber);
    }

    function addVote(address _voterPersonAddress, uint128 _nomineeNumber)
        public
    {
        loadNomineAddress(_nomineeNumber);
        _addVote(_voterPersonAddress);
    }

    function _addVote(address _voterPersonAddress)
        private
        isPersonVoter(_voterPersonAddress)
        alreadyVoted(_voterPersonAddress)
        isAreaMatch(_voterPersonAddress)
    {
        votes[nomineAddress] += 1;
        voted[_voterPersonAddress] = true;
        emit doneVoting(_voterPersonAddress);
    }

    function personAlreadyVoted(address _address) public view returns (bool) {
        return voted[_address];
    }

    function getVotes(address _address) public view returns (uint256) {
        return votes[_address];
    }
}
