// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title Template for appointing the moderators of the DAO
 */
contract DAOModerators is Ownable {
    struct Moderator {
        string name;
        string email;
        address moderatorAddress;
    }
    Moderator[] public moderators;

    event LogNewModerator(string name, string email, address moderatorAddress);

    constructor(
        string memory _name,
        string memory _email,
        address _moderatorAddress
    ) {
        moderators.push(Moderator(_name, _email, _moderatorAddress));
    }

    function getModerators() public view returns (Moderator[] memory) {
        return moderators;
    }

    function setNewModerator(
        string memory _name,
        string memory _email,
        address _moderatorAddress
    ) public onlyOwner {
        emit LogNewModerator(_name, _email, _moderatorAddress);
        moderators.push(Moderator(_name, _email, _moderatorAddress));
    }

    function deleteModerators() public onlyOwner {
        delete moderators;
    }
}
