//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./Roles.sol";
import "./ownable.sol";

contract Voter is Ownable {
    using Roles for Roles.Role;

    address private _owner;
    event voterAdded(address indexed account);
    event voterRemoved(address indexed account);

    Roles.Role private voter;

    constructor() {
        _owner = msg.sender;
    }

    // modifier onlyOwner() {
    //     require(_owner == msg.sender);
    //     _;
    // }

    modifier isVoter(address _address) {
        require(isAlreadyVoter(_address));
        _;
    }

    modifier nonVoter(address _address) {
        require(!isAlreadyVoter(_address));
        _;
    }

    function destoryContract() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function isAlreadyVoter(address _address) public view returns (bool) {
        return voter.has(_address);
    }

    function addVoter(
        address _address,
        string memory _addharCard,
        string memory _voterArea
    ) public {
        _addVoter(_address, _addharCard, _voterArea);
    }

    function _addVoter(
        address _address,
        string memory _addharCard,
        string memory _voterArea
    ) private nonVoter(_address) onlyOwner() {
        voter.add(_address, _addharCard, _voterArea);
        emit voterAdded(_address);
    }

    function removeVoter(address _address) public {
        _removeVoter(_address);
    }

    function _removeVoter(address _address)
        private
        isVoter(_address)
        onlyOwner()
    {
        voter.remove(_address);
        emit voterRemoved(_address);
    }

    function getVoterArea(address _address)
        public
        view
        returns (string memory)
    {
        return voter.getArea(_address);
    }
}
