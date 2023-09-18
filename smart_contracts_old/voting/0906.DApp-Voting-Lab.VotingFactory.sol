// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import './Voting.sol';

contract VotingFactory  {
    
    address public implementation;
    mapping (address => bool) public isValid;
    
    event contractCreated(address addr);
    
    constructor(address impl) {
        implementation = impl;
    }
    
    function newContract() external {
        address clone = Clones.clone(implementation);
        Voting(clone).initialize(msg.sender);
        isValid[clone] = true;
        emit contractCreated(clone);
    }
    
}