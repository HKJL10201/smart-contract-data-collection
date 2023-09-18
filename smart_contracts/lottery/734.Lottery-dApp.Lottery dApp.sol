// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {
    address payable[] private applications;
    string[] private emails;
    address payable private owner;

    mapping(string => address) private hasApplied;

    constructor() {
        owner = payable(msg.sender);
    }

    function apply(string memory _email) payable public {
        require(hasApplied[_email] == address(0), "You have already applied");
        require(msg.value == 2 ether, "Must pay 2 ether to enter");

        applications.push(payable(msg.sender));
        emails.push(_email);
        hasApplied[_email] = msg.sender;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, applications.length)));
    }

    function pickWinner() public {
        require(msg.sender == owner, "Only the owner can call this function");
        require(applications.length > 0, "No applications available");

        uint256 index = random() % applications.length;
        address payable winner = applications[index];

        winner.transfer(address(this).balance);

        delete applications;
        delete emails;

        hasApplied[emails[index]] = address(0);
    }

    function getApplications() public view returns (address payable[] memory) {
        return applications;
    }

    function getEmails() public view returns (string[] memory) {
        return emails;
    }
}
