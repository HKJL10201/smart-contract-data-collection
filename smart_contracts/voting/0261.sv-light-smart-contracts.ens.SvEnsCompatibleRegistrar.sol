pragma solidity ^0.4.20;

import "./ENS.sol";

/**
 * A registrar that allocates subdomains to the first admin to claim them
 */
contract SvEnsCompatibleRegistrar {
    ENSIface public ens;
    bytes32 public rootNode;
    mapping (bytes32 => bool) knownNodes;
    mapping (address => bool) admins;
    address public owner;


    modifier req(bool c) {
        require(c);
        _;
    }


    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param node The node that this registrar administers.
     */
    constructor(ENSIface ensAddr, bytes32 node) public {
        ens = ensAddr;
        rootNode = node;
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    function addAdmin(address newAdmin) req(admins[msg.sender]) external {
        admins[newAdmin] = true;
    }

    function remAdmin(address oldAdmin) req(admins[msg.sender]) external {
        require(oldAdmin != msg.sender && oldAdmin != owner);
        admins[oldAdmin] = false;
    }

    function chOwner(address newOwner, bool remPrevOwnerAsAdmin) req(msg.sender == owner) external {
        if (remPrevOwnerAsAdmin) {
            admins[owner] = false;
        }
        owner = newOwner;
        admins[newOwner] = true;
    }

    /**
     * Register a name that's not currently registered
     * @param subnode The hash of the label to register.
     * @param _owner The address of the new owner.
     */
    function register(bytes32 subnode, address _owner) req(admins[msg.sender]) external {
        _setSubnodeOwner(subnode, _owner);
    }

    /**
     * Register a name that's not currently registered
     * @param subnodeStr The label to register.
     * @param _owner The address of the new owner.
     */
    function registerName(string subnodeStr, address _owner) req(admins[msg.sender]) external {
        // labelhash
        bytes32 subnode = keccak256(abi.encodePacked(subnodeStr));
        _setSubnodeOwner(subnode, _owner);
    }

    /**
     * INTERNAL - Register a name that's not currently registered
     * @param subnode The hash of the label to register.
     * @param _owner The address of the new owner.
     */
    function _setSubnodeOwner(bytes32 subnode, address _owner) internal {
        require(!knownNodes[subnode]);
        knownNodes[subnode] = true;
        ens.setSubnodeOwner(rootNode, subnode, _owner);
    }
}
