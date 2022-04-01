pragma solidity ^0.4.24;

// DELEGATION SC v1.2
// (c) SecureVote 2018
// Author: Max Kaye <max@secure.vote>
// Released under MIT licence

// the most up-to-date version of the contract lives at delegate.secvote.eth

// NOTE - This is WIP and might not get used.


import "./SVCommon.sol";
import "./SVDelegationV0101.sol";
import { MemArrApp } from "../libs/MemArrApp.sol";


contract SVDelegationBackend is permissioned {
    SVDelegationV0101 public v1DlgtSC;

    uint256 constant GLOBAL_NAMESPACE = 0;

    event NewDelegation(bytes32 indexed voter, uint64 id);

    // delegation structure - allows us to traverse reasonably easily
    struct Delegation {
        uint64 thisId;
        uint64 prevId;
        uint64 setAtBlock;
        bytes32 voter;
        bytes32 delegate;
        uint256 namespace;
    }

    struct Sig {
        // note: including the sig here bc it might let us use ed25519 in future - there
        // are problems in that anyone could claim a delegation for anyone else which
        // is why the signature is required - but probs better to include and not use than
        // need to upgrade later on.
        bytes32 sig1;
        bytes32 sig2;
    }

    // mappings for storing delegations
    // note: first uint256 is the namespace, the bytes32 is the users PK or address
    mapping (uint256 => mapping (bytes32 => uint64)) public rawDelegations;

    // allows user to wipe delegations - uses block numbers to invalidate _ALL_ delegations before a point
    // note: no point doing it per token bc or for just global (defualt dlgts) since the user
    // can just set their delegation to address(0)
    mapping (bytes32 => uint64) public _forgetDelegationsBefore;

    // track which token contracts we know about for easy traversal + backwards compatibility
    mapping (uint256 => bool) public _knownNamespaces;
    uint256[] public _logNamespaces;

    // track all delegations via an indexed map
    mapping (uint64 => Delegation) public _allDelegations;
    mapping (uint64 => Sig) public _delegationSigs;
    uint64 public totalDelegations = 1;  // the 0th delegation is all 0s - just a default.


    constructor(SVDelegationV0101 _prevSC) public {
        v1DlgtSC = _prevSC;
    }


    // handle inserting delegates into state
    function mkDelegation(bytes32 voter, bytes32 delegate, uint256 namespace) internal returns(uint64) {
        // use this to log known tokenContracts
        if (!_knownNamespaces[namespace]) {
            _logNamespaces.push(namespace);
            _knownNamespaces[namespace] = true;
        }

        uint64 prevDelegationId = rawDelegations[namespace][voter];
        uint64 myDelegationId = totalDelegations;
        _allDelegations[myDelegationId].thisId = myDelegationId;
        _allDelegations[myDelegationId].prevId = prevDelegationId;
        _allDelegations[myDelegationId].setAtBlock = uint64(block.number);
        _allDelegations[myDelegationId].voter = voter;
        _allDelegations[myDelegationId].delegate = delegate;
        _allDelegations[myDelegationId].namespace = namespace;

        rawDelegations[namespace][voter] = myDelegationId;
        totalDelegations += 1;

        emit NewDelegation(voter, myDelegationId);

        return myDelegationId;
    }


    function createEthTknDelegation(address voter, address delegate, address tokenContract) only_editors() external returns(uint64) {
        return mkDelegation(bytes32(voter), bytes32(delegate), uint256(tokenContract));
    }


    function createEthGlobalDelegation(address voter, address delegate) only_editors() external returns(uint64) {
        return mkDelegation(bytes32(voter), bytes32(delegate), GLOBAL_NAMESPACE);
    }


    function resetAllDelegations(bytes32 voter) only_editors() external {
        _forgetDelegationsBefore[voter] = uint64(block.number);
    }


    // Getter Functions


    function resolveRawDelegation(bytes32 voter, uint256 namespace) view external returns (uint64, bytes32, bytes32, uint256) {
        uint64 id = _getIdIfValid(voter, namespace);

        if (id == 0) {
            uint64 prevId;
            uint64 setAtBlock;
            address voterAddr;
            address delegate;
            address tknAddr;
            // note - order returned for prevDlgtSC is different to this contract
            (id, prevId, setAtBlock, delegate, voterAddr, tknAddr) = v1DlgtSC.resolveDelegation(address(voter), address(namespace));
            return (id, voter, bytes32(delegate), namespace);
        }

        return _dlgtRet(id);
    }


    // returns 2 lists: first of voter addresses, second of token contracts
    function findPossibleDelegatorsOf(address delegate) external view returns(address[] memory, address[] memory) {
        // not meant to be run on-chain, but off-chain via API, mostly convenience
        address[] memory voters;
        address[] memory tokenContracts;
        Delegation memory d;

        // first loop through delegations in this contract
        uint64 i;
        // start at 1 because the first delegation is a "genesis" delegation - all 0s
        for (i = 1; i < totalDelegations; i++) {
            d = _allDelegations[i];
            if (d.delegate == bytes32(delegate)) {
                // since `.push` isn't available on memory arrays, use their length as the next index location
                voters = MemArrApp.appendAddress(voters, address(d.voter));
                tokenContracts = MemArrApp.appendAddress(tokenContracts, address(d.namespace));
            }
        }

        // NOTE: due to limitation of solidity we can't pass back old delegations from earlier SC (v0101).
        // This is a bummer, but basically means whenever you call findPossibleDelegatorsOf you need to call it
        // on the v1 sc too. :/
        return (voters, tokenContracts);
    }


    // returns 2 lists: first of voter addresses, second of token contracts
    function findPossibleDelegatorsOfRaw(bytes32 delegate) external view returns(bytes32[] memory, uint256[] memory) {
        // not meant to be run on-chain, but off-chain via API, mostly convenience
        bytes32[] memory voters;
        uint256[] memory namespaces;
        Delegation memory d;

        // first loop through delegations in this contract
        uint64 i;
        // start at 1 because the first delegation is a "genesis" delegation - all 0s
        for (i = 1; i < totalDelegations; i++) {
            d = _allDelegations[i];
            if (d.delegate == bytes32(delegate)) {
                // since `.push` isn't available on memory arrays, use their length as the next index location
                voters = MemArrApp.appendBytes32(voters, d.voter);
                namespaces = MemArrApp.appendUint256(namespaces, d.namespace);
            }
        }

        // NOTE: due to limitation of solidity we can't pass back old delegations from earlier SC (v0101).
        // This is a bummer, but basically means whenever you call findPossibleDelegatorsOf you need to call it
        // on the v1 sc too. :/
        return (voters, namespaces);
    }


    // utils

    // internal function to test if a delegation is valid or revoked / nonexistent
    function _getIdIfValid(bytes32 voter, uint256 namespace) public view returns(uint64) {
        // probs simplest test to check if we have a valid delegation - important to check if delegation is set to 0x00
        // to avoid counting a revocation (which is done by delegating to 0x00). Also note that default for forgetDelegationsBefore
        // is 0, so we can do that instead of actually checking if it's non-zero.
        uint64 id = rawDelegations[namespace][voter];
        bool blockCheck = _allDelegations[id].setAtBlock > _forgetDelegationsBefore[voter];
        bool nonZeroDelegate = _allDelegations[id].delegate != bytes32(0);
        if (blockCheck && nonZeroDelegate) {
            return id;
        }
        return 0;
    }

    // convenience function to turn Delegations into a returnable structure
    function _dlgtRet(uint64 id) internal view returns(uint64, bytes32, bytes32, uint256) {
        Delegation memory d = _allDelegations[id];
        return (d.thisId, d.voter, d.delegate, d.namespace);
    }
}


// Main delegation contract v1.2
contract SVDelegationV0102 is owned, upgradePtr {
    SVDelegationBackend public backend;

    // pretty straight forward - events
    event SetEthGlobalDelegation(address voter, address delegate);
    event SetEthTokenDelegation(address voter, address delegate, address tokenContract);
    event SetDelegation(bytes32 voter, bytes32 delegate, uint256 namespace);

    // main constructor - requires the prevDelegationSC address
    constructor(SVDelegationBackend _backend) public {
        backend = _backend;
    }

    // upgrade handler
    function doUpgrade(address newSC) only_owner() public {
        backend.upgradeMe(newSC);
        doUpgradeInternal(newSC);
    }

    // get previous delegation, create new delegation via function and then commit to globalDlgts
    function setGlobalDelegation(address delegate) not_upgraded() public returns(uint64) {
        emit SetEthGlobalDelegation(msg.sender, delegate);
        return backend.createEthGlobalDelegation(msg.sender, delegate);
    }

    // get previous delegation, create new delegation via function and then commit to tokenDlgts
    function setTokenDelegation(address delegate, address tokenAddress) not_upgraded() public returns(uint64) {
        emit SetEthTokenDelegation(msg.sender, delegate, tokenAddress);
        return backend.createEthTknDelegation(msg.sender, delegate, tokenAddress);
    }

    // given some voter and token address, get the delegation id - failover to global on 0 address
    function getDelegationID(address voter, address tokenAddress) public constant returns(uint64) {
        return backend._getIdIfValid(bytes32(voter), uint256(tokenAddress));
    }

    // keep interface compatibel with previous functions
    function resolveDelegation(address voter, address tokenAddress) public constant returns(uint64, uint64, uint64, address, address, address) {
        uint64 id;
        bytes32 delegate;
        bytes32 voterMeh;
        uint256 mehNS;

        (id, voterMeh, delegate, mehNS) = backend.resolveRawDelegation(bytes32(voter), uint256(tokenAddress));
        return (id, 0, 0, voter, address(delegate), tokenAddress);
    }

    // return (id, voter, delegate, namespace, sig1, sig2)
    function resolveRawDelegation(bytes32 voter, uint256 namespace) external constant returns(uint64, bytes32, bytes32, uint256) {
        return backend.resolveRawDelegation(voter, namespace);
    }
}
