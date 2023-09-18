//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Reviews.sol";
import "./Appraiser.sol";

/// @author Yan Man
/// @title Verifier fungible token contract. Each org deploys one of these contracts
contract Verifier is ERC1155, Ownable, AccessControl {
    using Counters for Counters.Counter;
    using Reviews for Reviews.Review;

    // state vars
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant VERIFIER = 0;
    uint256 public FLOOR_PRICE = 100000000000000; // 0.0001 eth

    uint256 public s_orgId;
    string public s_name;
    mapping(uint256 => Reviews.Review) public s_verifiers; // orgId -> # of tokens
    address public s_appraiserContract;

    // events

    // errors
    error Verifier__OnlyAdminCanMintNFT();
    error Verifier__OnlyAdminCanTransferVerifierNFT();
    error Verifier__InvalidBurnerAddress();
    error Verifier__InvalidMsgValue();
    error ERC1155__NotOwnerNorApproved();

    // modifiers

    constructor(
        uint256 orgId_,
        string memory name_,
        address addr_,
        string memory URI_,
        address owner_
    ) ERC1155(URI_) {
        transferOwnership(owner_);

        s_orgId = orgId_;
        s_name = name_;

        _mint(addr_, VERIFIER, 10**3, "");
        _setupRole(ADMIN_ROLE, addr_);
        s_appraiserContract = _msgSender();
    }

    /**
    @dev only allow admin/owner to mint Verifier tokens
    @param to_ where Verifier tokens are minted to
    */
    function mintBatch(address to_) external payable {
        if (!_isAdminOrOwner()) {
            revert Verifier__OnlyAdminCanMintNFT();
        }
        uint256 _msgVal = msg.value;
        if (_msgVal < FLOOR_PRICE) {
            revert Verifier__InvalidMsgValue();
        }
        uint256 amount_ = _msgVal / FLOOR_PRICE;
        payable(owner()).transfer(_msgVal);
        uint256[] memory amounts_ = new uint[](1);
        uint256[] memory ids_ = new uint[](1);

        ids_[0] = VERIFIER;
        amounts_[0] = amount_;

        _mintBatch(to_, ids_, amounts_, "");
    }

    /**
    @dev set appraiser contract address post-deployment
    @param appraiserContractAddress_ contract addr to set
     */
    function setAppraiserContractAddress(address appraiserContractAddress_)
        external
        onlyOwner
    {
        s_appraiserContract = appraiserContractAddress_;
    }

    /**
    burn token when a "Verified Review" is minted
    @dev only AppraiserOrganization contract can burn tokens, via mintReviewNFT function
    @param burnTokenAddress_ burn address of token holder
     */
    function burnVerifierForAddress(address burnTokenAddress_) external {
        Appraiser _appraiser = Appraiser(s_appraiserContract);
        (address _ao, ) = _appraiser.s_deployedContracts(s_orgId);
        if (msg.sender != _ao) {
            // check original end user
            revert Verifier__InvalidBurnerAddress();
        }
        _burn(burnTokenAddress_, VERIFIER, 1);
    }

    /**
    @dev check whether given address is an admin role
    @param addr account address to check
    @return is given address an admin?
     */
    function isAdmin(address addr) external view returns (bool) {
        return hasRole(ADMIN_ROLE, addr);
    }

    /**
    @dev mint batches of Verifier tokens (from Owner)
    @param ids_ array of token Ids
    @param amounts_ array, correspond to each token id
    @param to_ address to mint to 
     */
    function adminMintBatch(
        uint256[] memory ids_,
        uint256[] memory amounts_,
        address to_
    ) external onlyOwner {
        _mintBatch(to_, ids_, amounts_, "");
    }

    /** 
    @dev override existing 1155 safeTransferFrom, do not allow non-admin to tarnsfer these tokens
    @param from transfer from
    @param to transfer to
    @param id token Id
    @param amount number of tokens to transfer
    @param data optional extra data
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        if (
            (from == _msgSender() || isApprovedForAll(from, _msgSender())) ==
            false
        ) {
            revert ERC1155__NotOwnerNorApproved();
        }
        if (!_isAdminOrOwner()) {
            revert Verifier__OnlyAdminCanTransferVerifierNFT();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
    @dev check if sender is an admin or owner
    @return bool is sender an admin or owner?
     */
    function _isAdminOrOwner() private view returns (bool) {
        if (
            hasRole(ADMIN_ROLE, _msgSender()) == false &&
            _msgSender() != owner()
        ) {
            return false;
        }
        return true;
    }

    /**
    @dev MUST be implemented to override from function clash between ERC1155 / AccessControl
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
