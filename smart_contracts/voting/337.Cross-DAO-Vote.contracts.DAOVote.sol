// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155PermitUpgradeable.sol";
import "./Account.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract DAOVote is Initializable {

    /**
    * @dev Revert when contract does not support permit function
           Checks through function selector
    */
    error ContractDoesNotSupportPermit(address assetContract);

    /**
    * @dev Type of the vote allowed on a proposal. 
            0 = UP, 1 = DOWN
    */
    enum Vote {
        UP,
        DOWN
    }

    /**
    * @dev Proposal info
           - Proposal can be created by anyone holding particular DAO ERC1155 token
           - Instead of saving upvotes/downvotes into struct, 
             alternatively can use event for fetching result in order to save gas
    * Attributes:
      'proposer' is the address of the caller
      'assetContract' is the multiple user-added ERC1155 contract address
      'endPeriod' is deadline for voting period
      'upVotes' is upvote count of each proposal
      'downVotes' is downvote count of each proposal
      'allowedContract' is the bytes32 merkle root of list of DAO ERC1155 contract
                        addresses that has been preset off-chain
                        Only token holder of these contracts are allowed to vote
                        regardless of which token ID they use to vote
    */
    struct Proposal {
        address proposer;
        address assetContract;
        uint256 endPeriod;
        uint128 upVotes;
        uint128 downVotes;
        bytes32 allowedContract;
    }

    /**
    * @dev Voter asset info
           - Voter must hold any token from allowed contract(preset during proposal) 
             in order to vote on a particular proposal
    * Attributes:
      'assetContract' is the allowed ERC1155 contract address
      'tokenId' is the token ID of the 'assetContract'.
                This token ID will be transferred to an 'Account' contract after
                casting a vote.
                Voter only able to claim the token after the voting period deadline is over.
    */
    struct VoterAsset {
        address assetContract;
        uint256 tokenId;
    }

    /**
    * @dev Checks whether caller is a token holder
    */
    modifier onlyTokenHolder(address _assetContract, uint256 _tokenId) {
        require(IERC1155(_assetContract).balanceOf(_msgSender(), _tokenId) > 0, "DAOVote: restricted to token holders only");
        _;
    }

    /**
    * @dev Checks whether caller is a proposer
    */
    modifier onlyProposer(uint256 _proposalId) {
        require(_proposal[_proposalId].proposer == _msgSender(), "DAOVote: restricted to proposers only");
        _;
    }

    /**
    * @dev Proposal ID -> Proposal info
    *       Mapping for proposal ID for each proposal info
    */
    mapping(uint256 => Proposal) private _proposal;

    /**
    * @dev Proposal ID -> voter address -> voter asset info
    *       Mapping for proposal ID with voter and their asset info
    *       Store new vote on each proposal ID for particular voter
    */
    mapping(uint256 => mapping(address => VoterAsset)) private _voter;

    /**
    * @dev Owner address -> account address
    *       Mapping for owner address with their created account contract
    */
    mapping(address => Account) private _accounts;

    /**
    * @dev Proposal ID -> voter address => claimed token (true/false)
    *       Mapping for voter address whether token has been claimed or not
            for particular proposal ID
    */
    mapping(uint256 => mapping(address => bool)) private _claimed;

    /**
    * @dev Owner of this 'DAOVote' contract
    */
    address public _owner;

    /**
    * @dev Proposal ID count
    */
    uint256 private _proposalIdCount;

    /**
    * @dev Function selector to determine whether external contract support EIP-2612 permit function
    */
    bytes4 private constant _PERMIT_FUNC_SELECTOR = bytes4(keccak256("permit(address,address,uint256,uint8,bytes32,bytes32"));

    /**
    * @dev Emitted after a vote casted
    * @param proposalId  Proposal ID
    * @param voterInfo   Voter asset info
    * @param vote        Vote info (upvote/downvote)
    */
    event Votes(uint256 indexed proposalId, VoterAsset voterInfo, Vote vote);

    /**
    * @dev Emitted after a proposal created
    * @param proposalId       Proposal ID
    * @param proposer         Proposer address
    * @param accountContract  ERC1155 contract
    * @param tokenId          Token ID
    */
    event ProposalCreated(uint256 indexed proposalId, address proposer, address accountContract, uint256 tokenId);

    /**
    * @dev Initialize function are only called once for upgradeable proxy contract
           This contract does not use constructor function to avoid state variables conflicts
    */
    function initialize () initializer public {
        _owner = address(msg.sender);
        _proposalIdCount = 0;
    }

    /**
    * @notice Call this function to cast a vote
    * @dev This function will verify ERC1155 '_assetContract' based on the '_merkleProof' provided 
           from off-chain computation.
    *      Only token holder from allowed '_assetContract' are able to cast a vote regardless of 
           any token ID of the allowed '_assetContract' they are currently holding.
    *      The token used for casting the vote will be transferred to an 'Account' contract and to be
           claimed later after voting period ends.
    *      Only one(1) ERC1155 token will be used for voting.
    *      This function implement EIP-2612 Permit that verify signature for token handling approval
           for this 'DAOVote' contract
    * @param _assetContract ERC1155 external contract 
    * @param _tokenId Token ID for '_assetContract' used to cast a vote
    * @param _proposalId Vote casted on which '_proposalId'
    * @param _vote Vote casted, UP = 0, DOWN = 1
    * @param _deadline End period for signature validity
    * @param v Recovery id for signature recovery
    * @param r ECDSA output for signature recovery
    * @param s ECDSA output for signature recovery
    * @param _merkleProof Hexed merkle proof used for verifying leaf input
    */
    function vote(
                address _assetContract,
                uint256 _tokenId,
                uint256 _proposalId,
                Vote _vote, 
                uint256 _deadline,
                uint8 v,
                bytes32 r,
                bytes32 s,
                bytes32[] calldata _merkleProof
                ) 
    external {
        Proposal memory targetProposal = _proposal[_proposalId];
        // verify asset contract whether it is allowed for voting based on merkle root for each proposal
        bytes32 leaf = keccak256(abi.encodePacked(_assetContract));
        require(MerkleProof.verify(_merkleProof, targetProposal.allowedContract, leaf), "DAOVote: not allowed to vote");

        require(targetProposal.assetContract != address(0), "DAOVote: proposal does not exists");
        require(IERC1155(_assetContract).balanceOf(_msgSender(), _tokenId) > 0, "DAOVote: insufficient voting token balance");
        require(targetProposal.proposer != _msgSender(), "DAOVote: cannot cast vote on own proposal");
        require(targetProposal.endPeriod > block.timestamp, "DAOVote: voting period already ended");
        require(_voter[_proposalId][_msgSender()].assetContract == address(0), "DAOVote: already voted");

        // store new asset info of the caller for this proposal ID
        VoterAsset memory newVoter = VoterAsset ({
            assetContract: _assetContract,
            tokenId: _tokenId
        });
        _voter[_proposalId][_msgSender()] = newVoter;

        // unchecked as vote count is unlikely to overflow
        unchecked {
            if (_vote == Vote.UP) {
                targetProposal.upVotes++;
            } else {
                targetProposal.downVotes++;
            }
        }
        // update proposal info
        _proposal[_proposalId] = targetProposal;

        // checks whether this 'DAOVote' has been approved for handling the token for particular contract
        if (!IERC1155(_assetContract).isApprovedForAll(_msgSender(), address(this))) {
            checkPermit(_assetContract, _tokenId, _deadline, v, r, s);
        }

        // create an 'Account' contract if caller does not have any
        createAccount();
        
        // transfer used token for casting the vote from caller to created 'Account' contract
        IERC1155(_assetContract).safeTransferFrom(_msgSender(), 
                                                address(_accounts[_msgSender()]), 
                                                _tokenId, 
                                                1, // only one token will be transferred
                                                "");

        emit Votes(_proposalId, newVoter, _vote);
    }

    /**
    * @dev This function checks whether the external contract to be interacted with 
           supports EIP-2612 that uses Permit function
           Call external contract permit function to verify signature and approve token handling 
           for this 'DAOVote' contract
    * @param _assetContract ERC1155 external contract 
    * @param _tokenId Token ID for '_assetContract' used to cast a vote
    * @param _deadline End period for signature validity
    * @param v Recovery id for signature recovery
    * @param r ECDSA output for signature recovery
    * @param s ECDSA output for signature recovery
    */
    function checkPermit(address _assetContract, 
                        uint256 _tokenId,
                        uint256 _deadline, 
                        uint8 v, 
                        bytes32 r, 
                        bytes32 s)    
    internal {
        // checks if '_assetContract' support Permit function
        if (IERC1155(_assetContract).supportsInterface(_PERMIT_FUNC_SELECTOR)) {
            uint256 tokenBalance = IERC1155(_assetContract).balanceOf(_msgSender(), _tokenId);

            // verify signature for token approval
            IERC1155PermitUpgradeable(_assetContract).permit(_msgSender(), 
                                                            address(this), 
                                                            tokenBalance,
                                                            _deadline, 
                                                            v, r, s);
        } else {
            revert ContractDoesNotSupportPermit(_assetContract);
        }
    }

    /**
    * @notice Call this function to claim token
    * @dev This function allow claiming of token that has been used to create a proposal or 
           cast a vote for particular '_proposalId'.
    *      This function will call created 'Account' contract 'withdraw' function as
           those used token are being held in the 'Account' contract.
    *      Only one(1) token will be transferred to the caller for each 'claim' function call
    *      Tokens only allowed to be claimed after voting period ends for each '_proposalId'.
    * @param _proposalId Proposal ID
    */
    function claim(uint256 _proposalId) external {
        Proposal memory targetProposal = _proposal[_proposalId];
        VoterAsset memory targetVoter = _voter[_proposalId][_msgSender()];
        Account accountContract = _accounts[_msgSender()];

        require(targetProposal.assetContract != address(0), "DAOVote: proposal does not exists");
        require(address(accountContract) != address(0), "DAOVote: account does not exists");
        require(targetProposal.endPeriod <= block.timestamp, "DAOVote: voting period does not ended yet");
        require(targetVoter.assetContract != address(0), "DAOVote: caller did not vote");
        require(!_claimed[_proposalId][_msgSender()], "DAOVote: token claimed for this proposal");

        // check effect interactions before token withdrawal
        _claimed[_proposalId][_msgSender()] = true;
        accountContract.withdraw(targetVoter.assetContract, targetVoter.tokenId);
    }

    /**
    * @notice Call this function to create an 'Account' contract
    * @dev This function will create an 'Account' contract for each first time proposer/voter.
    *      Token that has been used for proposal creation or casting a vote will be transferred
           to this 'Account' and to be claimed later after the voting period ends.
    *      Purpose of creating individual external 'Account' contract for each respective users 
           is to implement pull-over-push pattern that can reduce risk of this 'DAOVote' contract 
           exploited by malicious known attacks.
    */
    function createAccount() public {
        // checks whether the caller has an 'Account' contract created
        if (address(_accounts[_msgSender()]) == address(0)) {
            // create an 'Account' by passing caller address and this 'DAOVote' contract address
            Account account = new Account(_msgSender(), address(this));
            // map 'Account' with the owner
            _accounts[_msgSender()] = account;
        }
    }

    /**
    * @notice Call this function to create proposal
    * @dev Caller(proposer) must be one of the '_tokenId' holder for particular '_assetContract'.
    *      Caller cannot cast vote on their own proposal.
    *      After proposal created, one(1) token (specified '_tokenId') will be transferred to 
           the caller's 'Account' contract.
    *      'Account' contract will be created for first time proposer.
    *      This function implement EIP-2612 Permit that verify signature for token handling approval
           for this 'DAOVote' contract
    *      After voting period ends, caller need to claim their tokens by calling 'claim' function.
    *      List of ERC1155 contract addresses that are allowed to cast votes on a particular proposal 
           can be retrieved from '_merkleRoot'.
    *      Instead of storing long list of ERC1155 contract addresses in state variables array,
           merkle tree pattern is effectively saving a lot of gas.
    *      The '_merkleRoot' has been computed off-chain and will be used for verifying allowed ERC1155 
           contract when voter casts a vote.
    * @param _assetContract ERC1155 external contract 
    * @param _tokenId Token ID for '_assetContract' used to cast a vote
    * @param _duration Voting period duration
    * @param _deadline End period for signature validity
    * @param v Recovery id for signature recovery
    * @param r ECDSA output for signature recovery
    * @param s ECDSA output for signature recovery
    * @param _merkleRoot hashed merkle root of external ERC1155 contract addresses
    */
    function createProposal(
                            address _assetContract,
                            uint256 _tokenId, 
                            uint256 _duration,
                            uint256 _deadline,
                            uint8 v,
                            bytes32 r,
                            bytes32 s,
                            bytes32 _merkleRoot
                            ) 
    external onlyTokenHolder(_assetContract, _tokenId) returns (uint256) {
        require(_msgSender() != address(0), "DAOVote: proposer cannot be zero address");

        // unchecked as unlikely to overflow
        unchecked {
            ++_proposalIdCount;
        }

        // creates new Proposal info
        // 'allowedContract' attribute will store the merkle root for list of ERC1155 contract that
        // their holders are allowed to cast votes
        Proposal memory newProposal = Proposal ({
            proposer: _msgSender(),
            assetContract: _assetContract,
            endPeriod: block.timestamp + _duration,
            upVotes: 0,
            downVotes: 0,
            allowedContract: _merkleRoot
        });
        // store proposal info
        _proposal[_proposalIdCount] = newProposal;

        // checks whether this 'DAOVote' has been approved for handling the token for particular contract
        if (!IERC1155(_assetContract).isApprovedForAll(_msgSender(), address(this))) {
            checkPermit(_assetContract, _tokenId, _deadline, v, r, s);
        }

        // creates an 'Account' contract if caller does not have any
        createAccount();

        // transfer used token for creating the proposal from caller to created 'Account' contract
        IERC1155(_assetContract).safeTransferFrom(_msgSender(), 
                                                address(_accounts[_msgSender()]), 
                                                _tokenId, 
                                                1, // only one token will be transferred
                                                "");
        
        emit ProposalCreated(_proposalIdCount, _msgSender(), address(_accounts[_msgSender()]), _tokenId);
        return _proposalIdCount;
    }

    /**
    * @dev This function allow proposer to cancel proposal by putting an end to the voting period
    *      Only particular '_proposalId' creator allowed to cancel the proposal. 
    *      After proposal cancelled, proposer and voter can claim their used token
           by calling 'claim' function.
    * @param _proposalId Proposal ID
    */
    function cancelProposal(uint256 _proposalId) external onlyProposer(_proposalId) {
        _proposal[_proposalId].endPeriod = block.timestamp;
    }

    /**
    * @dev This function returns address of an 'Account' based on the '_accountOwner' address
    * @param _accountOwner Account owner address
    */
    function getAccount(address _accountOwner) public view 
    returns (address) {
        return address(_accounts[_accountOwner]);
    }

    /**
    * @dev This function returns caller address
    */
    function _msgSender() internal view returns (address) {
        return address(msg.sender);
    }

    /**
    * @notice Function to receive Ether
    */
    receive() external payable {}

    /**
    * @notice Fallback function is called when msg.data is not empty
    */
    fallback() external payable {}

    /**
    * @dev ERC 1155 Receiver functions.
    **/
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
    * @dev ERC 1155 Batch Receiver functions.
    **/
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}