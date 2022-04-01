pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;


interface IENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(bytes32 node, bytes32 label, address owner)
        external
        returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}


interface IRegistrar {
    function register(bytes32 label, address owner) external;
}


interface IResolver {
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(
        bytes32 indexed node,
        string indexed indexedKey,
        string key
    );
    event ContenthashChanged(bytes32 indexed node, bytes hash);
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function ABI(bytes32 node, uint256 contentTypes)
        external
        view
        returns (uint256, bytes memory);

    function addr(bytes32 node) external view returns (address);

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);

    function contenthash(bytes32 node) external view returns (bytes memory);

    function dnsrr(bytes32 node) external view returns (bytes memory);

    function name(bytes32 node) external view returns (string memory);

    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);

    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);

    function interfaceImplementer(bytes32 node, bytes4 interfaceID)
        external
        view
        returns (address);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data)
        external;

    function setAddr(bytes32 node, address addr) external;

    function setAddr(bytes32 node, uint256 coinType, bytes calldata a) external;

    function setContenthash(bytes32 node, bytes calldata hash) external;

    function setDnsrr(bytes32 node, bytes calldata data) external;

    function setName(bytes32 node, string calldata _name) external;

    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;

    function setText(bytes32 node, string calldata key, string calldata value)
        external;

    function setInterface(bytes32 node, bytes4 interfaceID, address implementer)
        external;

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);

    function multihash(bytes32 node) external view returns (bytes memory);

    function setContent(bytes32 node, bytes32 hash) external;

    function setMultihash(bytes32 node, bytes calldata hash) external;
}


interface IReverseRegistrar {
    function ADDR_REVERSE_NODE() external pure returns (bytes32);

    function claim(address owner) external returns (bytes32);

    function claimWithResolver(address owner, address resolver)
        external
        returns (bytes32);

    function setName(string calldata name) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}
