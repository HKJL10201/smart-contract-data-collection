pragma solidity ^0.4.21;

import { SvEnsRegistry } from "../ens/SvEnsRegistry.sol";
import { PublicResolver } from "../ens/SvEnsResolver.sol";
import { SvEnsRegistrar } from "../ens/SvEnsRegistrar.sol";
import { owned, hasAdmins } from "./SVCommon.sol";

contract SvEnsEverythingPx is hasAdmins {

    SvEnsRegistrar public registrar;
    SvEnsRegistry public registry;
    PublicResolver public resolver;
    bytes32 public rootNode;

    constructor(SvEnsRegistrar _registrar, SvEnsRegistry _registry, PublicResolver _resolver, bytes32 _rootNode) public {
        registrar = _registrar;
        registry = _registry;
        resolver = _resolver;
        rootNode = _rootNode;
    }

    function _regName(bytes32 labelhash) internal returns (bytes32 node) {
        registrar.register(labelhash, this);
        node = keccak256(abi.encodePacked(rootNode, labelhash));
        registry.setResolver(node, resolver);
    }

    function regName(string name, address resolveTo) only_admin() external returns (bytes32 node) {
        bytes32 labelhash = keccak256(bytes(name));
        node = _regName(labelhash);
        resolver.setAddr(node, resolveTo);
        registry.setOwner(node, msg.sender);
    }

    function regNameWOwner(string name, address resolveTo, address domainOwner) only_admin() external returns (bytes32 node) {
        bytes32 labelhash = keccak256(bytes(name));
        node = _regName(labelhash);
        resolver.setAddr(node, resolveTo);
        registry.setOwner(node, domainOwner);
    }
}


// this is for backwards compatibility before EnsOwnerProxy used `hasAdmins`
interface SvEnsEverythingPxGen1Iface {
    function admins(address) external view returns (bool);
    function addAdmin(address) external;
}
