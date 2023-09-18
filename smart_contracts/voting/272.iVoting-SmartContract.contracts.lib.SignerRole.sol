pragma solidity ^0.5.0;

import "./Roles.sol";
import "./MasterRole.sol";


contract SignerRole is MasterRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signer;

    constructor () internal {
        _addSigner(msg.sender);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signer.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function removeSigner(address account) public onlyMaster {
        _removeSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(msg.sender);
    }

    function _addSigner(address account) internal {
        _signer.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signer.remove(account);
        emit SignerRemoved(account);
    }
}
