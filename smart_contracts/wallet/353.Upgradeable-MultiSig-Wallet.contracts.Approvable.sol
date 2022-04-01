// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Approvable is Initializable {
    
    address[] internal _approvers;
    mapping (address => bool) internal _approvership;
    uint internal _minApprovals;

    modifier onlyAnApprover {
         require(_approvership[msg.sender], "Not an approver!");
         _;
    }
    
    function initializeApprovable(address[] memory approvers, uint minApprovals)
        public
        virtual
        initializer
    {
        require(
            minApprovals <= approvers.length,
            "Minimum approvals > approvers!"
        );
        
        for (uint i=0; i < approvers.length; i++) {
            require(approvers[i] != address(0), "Approver has 0 address!");
            require(
                !_approvership[approvers[i]],
                "Duplicate approver address!"
            );
            _approvers.push(approvers[i]);
            _approvership[approvers[i]] = true;
        }
        _minApprovals = minApprovals;

        assert(_approvers.length == approvers.length);
    }

    // Functions for Developer testing 
    function getApprovers() external view returns (address[] memory approvers){
        return _approvers;
    }
    
    function getMinApprovals() external view returns (uint){
        return _minApprovals;
    }
}