// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface IVote {
    function initialize(uint _election_id, string memory _postion_title, address _manager, uint256 _election_duration) external;
}



contract Factory {
    mapping(uint => address) public contracts;
    address implementation;
    uint256 contract_index;

    // setting implementation contract address
    constructor(address _implementation) {
        implementation = _implementation;
    }

    event Created();

    function create(
        uint _election_id, 
        string memory _postion_title, 
        address _manager, 
        uint256 _election_duration
    ) public {
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, _election_id));
        address pair = Clones.cloneDeterministic(implementation, salt);
        IVote(pair).initialize(_election_id, _postion_title, _manager, _election_duration);
        emit Created();
    }

    function returnContractList() public view returns(uint256 ) {
        return contract_index;
    }
}