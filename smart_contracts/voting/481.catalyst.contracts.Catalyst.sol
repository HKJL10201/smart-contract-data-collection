//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./token/ERC20.sol";
import "./access/Ownable.sol";
import "./utils/IterableMapping.sol";
import "./ICatalyst.sol";

contract Catalyst is ICatalyst, Ownable {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private voters;

    /// Counter, number of vote per voters
    mapping(address => uint) private counters;

    /// Vote weight per role
    mapping(uint8 => uint8) private roles;

    /// Link name of the project to its struct (status, vote)
    mapping(string => Project) private projects;

    /**
     * @notice Register a voter and assign a role
     * @dev update `counters`for `_voterAddress`
     * @param _voterAddress, address to assign role
     * @param _role, id of the role to be affected to this voter
     */
    function registerVoter(address _voterAddress, uint8 _role)
        external
        onlyOwner
    {
        require(voters.get(_voterAddress) == 0, "Voter already exists");
        _assignVoter(_voterAddress, _role);
        emit voterAssigned(_voterAddress, _role);
    }

    /**
     * @notice Update a voter and assign a new role
     * @dev update `counters`for `_voterAddress`, _voterAddress must be a valid voter
     * @param _voterAddress, address to assign role
     * @param _role, id of the role to be affected to this voter
     */
    function updateVoter(address _voterAddress, uint8 _role)
        external
        onlyOwner
    {
        require(voters.get(_voterAddress) != 0, "Voter doesn't exists");
        _assignVoter(_voterAddress, _role);
        emit voterAssigned(_voterAddress, _role);
    }

    /**
     * @notice Remove a voter
     * @dev update `counters`for `_voterAddress` to 0, and remove voter
     * @param _voterAddress, address of the voter to be removed
     */
    function removeVoter(address _voterAddress) external onlyOwner {
        require(voters.get(_voterAddress) != 0, "Voter doesn't exists");
        counters[_voterAddress] = 0;
        voters.remove(_voterAddress);
        emit voterRemoved(_voterAddress);
    }

    /**
     * @notice Set a new Role and number of voting points to be assigned
     * @dev update `roles` for a `_voteWeight`
     * @param _role, id of the role to be created
     * @param _voteWeight, voting points to be assigned to this role
     */
    function addRole(uint8 _role, uint8 _voteWeight) external onlyOwner {
        require(_role > 0, "Cannot assign role 0");
        require(roles[_role] == 0, "Role already exists");
        roles[_role] = _voteWeight;
        emit RoleAdded(_role, _voteWeight);
    }

    /**
     * @notice Create a new Project
     * @dev update `projects` for a `_name` that represents the project
     * @param _name, name of the project to be created
     */
    function createProject(string memory _name) external onlyOwner {
        require(projects[_name].exists == false, "Project already exists");
        projects[_name].exists = true;
        projects[_name].status = true;
        projects[_name].votes = 0;
        emit ProjectAdded(_name);
    }

    /**
     * @notice Close Project
     * @dev update `projects[_name]` status to false
     * @param _name, name of the project to be closed
     */
    function closeProject(string memory _name) external onlyOwner {
        require(projects[_name].status == true, "Vote closed");
        projects[_name].status = false;
        emit ProjectClosed(_name);
    }

    /**
     * @notice Set Voters, assign for each `voter` voting points corresponding to its role
     * @dev update `counters` for each `voter` with voting points
     */
    function setVoters() external onlyOwner {
        for (uint i = 0; i < voters.size(); i++) {
            address voter = voters.getKeyAtIndex(i);
            counters[voter] = roles[voters.get(voter)];
            emit VotingPointsUpdated(voter, counters[voter]);
        }
    }

    /**
     * @notice Prune Voters, remove all voting points for each voters
     * @dev set `counters` for each `voter` to `0`
     */
    function pruneVoters() external onlyOwner {
        for (uint i = 0; i < voters.size(); i++) {
            address voter = voters.getKeyAtIndex(i);
            counters[voter] = 0;
            emit VotingPointsUpdated(voter, 0);
        }
    }

    /**
     * @notice Vote for the `_projectName` with the `_amount` of voting points
     * @dev sub `counters` for `_amount` of voting points and add it to the `project`
     * @param _projectName, name of the project to be voted
     * @param _amount, amount of voting points to be affected to the project
     */
    function vote(string memory _projectName, uint _amount) external {
        require(projects[_projectName].status == true, "Vote closed");
        require(counters[_msgSender()] >= _amount, "Not enough vote");
        counters[_msgSender()] -= _amount;
        projects[_projectName].votes += _amount;
        emit Voted(_projectName, _msgSender(), _amount);
    }

    /**
     * @notice Number of Voting points for the `_voter`
     * @param _voter, address of the voter
     * @return uint, amount of voting point for this `_voter`
     */
    function getVotingPoints(address _voter) external view returns (uint) {
        return counters[_voter];
    }

    /**
     * @notice Number of Votes affected to this project
     * @param _name, name of the project
     * @return uint, number of votes for this `project`
     */
    function getProjectVotes(string calldata _name)
        external
        view
        returns (uint)
    {
        require(projects[_name].exists, "Project doesn't exist");
        return projects[_name].votes;
    }

    /**
     * @notice Number of Voting points for this `_role`
     * @param _role, id of the role
     * @return uint, amount of voting point for this `_role`
     */
    function getRoleWeight(uint8 _role) external view returns (uint8) {
        return roles[_role];
    }

    /**
     * @notice Id of the role affected to this `_voterAddress`
     * @param _voterAddress, address of the voter
     * @return uint8, id of the `role` affected to this `_voterAddress`
     */
    function getVoterRole(address _voterAddress) external view returns (uint8) {
        return voters.get(_voterAddress);
    }

    function _assignVoter(address _voterAddress, uint8 _role) private {
        require(roles[_role] != 0, "Trying to assign a non-existing role");
        voters.set(_voterAddress, _role);
    }
}
