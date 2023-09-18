pragma solidity ^0.4.24;

import { hasAdmins } from "./SVCommon.sol";
import "../ens/ENS.sol";
import "../ens/SvEnsResolver.sol";

/**
 * EnsOwnerProxy allows multiple identities to own / manage an ENS domain.
 */
contract EnsOwnerProxy is hasAdmins {
    bytes32 public ensNode;
    ENSIface public ens;
    PublicResolver public resolver;

    /**
     * @param _ensNode The node to administer
     * @param _ens The ENS Registrar
     * @param _resolver The ENS Resolver
     */
    constructor(bytes32 _ensNode, ENSIface _ens, PublicResolver _resolver) public {
        ensNode = _ensNode;
        ens = _ens;
        resolver = _resolver;
    }

    function setAddr(address addr) only_admin() external {
        _setAddr(addr);
    }

    function _setAddr(address addr) internal {
        resolver.setAddr(ensNode, addr);
    }

    function returnToOwner() only_owner() external {
        ens.setOwner(ensNode, owner);
    }

    function fwdToENS(bytes data) only_owner() external {
        require(address(ens).call(data), "fwding to ens failed");
    }

    function fwdToResolver(bytes data) only_owner() external {
        require(address(resolver).call(data), "fwding to resolver failed");
    }
}
