// Note: Based in https://github.com/paulrberg/prb-proxy/blob/main/contracts/PRBProxy.sol

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IPRBProxy.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @notice Emitted when the caller is not the owner.
error PRBProxy__ExecutionNotAuthorized(address owner, address caller, address target, bytes4 selector);

/// @notice Emitted when execution reverted with no reason.
error PRBProxy__ExecutionReverted();

/// @notice Emitted when the caller is not the owner.
error PRBProxy__NotOwner(address owner, address caller);

/// @notice Emitted when the owner is changed during the DELEGATECALL.
error PRBProxy__OwnerChanged(address originalOwner, address newOwner);

/// @notice Emitted when passing an EOA or an undeployed contract as the target.
error PRBProxy__TargetInvalid(address target);

/// @notice Emitted when trying to send a pass when address already has one.
error PRBProxy__AlreadyOwnPass(address target);

/// @notice Emitted when calling address has no pass.
error PRBProxy__NoPassOwned(address sender);

/// @notice Emitted when limit is exceeded with the call.
error PRBPRroxy__LimitExceeded(address sender, uint256 limit);

/// @title PRBProxy
/// @author Paul Razvan Berg
contract PRBProxy is IPRBProxy, ERC721, ERC721Enumerable {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IPRBProxy
    address public override owner;

    /// @inheritdoc IPRBProxy
    uint256 public override minGasReserve;

    /// INTERNAL STORAGE ///

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    /// @notice Maps envoys to target contracts to function selectors to boolean flags.
    mapping(address => mapping(address => mapping(bytes4 => bool))) internal permissions;

    // Mapping from token ID to limit
    mapping(uint256 => uint256) private _limits;

    // Mapping from token ID to spent
    mapping(uint256 => uint256) private _spent;

    /// CONSTRUCTOR ///

    constructor() ERC721("ExpenseToken", "EXPENSE") {
        minGasReserve = 5_000;
        owner = msg.sender;
        // first call is with id zero as using auto increment
        _mintSpendooorPass(msg.sender, type(uint256).max);
        emit TransferOwnership(address(0), msg.sender);
    }

    /// FALLBACK FUNCTION ///

    /// @dev Called when Ether is sent and the call data is empty.
    receive() external payable {}

    /// INTERNAL FUNCTIONS ///

    /// The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        // Only allow 1 pass allowed per address
        if (balanceOf(to) > 0) {
            revert PRBProxy__AlreadyOwnPass(to);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// The previos functions are overrides required by Solidity.

    // Mint spendooor pass to an address with the given limit
    function _mintSpendooorPass(address to, uint256 limit) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _limits[tokenId] = limit;
        return tokenId;
    }


    /// PUBLIC CONSTANT FUNCTIONS ///

    // NOTE: We don't use permissions now, we will check NFT owning and spending limits for now
    /// @inheritdoc IPRBProxy
    function getPermission(
        address envoy,
        address target,
        bytes4 selector
    ) external view override returns (bool) {
        return permissions[envoy][target][selector];
    }

    function limitOf(uint256 tokenId) public view returns (uint256) {
        return _limits[tokenId];
    }

    function spentOf(uint256 tokenId) public view returns (uint256) {
        return _spent[tokenId];
    }

    function spendableOf(uint256 tokenId) public view returns (uint256) {
        return limitOf(tokenId) - spentOf(tokenId);
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    // External facing function for minting spendooor pass to an address with the given limit
    function mintSpendooorPass(address to, uint256 limit) external returns (uint256) {
        if (ownerOf(0) != msg.sender) {
            revert PRBProxy__NotOwner(owner, msg.sender);
        }
        return _mintSpendooorPass(to, limit);        
    }

    function setLimit(uint256 tokenID, uint256 limit) external {
        if (ownerOf(0) != msg.sender) {
            revert PRBProxy__NotOwner(owner, msg.sender);
        }
        _limits[tokenID] = limit;
    }

    /// @inheritdoc IPRBProxy
    function execute(address target, uint256 value, bytes calldata data) external payable override returns (bytes memory response) {
        // Check that the caller is either the owner or an envoy.
        // NOTE: We don't use permissions now, we will check NFT owning and spending limits for now
        // if (owner != msg.sender) {
        //     bytes4 selector;
        //     assembly {
        //         selector := calldataload(data.offset)
        //     }
        //     if (!permissions[msg.sender][target][selector]) {
        //         revert PRBProxy__ExecutionNotAuthorized(owner, msg.sender, target, selector);
        //     }
        // }

        // Check that the target is a valid contract.
        if (target.code.length == 0) {
            revert PRBProxy__TargetInvalid(target);
        }

        // Save the owner address in memory. This local variable cannot be modified during the DELEGATECALL.
        address owner_ = owner;

        // Reserve some gas to ensure that the function has enough to finish the execution.
        uint256 stipend = gasleft() - minGasReserve;

        // Check if caller owns Expense NFT
        if (balanceOf(msg.sender) == 0) {
            revert PRBProxy__NoPassOwned(msg.sender);
        }

        // Check if caller does not exceeded spending limit
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        uint256 limit = limitOf(tokenId);
        uint256 spent = spentOf(tokenId);
        uint256 spendable = spendableOf(tokenId);
        if (value > spendable) {
            revert PRBPRroxy__LimitExceeded(msg.sender, limit);
        }

        _spent[tokenId] = _spent[tokenId] + value;

        // Delegate call to the target contract.
        bool success;
        (success, response) = target.call{ gas: stipend, value: value }(data);

        // Check that the owner has not been changed.
        if (owner_ != owner) {
            revert PRBProxy__OwnerChanged(owner_, owner);
        }

        // Log the execution.
        emit Execute(target, data, response);

        // Check if the call was successful or not.
        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (response.length > 0) {
                assembly {
                    let returndata_size := mload(response)
                    revert(add(32, response), returndata_size)
                }
            } else {
                revert PRBProxy__ExecutionReverted();
            }
        }
    }

    /// @inheritdoc IPRBProxy
    function setPermission(
        address envoy,
        address target,
        bytes4 selector,
        bool permission
    ) external override {
        if (ownerOf(0) != msg.sender) {
            revert PRBProxy__NotOwner(owner, msg.sender);
        }
        permissions[envoy][target][selector] = permission;
    }

    /// @inheritdoc IPRBProxy
    function transferOwnership(address newOwner) external override {
        // address oldOwner = owner;
        // if (oldOwner != msg.sender) {
        //     revert PRBProxy__NotOwner(oldOwner, msg.sender);
        // }
        // owner = newOwner;
        // emit TransferOwnership(oldOwner, newOwner);
    }
}