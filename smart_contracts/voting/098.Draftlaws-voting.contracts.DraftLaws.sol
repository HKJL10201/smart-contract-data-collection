pragma solidity ^0.6.12;

import "..//node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract DraftLaws is Ownable {

    struct DraftLaw {
        string name;
        address subject;
        uint registryNumber;
        uint registryTime;
        uint expirationTime;
        bool approved;
    }

    /* Events */
    event SignerReplaced(address indexed previousSigner, address indexed newSigner);

    event DraftlawRegister(address indexed subject, uint indexed draftlawId);

    event DraftlawConfirmed(address indexed signer, uint indexed draftlawId);
    event DraftlawRevoked(address indexed signer, uint indexed draftlawId);

    event DraftlawApproved(uint indexed draftlawId);
    event DraftlawRejected(uint indexed draftlawId);

    /* constants */

    uint constant MAX_SIGNERS = 10;
    uint constant THRESHOLD = 3;

    /* Storage */

    mapping(uint => DraftLaw) public draftLaws;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isSigner;
    address[] public signers;
    uint public draftlawsCount;

    /* Modifiers */

    modifier isNotSigner(address _address) {
        require(!isSigner[_address], "Already a signer");
        _;
    }

    modifier isAllowedSigner(address _address) {
        require(isSigner[_address], "Not a signer");
        _;
    }

    modifier draftlawExists(uint _draftlawId) {
        require (_draftlawId < draftlawsCount, "DraftLaw with such id doesn't exist");
        _;
    }
    
    modifier draftlawNotExpired(uint _draftlawId) {
        require (now < draftLaws[_draftlawId].expirationTime, "draftlaw expired");
        _;
    }

    modifier notConfirmed(uint _draftlawId, address _signer) {
        require(!confirmations[_draftlawId][_signer], "Already confirmed");
        _;
    }

    modifier confirmed(uint _draftlawId, address _signer) {
        require(confirmations[_draftlawId][_signer], "Not yet confirmed");
        _;
    }

    modifier notApproved(uint _draftlawId) {
        require(!draftLaws[_draftlawId].approved, "Already approved");
        _;
    }

    /* methods */

    /// @dev Sets signers and owner in Ownable constructor
    /// @param _signers Array of initial signers
    constructor(address[] memory _signers)  public {
        require(_signers.length == MAX_SIGNERS, "Wrong amount of signers");

        signers = new address[](MAX_SIGNERS);

        for (uint i = 0; i < MAX_SIGNERS; i++) {
            require(_signers[i] != address(0), "Zero address");
            require(!isSigner[_signers[i]], "Signer's address repeats");
            isSigner[_signers[i]] = true;
            signers[i] = _signers[i];
        }
        draftlawsCount = 0;
    }

    /// @dev Replaces existing signer with new, only for owner
    /// @param _previousSig Address of existing signer
    /// @param _newSig Address of a new signer
    function replaceSigner(address _previousSig, address _newSig) external
         onlyOwner
         isAllowedSigner(_previousSig)
         isNotSigner(_newSig) 
    {
        for (uint i = 0; i < MAX_SIGNERS; i++) {
            if (signers[i] == _previousSig) {
                signers[i] = _newSig;
                break;
            }
        }
        isSigner[_previousSig] = false;
        isSigner[_newSig] = true;
    }

    /// @dev Register a new DraftLaw for voting
    /// @param _name Name of a draftlaw
    /// @param _regNumber registration number of a draftlaw
    function registerDraftLaw(string memory _name, uint _regNumber) external 
            isAllowedSigner(_msgSender())
            returns (uint draftlawId)
    {
        draftlawId = draftlawsCount;
        draftLaws[draftlawId] = DraftLaw(
            _name,
            _msgSender(),
            _regNumber,
            now,
            now + 14 days,
            false
        );

        draftlawsCount++;
        emit DraftlawRegister(_msgSender(), draftlawId);

        confirmDraftLaw(draftlawId);
    }

    /// @dev Allows signer to vote for draftlaw untill its expiration
    /// @param _draftlawId ID of a draftlaw
    function confirmDraftLaw(uint _draftlawId) public
            isAllowedSigner(_msgSender())
            draftlawExists(_draftlawId)
            draftlawNotExpired(_draftlawId)
            notConfirmed(_draftlawId, _msgSender())
    {
        confirmations[_draftlawId][_msgSender()] = true;

        emit DraftlawConfirmed(_msgSender(), _draftlawId);
    }

    /// @dev Allows signer to revoke his vote untill expiration of a draftlaw
    /// @param _draftlawId ID of a draftlaw
    function revokeDraftLaw(uint _draftlawId) external
            isAllowedSigner(_msgSender())
            draftlawExists(_draftlawId)
            draftlawNotExpired(_draftlawId)
            confirmed(_draftlawId, _msgSender())
    {
        confirmations[_draftlawId][_msgSender()] = false;
        emit DraftlawRevoked(_msgSender(), _draftlawId);
    }

    /// @dev After voting for draftlaw is finished, owner calls this function
    /// to check whether draftlaw is approved
    /// @param _draftlawId ID of a draftlaw
    function approveDraftLaw(uint _draftlawId) external
            onlyOwner
            draftlawExists(_draftlawId)
            notApproved(_draftlawId)
            returns (uint votesCount)
    {
        require(draftLaws[_draftlawId].expirationTime <= now, "Voting still in progress");

        votesCount = getConfirmationCount(_draftlawId);

        if (isConfirmed(_draftlawId)) {
            draftLaws[_draftlawId].approved = true;
            emit DraftlawApproved(_draftlawId);
        }
        else
            emit DraftlawRejected(_draftlawId);
    }

    /// @dev Returns true if draftlaw is approved and false otherwise
    /// @param _draftlawId ID of a draftlaw
    function isConfirmed(uint _draftlawId) public view draftlawExists(_draftlawId) returns(bool)
    {
        if (draftLaws[_draftlawId].approved)
            return true;
        uint count = 0;
        for (uint i = 0; i < MAX_SIGNERS; i++) {
            if (confirmations[_draftlawId][signers[i]])
                count++;
            if (count == THRESHOLD)
                return true;
        }
        return false;
    }

    /// @dev Returns current amount of votes while voting in progress or draftlaw is rejected
    /// and THRESHOLD if draftlaw is approved 
    /// @param _draftlawId ID of a draftlaw
    function getConfirmationCount(uint _draftlawId) public view draftlawExists(_draftlawId)
            returns (uint count)
    {
        count = 0;
        if(draftLaws[_draftlawId].approved)
            return THRESHOLD;
        for (uint i = 0; i < MAX_SIGNERS; i++) {
            if(confirmations[_draftlawId][signers[i]])
                count++;
        }
    }

    /// @dev Returns amount of draftlaws which are still in progress
    function getCurrentDraftlawsCount() external view returns(uint count)
    {
        for (uint i = 0; i < draftlawsCount; i ++) {
            if (now < draftLaws[i].expirationTime && !draftLaws[i].approved)
                count++;
        }
    }

    /// @dev Returns array of signers addresses
    function getSigners() external view returns(address[] memory _signers)
    {
        _signers = signers;
    }
}