// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./Election.sol";

contract ElectionFactory {
    struct ElecMeta {
        Election election;
        address adminAddr;
        address elecAddr;
        string name;
    }

    mapping(uint256 => ElecMeta) private idToMeta;
    mapping(string => bool) private takenNames;
    ElecMeta[] private elections;
    modifier validName(string memory _name) {
        require(!takenNames[_name], "Name already taken");
        _;
    }

    function addElection(string memory _name) public validName(_name) {
        takenNames[_name] = true;
        Election elec = new Election(msg.sender);
        uint256 _id = uint256(keccak256(abi.encodePacked(_name)));
        idToMeta[_id] = ElecMeta(elec, msg.sender, elec.getElecAddr(), _name);
        elections.push(idToMeta[_id]);
    }

    function getElection(string memory _name)
        external
        view
        returns (ElecMeta memory)
    {
        require(takenNames[_name], "The election does not exist");
        uint256 _id = uint256(keccak256(abi.encodePacked(_name)));
        return idToMeta[_id];
    }

    function getCurrentElections() external view returns (ElecMeta[] memory) {
        return elections;
    }
}
