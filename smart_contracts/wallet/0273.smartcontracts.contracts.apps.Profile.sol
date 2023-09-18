// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Profile is
    Initializable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 constant NULL = "";

    /// only a single username per address
    ///
    /// allows us to check which username was already reserved by a profile
    mapping(address profile => bytes32 username) public usernames;

    /// only a single username per profile
    ///
    /// allows us to easily fetch a profile from a username
    mapping(bytes32 username => address profile) public profiles;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Profile", "PRF");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function set(
        address profile,
        bytes32 _username,
        string memory _uri
    ) public returns (uint256) {
        require(profile == msg.sender, "Only the profile owner can set it.");

        bytes32 currentUsername = usernames[profile];

        require(
            (currentUsername == NULL &&
                (profiles[_username] == address(0) ||
                    profiles[_username] == profile)) || // username is not set and is also not reserved
                (currentUsername != NULL &&
                    profiles[currentUsername] == profile), // username is set but belongs to the profile
            "This username is already taken."
        );

        uint256 newProfileId = _fromAddressToId(profile);
        if (!_exists(newProfileId)) {
            _mint(profile, newProfileId);
        }
        if (currentUsername != _username) {
            _setUsername(profile, _username);
        }
        if (
            keccak256(abi.encodePacked(tokenURI(newProfileId))) !=
            keccak256(abi.encodePacked(_uri))
        ) {
            _setTokenURI(newProfileId, _uri);
        }

        return newProfileId;
    }

    function get(address profile) public view returns (string memory) {
        uint256 profileId = _fromAddressToId(profile);
        return tokenURI(profileId);
    }

    function getFromUsername(
        bytes32 username
    ) public view returns (string memory) {
        address profile = profiles[username];
        require(profile != address(0), "This username does not exist.");

        uint256 profileId = _fromAddressToId(profile);
        return tokenURI(profileId);
    }

    function burn(uint256 tokenId) external {
        address profileOwner = _fromIdToAddress(tokenId);
        require(
            owner() == msg.sender || profileOwner == msg.sender,
            "Only the owner of the token or profile can burn it."
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal pure override {
        require(
            from == address(0) || to == address(0),
            "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner."
        );
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721URIStorageUpgradeable) {
        _unsetUsername(_fromIdToAddress(tokenId));
        super._burn(tokenId);
    }

    function _setUsername(address profile, bytes32 username) internal {
        if (usernames[profile] != NULL) {
            // clean up old username if it exists
            delete profiles[usernames[profile]];
        }

        profiles[username] = profile;
        usernames[profile] = username;
    }

    function _unsetUsername(address _profile) internal {
        bytes32 username = usernames[_profile];

        delete profiles[username];
        delete usernames[_profile];
    }

    function _fromIdToAddress(uint256 tokenId) internal pure returns (address) {
        return address(uint160(uint256(tokenId)));
    }

    function _fromAddressToId(address profile) internal pure returns (uint256) {
        return uint256(uint160(profile));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
