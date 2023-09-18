// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MultiOwnable is Initializable {
    
    address[] internal _owners;
    mapping (address => bool) internal _ownership;

    modifier onlyAnOwner {
        require(_ownership[msg.sender], "Not an owner!");
        _;
    }
    
    function initializeMultiOwnable(address[] memory owners)
        public
        virtual
        initializer
    {
        for (uint i=0; i < owners.length; i++) {
            require(owners[i] != address(0), "Owner with 0 address!");
            require(!_ownership[owners[i]], "Duplicate owner address!");
            _owners.push(owners[i]);
            _ownership[owners[i]] = true;
        }
        assert(_owners.length == owners.length);
    }
    
    // Functions for Developer testing 
    function getOwners() external view returns (address[] memory owners){
        return _owners;
    }
      
}