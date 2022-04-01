pragma solidity ^0.4.18;

/// Based on the ERC721Token from OpenZeppelin.


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/payment/PullPayment.sol";


/**
 * based off of work of author Nastassia Sachs 
 */
contract DigitalREC is ERC721, PullPayment {
  
  // Current tokenId
    uint256 public tokenIds;

  // Total amount of REC tokens
    uint256 private totalRecs;
  
  // Mapping from REC token id to RECItem
    mapping(uint256 => RECItem) private _RECItems;

  // Mapping from REC token id to owner
    mapping (uint256 => address) private recOwner;

  // Mapping from owner to list of owned REC token IDs
    mapping (address => uint256[]) private ownedRecs;

  // Mapping from REC token ID to index of the owner RECs list
    mapping(uint256 => uint256) private ownedRecsIndex;
    
    struct RECItem {
        address owner;
        uint256 price;
        string tokenURI;
        uint256 stateIDNum;
    }
  
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    constructor() public ERC721("DigitalREC", "REC") {}


  /**
  * @dev Guarantees msg.sender is owner of the given REC
  * @param _recId uint256 ID of the REC to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _recId) {
    require(recOwner[_recId] == msg.sender);
    _;
  }

  /**
  * @dev Gets the owner of the specified REC token ID
  * @param _recId uint256 ID of the rec token to query the owner of
  * @return owner address currently marked as the owner of the given REC ID
  */
  function ownerOf(uint256 _recId)
  external view returns (address _owner) {
    require(recOwner[_recdId] != address(0));
    _owner = recOwner[_recdId];
  }

  /**
  * @dev Gets the total amount of RECs stored by the contract
  * @return uint256 representing the total amount of RECs
  */
  function countOfRecs()
  external view returns (uint256) {
    return totalRecs;
  }

  /**
  * @dev Gets the number of RECs of the specified address
  * @param _owner address to query the number of RECs
  * @return uint256 representing the number of RECs owned by the passed address
  */
  function countOfRecsByOwner(address _owner)
  external view returns (uint256 _count) {
    require(_owner != address(0));
    _count = ownedRecs[_owner].length;
  }

  /**
  * @dev Gets the REC ID of the specified address at the specified index
  * @param _owner address for the REC's owner
  * @param _index uint256 for the n-th REC in the list of RECs owned by this owner
  * @return uint256 representing the ID of the REC
  */
  function RECOfOwnerByIndex(address _owner, uint256 _index)
  external view returns (uint256 _recId) {
    require(_owner != address(0));
    require(_index < ownedRecs[_owner].length);
    _recId = ownedRecs[_owner][_index];
  }

  /**
  * @dev Gets all REC IDs of the specified address
  * @param _owner address for the REC's owner
  * @return uint256[] representing all REC IDs owned by the passed address
  */
  function RECsOf(address _owner)
  external view returns (uint256[] _ownedRECIds) {
    require(_owner != address(0));
    _ownedRECIds = ownedRecs[_owner];
  }

  /**
  * @dev Approves another address to claim for the ownership of the given  REC
  * @param _to address to be approved for the given REC ID
  * @param _recId uint256 ID of the REC to be approved
  */
  function approve(address _to, uint256 _recId)
  external onlyOwnerOf(_recId) payable {
    require(_to != msg.sender);
    if(_to != address(0) || approvedFor(_recId) != address(0)) {
      Approval(msg.sender, _to, _recId);
    }
    RECApprovedFor[_recId] = _to;
    emit Approval(recOwner[_recId], _to, _recId);
  }

  /**
  * @dev Claims the ownership of a given REC ID
  * @param _recId uint256 ID of the REC being claimed by the msg.sender
  */
  function takeOwnership(uint256 _recId)
  external payable {
    require(approvedFor(_recId) == msg.sender);
    clearApprovalAndTransfer(recOwner[_recId], msg.sender, _recId);
    emit Transfer(recOwner[_recId], msg.sender, _recId);
  }

  /**
   * @dev Gets the approved address to take ownership of a given REC ID
   * @param _recId uint256 ID of the REC to query the approval of
   * @return address currently approved to take ownership of the given REC ID
   */
  function approvedFor(uint256 _recId)
  public view returns (address) {
    return RECApprovedFor[_recId];
  }

  /**
  * @dev Transfers the ownership of a given REC ID to another address
  * @param _to address to receive the ownership of the given REC ID
  * @param _recId uint256 ID of the REC to be transferred
  */
  function transfer(address _to, uint256 _recId)
  public onlyOwnerOf(_recId) {
    clearApprovalAndTransfer(msg.sender, _to, _recId);
  }

  /**
  * @dev Mint REC function
  * @param _to The address that will own the minted REC
  */
  function _mint(address _to, uint256 _recId)
  internal {
    require(_to != address(0));
    require(true == verifyREC(_redID));
    addREC(_to, _recId);
    Transfer(0x0, _to, _recId);
  }

  
  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given REC ID
  * @param _from address which you want to send RECs from
  * @param _to address which you want to transfer the REC to
  * @param _recId uint256 ID of the REC to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _recId)
  internal {
    require(_to != address(0));
    require(_to != _from);
    require(recOwner[_recId] == _from);

    clearApproval(_from, _recId);
    removeREC(_from, _recId);
    addREC(_to, _recId);
    Transfer(_from, _to, _recId);
  }

  /**
  * @dev Internal function to clear current approval of a given REC ID
  * @param _recId uint256 ID of the REC to be transferred
  */
  function clearApproval(address _owner, uint256 _recId)
  private {
    require(recOwner[_recId] == _owner);
    RECApprovedFor[_recId] = 0;
    Approval(_owner, 0, _recId);
  }

  /**
  * @dev Internal function to add a REC ID to the list of a given address
  * @param _to address representing the new owner of the given REC ID
  * @param _recId uint256 ID of the REC to be added to the RECs list of the given address
  */
  function addREC(address _to, uint256 _recId)
  private {
    require(recOwner[_recId] == address(0));
    recOwner[_recId] = _to;
    uint256 length = ownedRecs[_to].length;
    ownedRecs[_to].push(_recId);
    ownedRecsIndex[_recId] = length;
    totalRecs = totalRecs.add(1);
  }

  /**
  * @dev Internal function to remove a REC ID from the list of a given address
  * @param _from address representing the previous owner of the given REC ID
  * @param _recId uint256 ID of the REC to be removed from the recs list of the given address
  */
  function removeREC(address _from, uint256 _recId)
  private {
    require(recOwner[_recId] == _from);

    uint256 recIndex = ownedRecsIndex[_recId];
    uint256 lastRecIndex = ownedRecs[_from].length.sub(1);
    uint256 lastRec = ownedRecs[_from][lastRecIndex];

    recOwner[_recId] = 0;
    ownedRecs[_from][recIndex] = lastRec;
    ownedRecs[_from][lastRecIndex] = 0;
   

    ownedRecs[_from].length--;
    ownedRecsIndex[_recId] = 0;
    ownedRecsIndex[lastRec] = recIndex;
    totalRecs = totalRecs.sub(1);
  }
  
  /**
  * @dev Internal function to verify an REC based on a third-party API (owner, creation etc.)
  * hard-coded to true for now (will have to set up partnership w/ REC institution such as M-RETs)
  * @return _verified boolean representing if the given REC is valid or not
  * @param _recId uint256 ID of the REC to be verified
  */
  
  function verifyREC(uint256 _recId)
  private returns (bool _verified) {
      _verified = true;
      return true;
  }
  
  /**
  * @dev Function to carry out transaction of purchasing an REC token, which includes deciding
  * the final buyer, ensuring the final buyer has enough funds, and transferring over the funds
  * from the buyer to the seller's account while transferring the ownership of the REC to the buyer.
  * @param _recId uint256 ID of the REC to be purchased
  */
  function purchaseRECItem(uint256 _recId)
        external
        payable
    {
        RECItem storage currItem = _RECItems[_recId];

        require(msg.value >= currItem.price, "Your bid is too low");
        //require that msg.sender's balance >= currItem.price
        clearApprovalAndTransfer(currItem.owner, msg.sender, _recId);
        
        
        _asyncTransfer(msg.sender, msg.value);
    }
  
  /**
  * @dev Function for a seller to collect the payments that have been made to their account.
  */
  function getPayments() external {
        withdrawPayments(msg.sender);
    }
}
