//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Reviews.sol";
import "./AppraiserOrganization.sol";
import "./Users.sol";
import "./VRFv2Consumer.sol";

/// @author Yan Man
/// @title Reviewer contract for minting reviews. Manage reviews across all orgs
contract Reviewer is Ownable {
    using Counters for Counters.Counter;
    using Users for Users.User;

    // state vars
    mapping(uint256 => address) public s_aoContracts; // orgId -> deployed AO contract
    mapping(uint256 => mapping(uint256 => address)) public s_reviews; // orgId -> reviewId -> reviewer address
    mapping(address => Users.User) public s_users; // user/reviewer address -> User struct
    address private s_VRFv2ConsumerContractAddr;

    // events
    event LogMintReview(uint256 reviewId);
    event LogNewUser(address addr);
    event LogVoteOnReview(address voter, uint256 orgId, uint256 reviewId);

    // errors
    error Reviewer__InvalidOrgId();
    error Reviewer__VoterMatchesAuthor();
    error Reviewer__InvalidReview();
    error Reviewer__OnlyVRFv2ConsumerContractAddr();

    // modifiers
    modifier isValidOrgId(uint256 orgId_) {
        if (address(s_aoContracts[orgId_]) == address(0)) {
            revert Reviewer__InvalidOrgId();
        }
        _;
    }

    /** 
    @dev mint reviews. Also creates a user profile if it does not yet exist
    call VRF to get random group for user
    @param orgId_ org Id
    @param rating_ 1-100
    @param review_ text description of review
     */
    function mintReview(
        uint256 orgId_,
        uint256 rating_,
        string calldata review_
    ) external isValidOrgId(orgId_) {
        uint256 _reviewId = AppraiserOrganization(s_aoContracts[orgId_])
            .mintReviewNFT(_msgSender(), rating_, review_);
        s_reviews[orgId_][_reviewId] = _msgSender();
        VRFv2Consumer(s_VRFv2ConsumerContractAddr).requestRandomWords(
            orgId_,
            _reviewId
        );
        _addUser(_msgSender());
        emit LogMintReview(_reviewId);
    }

    /** 
    @dev upvote/downvote existing reviews. Check that orgId is valid first
    @param orgId_ org Id
    @param reviewId_ review Id
    @param isUpvote_ upvote or downvote
     */
    function voteOnReview(
        uint256 orgId_,
        uint256 reviewId_,
        bool isUpvote_
    ) external isValidOrgId(orgId_) {
        address _reviewAuthorAddr = s_reviews[orgId_][reviewId_];
        if (_reviewAuthorAddr == address(0)) {
            revert Reviewer__InvalidReview();
        }
        if (_msgSender() == _reviewAuthorAddr) {
            revert Reviewer__VoterMatchesAuthor();
        }

        Users.User storage _reviewUser = s_users[s_reviews[orgId_][reviewId_]];
        if (isUpvote_ == true) {
            _reviewUser.upvotes += 1;
        } else {
            _reviewUser.downvotes += 1;
        }
        AppraiserOrganization(s_aoContracts[orgId_]).voteOnReview(
            _msgSender(),
            reviewId_,
            isUpvote_
        );

        emit LogVoteOnReview(_msgSender(), orgId_, reviewId_);
    }

    /** 
    @dev called after VRF filled, and random group number is retrieved 
    @param orgId_ org Id
    @param reviewId_ review Id
    @param groupId_ group Id to set for user
     */
    function updateReviewGroupId(
        uint256 orgId_,
        uint256 reviewId_,
        uint256 groupId_
    ) external {
        if (s_VRFv2ConsumerContractAddr != _msgSender()) {
            revert Reviewer__OnlyVRFv2ConsumerContractAddr();
        }
        AppraiserOrganization(s_aoContracts[orgId_]).updateReviewGroupId(
            reviewId_,
            groupId_
        );
    }

    /** 
    @dev set VRF consumer contract address
    @param VRFv2ConsumerContractAddr_ set contract address
     */
    function setVRFv2ConsumerContractAddress(address VRFv2ConsumerContractAddr_)
        external
        onlyOwner
    {
        s_VRFv2ConsumerContractAddr = VRFv2ConsumerContractAddr_;
    }

    /** 
    @dev set AppraiserOrganization contract address
    @param orgId_ org Id
    @param contractAddr_ set contract addr for specific org
     */
    function setAppraiserOrganizationContractAddress(
        uint256 orgId_,
        address contractAddr_
    ) external onlyOwner {
        s_aoContracts[orgId_] = contractAddr_;
    }

    /** 
    @dev add new user if needed
    @param addr_ user address
     */
    function _addUser(address addr_) private {
        if (s_users[addr_].isRegistered == false) {
            s_users[addr_] = Users.User({
                upvotes: 0,
                downvotes: 0,
                isRegistered: true
            });

            emit LogNewUser(addr_);
        }
    }
}
