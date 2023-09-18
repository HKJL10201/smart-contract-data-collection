// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract GratitudeToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable
{
    IEntryPoint private immutable _entryPoint;

    address public owner;

    event GratitudeTokenInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyOwnerOrEntryPoint() {
        _requireFromEntryPointOrOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == owner || msg.sender == address(this),
            "only owner"
        );
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(_entryPoint) || msg.sender == owner,
            "account: not Owner or EntryPoint"
        );
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        emit GratitudeTokenInitialized(_entryPoint, owner);
        __ERC20_init("GratitudeToken", "GTT");
        __ERC20Burnable_init();
        __UUPSUpgradeable_init();
    }

    function entryPoint() public view virtual returns (IEntryPoint) {
        return _entryPoint;
    }

    function mint(address to, uint256 amount) public onlyOwnerOrEntryPoint {
        _mint(to, amount);
    }

    function mintToMany(
        address[] memory recipients,
        uint256 amount
    ) public onlyOwnerOrEntryPoint {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            _mint(recipient, amount);
        }
    }

    function mintToMany(
        address[] memory recipients,
        uint256[] memory amounts
    ) public onlyOwnerOrEntryPoint {
        require(
            recipients.length == amounts.length,
            "recipients and amounts arrays must have the same length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            _mint(recipient, amount);
        }
    }

    function mintToMany(
        address[] memory recipients
    ) public onlyOwnerOrEntryPoint {
        mintToMany(recipients, 10 ** 18);
    }

    // only the owner of the contract can transfer gratitude tokens
    function transfer(
        address recipient,
        uint256 amount
    ) public override onlyOwnerOrEntryPoint returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyOwnerOrEntryPoint returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwnerOrEntryPoint {}
}
