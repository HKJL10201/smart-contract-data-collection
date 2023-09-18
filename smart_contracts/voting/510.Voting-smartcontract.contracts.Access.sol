//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Access {
    address public owner;

    constructor() {
        owner = msg.sender;
        bod[owner] = true;
        staff[owner] = true;
        stakeholders[owner] = true;
    }

    mapping(address => bool) public stakeholders;
    mapping(address => bool) public staff;
    mapping(address => bool) public bod;
    mapping(address => bool) public student;

    modifier staffOnly() {
        require(staff[msg.sender], "You are not a staff");
        _;
    }

    modifier bodOnly() {
        require(bod[msg.sender], "You are not a BOD");
        _;
    }

    modifier stakeholderOnly() {
        require(stakeholders[msg.sender], "You are not a stakeholder");
        _;
    }

    modifier onlyChairman() {
        require(msg.sender == owner, "Chairman only access");
        _;
    }

    function giveStaffRole(address _adr) public bodOnly {
        staff[_adr] = true;
    }

    function removeStaffRole(address _adr) public bodOnly {
        staff[_adr] = false;
    }

    function getStaffStatus() public view returns (bool) {
        require(staff[msg.sender] == true, "You are not a staff");
        return true;
    }

    function giveBodRole(address _adr) public bodOnly {
        bod[_adr] = true;
        staff[_adr] = true;
        stakeholders[_adr] = true;
    }

    function removeBodRole(address _adr) public bodOnly {
        bod[_adr] = false;
        staff[_adr] = false;
        stakeholders[_adr] = false;
    }

    function getBodStatus() public view returns (bool) {
        require(bod[msg.sender] == true, "You are not a BOD");
        return true;
    }

    function giveStakeholderRole(address _adr) public staffOnly {
        stakeholders[_adr] = true;
    }

    function removeStakeholderRole(address _adr) public staffOnly {
        stakeholders[_adr] = false;
    }

    function getStakeholderStatus() public view returns (bool) {
        require(bod[msg.sender] == true, "You are not a BOD");
        return true;
    }
}
