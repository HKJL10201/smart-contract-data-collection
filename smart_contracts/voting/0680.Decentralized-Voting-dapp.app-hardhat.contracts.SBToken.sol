// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract SBToken {
    struct Soul {
        string name;
        string email;
        uint8 age;
        bool KYC;
        uint8 roleWeight;
        address owner;
    }

    mapping(address => Soul) private souls;

    string public title;

    modifier onlyAdmin() {
        require(souls[msg.sender].roleWeight == 2, "Not an Admin");
        _;
    }

    modifier onlyModerator() {
        require(souls[msg.sender].roleWeight > 0, "Not a moderator");
        _;
    }

    constructor(
        string memory _title,
        string memory _name,
        string memory _email,
        uint8 _age
    ) {
        title = _title;
        createSoul(_name, _email, _age);
        souls[msg.sender].roleWeight = 2;
        souls[msg.sender].KYC = true;
    }

    function createSoul(
        string memory _name,
        string memory _email,
        uint8 _age
    ) public {
        require(souls[msg.sender].owner == address(0), "Soul already exists");

        address addrSoul = msg.sender;
        souls[addrSoul].name = _name;
        souls[addrSoul].email = _email; // <-- bug was here
        souls[addrSoul].age = _age;
        souls[addrSoul].owner = addrSoul;
    }

    function deleteSoul(address addrSoul) public onlyModerator {
        require(souls[msg.sender].owner != address(0), "Soul does not exist");
        delete souls[addrSoul];
    }

    function turnKYC(address addrSoul, bool _kyc) public onlyModerator {
        require(souls[msg.sender].owner != address(0), "Soul does not exist");
        souls[addrSoul].KYC = _kyc;
    }

    function updateDataSoul(
        string memory _name,
        string memory _email,
        uint8 _age
    ) public {
        require(souls[msg.sender].owner != address(0), "Soul does not exist");

        address addrSoul = msg.sender;
        souls[addrSoul].name = _name;
        souls[addrSoul].email = _email;
        souls[addrSoul].age = _age;
    }

    function checkKYC(address addrSoul) public view returns (bool) {
        return souls[addrSoul].KYC ? true : false;
    }

    function checkIdentity(address addrSoul) public view returns (bool) {
        return souls[addrSoul].owner != address(0) ? true : false;
    }

    function getSoul(address addrSoul) public view returns (Soul memory) {
        return souls[addrSoul];
    }

    function getRole(address addrSoul) public view returns (uint8) {
        return souls[addrSoul].roleWeight;
    }

    function getOwner(address addrSoul) public view returns (address) {
        return souls[addrSoul].owner;
    }

    function addModerator(address user) public onlyAdmin {
        require(souls[msg.sender].owner != address(0), "Soul does not exist");
        require(souls[user].roleWeight < 1, "Already has role");
        souls[user].roleWeight = 1;
    }

    function removeModerator(address user) public onlyAdmin {
        require(souls[user].roleWeight != 2, "Admin can't be deleted");
        require(souls[user].roleWeight != 0, "Not a moderator");
        souls[user].roleWeight = 0;
    }
}
