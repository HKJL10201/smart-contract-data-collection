//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Verifier.sol";
import "./Organizations.sol";
import "./Reviews.sol";

/// @author Yan Man
/// @title AppraiserOrganization contract for minting review NFTs. Deploy 1 contract per organization.
contract AppraiserOrganization is ERC1155, Ownable {
    using Counters for Counters.Counter;
    using Organizations for Organizations.Organization;
    using Reviews for Reviews.Review;

    // structs

    // state vars
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(uint256 => Reviews.Review) public s_reviews; // reviewId -> Review
    mapping(uint256 => mapping(address => bool)) public s_upvotes; // reviewId -> (voting address -> isVoted)
    mapping(uint256 => uint256) public s_upvoteCount; // reviewId -> # upvotes
    mapping(uint256 => mapping(address => bool)) public s_downvotes; // reviewId -> (voting address -> isVoted)
    mapping(uint256 => uint256) public s_downvoteCount; // reviewId -> # downvotes
    mapping(address => uint256[]) public s_userReviews; // author address -> [reviewIds]

    Counters.Counter private _s_reviewIds; // 1-indexed
    Organizations.Organization private _s_organization;
    address private _s_verifierContractAddress;
    address private _s_reviewerContractAddress;
    uint256 private immutable VERIFIER_ID;

    // events
    event LogNFTReviewMinted(uint256 reviewId);
    event LogNFTReviewVote(uint256 reviewId);

    // errors
    error AppraiserOrganization__InvalidRating();
    error AppraiserOrganization__OneVoteAllowedPerReview();
    error AppraiserOrganization__CannotVoteOnOwnReview();
    error AppraiserOrganization__OnlyReviewerContractCanCall();
    error AppraiserOrganization__GroupIdAlreadySet();

    // modifiers
    modifier isValidRating(uint256 rating_) {
        if (rating_ == 0 || rating_ > 100) {
            revert AppraiserOrganization__InvalidRating();
        }
        _;
    }
    modifier validateVoter(
        address reviewer_,
        uint256 reviewId_,
        bool isUpvote_
    ) {
        if (s_reviews[reviewId_].author == reviewer_) {
            revert AppraiserOrganization__CannotVoteOnOwnReview();
        }
        if (
            s_downvotes[reviewId_][reviewer_] == true ||
            s_upvotes[reviewId_][reviewer_] == true
        ) {
            revert AppraiserOrganization__OneVoteAllowedPerReview();
        }
        _;
    }

    modifier onlyReviewerContract() {
        if (msg.sender != _s_reviewerContractAddress) {
            revert AppraiserOrganization__OnlyReviewerContractCanCall();
        }
        _;
    }

    constructor(
        uint256 orgId_,
        string memory name_,
        address addr_,
        string memory URI_,
        address verifierAddr_,
        address reviewerAddr_
    ) ERC1155(URI_) {
        _s_organization = Organizations.Organization({
            orgId: orgId_,
            name: name_,
            addr: addr_,
            isActive: true,
            isCreated: true
        });
        _s_verifierContractAddress = verifierAddr_;
        _s_reviewerContractAddress = reviewerAddr_;
        VERIFIER_ID = Verifier(_s_verifierContractAddress).VERIFIER();
        _s_reviewIds.increment();
    }

    /** 
    @dev voteOnReview. Upvote or downvote. Invoked by Reviewer contract
    @param reviewer_ address of reviewer
    @param reviewId_ review Id
    @param isUpvote_ upvote or downvote
     */
    function voteOnReview(
        address reviewer_,
        uint256 reviewId_,
        bool isUpvote_
    ) external validateVoter(reviewer_, reviewId_, isUpvote_) {
        if (isUpvote_ == true) {
            s_upvotes[reviewId_][reviewer_] = true;
            uint256 count = s_upvoteCount[reviewId_];
            s_upvoteCount[reviewId_] = count + 1;
        } else {
            s_downvotes[reviewId_][reviewer_] = true;
            uint256 count = s_downvoteCount[reviewId_];
            s_downvoteCount[reviewId_] = count + 1;
        }
        emit LogNFTReviewVote(reviewId_);
    }

    /** 
    @dev check on whether user has voted on current review already. Cannot vote multiple times on same review
    @param reviewer_ address of reviewer
    @param reviewId_ review Id
     */
    function hasVoted(address reviewer_, uint256 reviewId_)
        external
        view
        returns (bool)
    {
        return
            s_upvotes[reviewId_][reviewer_] ||
            s_downvotes[reviewId_][reviewer_];
    }

    /** 
    @dev get current reviewId
    @return id
     */
    function currentReviewId() external view returns (uint256) {
        return _s_reviewIds.current();
    }

    /** 
    @dev get _s_organization private var Org struct
    @return Organization struct
     */
    function organization()
        external
        view
        returns (Organizations.Organization memory)
    {
        return _s_organization;
    }

    /** 
    @dev get number of reviews given by author
    @param author_ author address
    @return # of reviews 
     */
    function numUserReviews(address author_) external view returns (uint256) {
        return s_userReviews[author_].length;
    }

    /** 
    @dev mint review. Burn Verifier token if valid. Invoked by Reviewer contract
    @param reviewerAddr_ address of reviewer
    @param rating_ 1-100
    @param review_ text description of review
    @return reviewId
     */
    function mintReviewNFT(
        address reviewerAddr_,
        uint256 rating_,
        string memory review_
    ) public isValidRating(rating_) onlyReviewerContract returns (uint256) {
        uint256 _reviewId = _s_reviewIds.current();
        _mint(reviewerAddr_, _reviewId, 1, "");

        bool _isVerified = false;
        Verifier _verifier = Verifier(_s_verifierContractAddress);
        if (_verifier.balanceOf(reviewerAddr_, VERIFIER_ID) > 0) {
            _verifier.burnVerifierForAddress(reviewerAddr_);
            _isVerified = true;
        }

        Reviews.Review memory review = Reviews.Review({
            id: _reviewId,
            author: reviewerAddr_,
            rating: rating_,
            review: review_,
            unixtime: block.timestamp,
            isVerified: _isVerified,
            groupId: 0
        });
        s_reviews[_reviewId] = review;
        s_userReviews[reviewerAddr_].push(_reviewId);
        _s_reviewIds.increment();

        emit LogNFTReviewMinted(_reviewId);
        return _reviewId;
    }

    /** 
    @dev after VRF fulfillment, update groupId for given review. Invoked by Reviewer contract
    @param reviewId_ review Id
    @param groupId_ group Id to set for review Id
     */
    function updateReviewGroupId(uint256 reviewId_, uint256 groupId_)
        public
        onlyReviewerContract
    {
        if (s_reviews[reviewId_].groupId != 0) {
            revert AppraiserOrganization__GroupIdAlreadySet();
        }
        s_reviews[reviewId_].groupId = groupId_;
    }
}
