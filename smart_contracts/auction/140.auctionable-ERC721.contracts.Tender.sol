
pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/drafts/Counters.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';
import "./Oraclize.sol";


contract Ownable {

  address public _owner;

  constructor() internal {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender);
    _;
  }
  //  4) fill out the transferOwnership function
  //  5) create an event that emits anytime ownerShip is transfered (including in the constructor)
  event OwnerShipIsTransfered();

  function transferOwnership(address newOwner) public onlyOwner {
    // TODO add functionality to transfer control of the contract to a newOwner.
    //newOwner.transfer(msg.value); // if fails newOwners address
    // make sure the new owner is a real address
    if(newOwner != address(0)){
      _owner = newOwner;
      emit OwnerShipIsTransfered();
    }

  }
}

//  TODO's: Create a Pausable contract that inherits from the Ownable contract
contract Pausable is Ownable {
  //  1) create a private '_paused' variable of type bool
  bool private _paused;

  //  2) create a public setter using the inherited onlyOwner modifier
  // HERE
  function setContact() public onlyOwner{
  }

  //  3) create an internal constructor that sets the _paused variable to false
  constructor() internal {
    _paused = false;
  }

  //  4) create 'whenNotPaused' & 'paused' modifier that throws in the appropriate situation
  modifier whenNotPaused{
    if(_paused == false){
      return;
    }else{
      revert();
      //("Contract is not operational")
    }
    emit Unpaused(msg.sender);
    _;
  }
  modifier paused {
    if(_paused == true){
      return;
    }else{
      revert();
      //("Contract is operational")
    }
    emit Paused(msg.sender);
    _;
  }

  //  5) create a Paused & Unpaused event that emits the address that triggered the event
  event Paused(address indexed caller);
  event Unpaused(address indexed caller);

}

contract ERC165 {
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
  /*
  * 0x01ffc9a7 ===
  *     bytes4(keccak256('supportsInterface(bytes4)'))
  */

  /**
  * @dev a mapping of interface id to whether or not it's supported
  */
  mapping(bytes4 => bool) private _supportedInterfaces;

  /**
  * @dev A contract implementing SupportsInterfaceWithLookup
  * implement ERC165 itself
  */
  constructor () internal {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  /**
  * @dev implement supportsInterface(bytes4) using a lookup table
  */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  /**
  * @dev internal method for registering an interface
  */
  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

contract ERC721 is Pausable, ERC165 {

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  // IMPORTANT: this mapping uses Counters lib which is used to protect overflow when incrementing/decrementing a uint
  // use the following functions when interacting with Counters: increment(), decrement(), and current() to get the value
  // see: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/drafts/Counters.sol
  mapping (address => Counters.Counter) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  constructor () public {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
  }

  function balanceOf(address owner) public view returns (uint256) {
    // TODO return the token balance of given address
    // HERE
    return _ownedTokensCount[owner].current();
    // TIP: remember the functions to use for Counters. you can refresh yourself with the link above
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    // TODO return the owner of the given tokenId
    return _tokenOwner[tokenId];

  }

  //    @dev Approves another address to transfer the given token ID
  function approve(address to, uint256 tokenId) public {

    // TODO require the given address to not be the owner of the tokenId
    require(msg.sender == ownerOf(tokenId), "Sender must be the token owner");
    // TODO require the msg sender to be the owner of the contract or isApprovedForAll() to be true
    // HERE
    require(isApprovedForAll(msg.sender, to), "Is approved for all is false");
    // TODO add 'to' address to token approvals
    _tokenApprovals[tokenId] = to;
    // TODO emit Approval Event
    emit Approval(msg.sender, to, tokenId);

  }

  function getApproved(uint256 tokenId) public view returns (address) {
    // TODO return token approval if it exists
    if (_tokenApprovals[tokenId] != address(0)){
      return(_tokenApprovals[tokenId]);
    }
  }

  /**
  * @dev Sets or unsets the approval of a given operator
  * An operator is allowed to transfer all tokens of the sender on their behalf
  * @param to operator address to set the approval
  * @param approved representing the status of the approval to be set
  */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
  * @dev Tells whether an operator is approved by a given owner
  * @param owner owner address which you want to query the approval of
  * @param operator operator address which you want to query the approval of
  * @return bool whether the given operator is approved by the given owner
  */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(address from, address to, uint256 tokenId) public {
    require(_isApprovedOrOwner(msg.sender, tokenId));

    _transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
    transferFrom(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

  /**
  * @dev Returns whether the specified token exists
  * @param tokenId uint256 ID of the token to query the existence of
  * @return bool whether the token exists
  */
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  /**
  * @dev Returns whether the given spender can transfer a given token ID
  * @param spender address of the spender to query
  * @param tokenId uint256 ID of the token to be transferred
  * @return bool whether the msg.sender is approved for the given token ID,
  * is an operator of the owner, or is the owner of the token
  */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  // @dev Internal function to mint a new token
  // TIP: remember the functions to use for Counters. you can refresh yourself with the link above
  function _mint(address to, uint256 tokenId) internal {

    require(_exists(tokenId) == false);
    require(to != address(0));
    // TODO mint tokenId to given address & increase token count of owner
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to].increment();

    emit Transfer(msg.sender, to, tokenId);
  }

  // @dev Internal function to transfer ownership of a given token ID to another address.
  // TIP: remember the functions to use for Counters. you can refresh yourself with the link above
  function _transferFrom(address from, address to, uint256 tokenId) internal {

    // TODO: require from address is the owner of the given token
    require(ownerOf(tokenId) == from);

    require(to != address(0));

    _operatorApprovals[to][from] = false;
    // TODO: update token counts & transfer ownership of the token ID
    //_ownedTokensCount[from].decrement();
    _ownedTokensCount[to].increment();
    //safeTransferFrom(from,to,tokenId);
    _tokenOwner[tokenId] = to;
    // TODO: emit correct event
    emit Transfer(from, to, tokenId);
  }

  /**
  * @dev Internal function to invoke `onERC721Received` on a target address
  * The call is not executed if the target address is not a contract
  * @param from address representing the previous owner of the given token ID
  * @param to target address that will receive the tokens
  * @param tokenId uint256 ID of the token to be transferred
  * @param _data bytes optional data to send along with the call
  * @return bool whether the call correctly returned the expected magic value
  */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
  internal returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }

    bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

  // @dev Private function to clear current approval of a given token ID
  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

contract ERC721Enumerable is ERC165, ERC721 {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  /*
  * 0x780e9d63 ===
  *     bytes4(keccak256('totalSupply()')) ^
  *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
  *     bytes4(keccak256('tokenByIndex(uint256)'))
  */

  /**
  * @dev Constructor function
  */
  constructor () public {
    // register the supported interface to conform to ERC721Enumerable via ERC165
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  /**
  * @dev Gets the token ID at a given index of the tokens list of the requested owner
  * @param owner address owning the tokens list to be accessed
  * @param index uint256 representing the index to be accessed of the requested tokens list
  * @return uint256 token ID at the given index of the tokens list owned by the requested address
  */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
  * @dev Gets the token ID at a given index of all the tokens in this contract
  * Reverts if the index is greater or equal to the total number of tokens
  * @param index uint256 representing the index to be accessed of the tokens list
  * @return uint256 token ID at the given index of the tokens list
  */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

  /**
  * @dev Internal function to transfer ownership of a given token ID to another address.
  * As opposed to transferFrom, this imposes no restrictions on msg.sender.
  * @param from current owner of the token
  * @param to address to receive the ownership of the given token ID
  * @param tokenId uint256 ID of the token to be transferred
  */
  function _transferFrom(address from, address to, uint256 tokenId) internal {
    super._transferFrom(from, to, tokenId);

    _removeTokenFromOwnerEnumeration(from, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);
  }

  /**
  * @dev Internal function to mint a new token
  * Reverts if the given token ID already exists
  * @param to address the beneficiary that will own the minted token
  * @param tokenId uint256 ID of the token to be minted
  */
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);

    _addTokenToAllTokensEnumeration(tokenId);
  }

  /**
  * @dev Gets the list of token IDs of the requested owner
  * @param owner address owning the tokens
  * @return uint256[] List of token IDs owned by the requested address
  */
  function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
    return _ownedTokens[owner];
  }

  /**
  * @dev Private function to add a token to this extension's ownership-tracking data structures.
  * @param to address representing the new owner of the given token ID
  * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
  }

  /**
  * @dev Private function to add a token to this extension's token tracking data structures.
  * @param tokenId uint256 ID of the token to be added to the tokens list
  */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
  * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
  * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
  * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
  * This has O(1) time complexity, but alters the order of the _ownedTokens array.
  * @param from address representing the previous owner of the given token ID
  * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    _ownedTokens[from].length--;

    // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
    // lastTokenId, or just over the end of the array if the token was the last one).
  }

  /**
  * @dev Private function to remove a token from this extension's token tracking data structures.
  * This has O(1) time complexity, but alters the order of the _allTokens array.
  * @param tokenId uint256 ID of the token to be removed from the tokens list
  */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
  }
}

contract ERC721Metadata is ERC721Enumerable,usingOraclize {

  string private _name;
  string private _symbol;
  string private _baseTokenURI;


  // TODO: create private mapping of tokenId's to token uri's called '_tokenURIs'
  // Make this bigger with more info
  mapping (uint256 => string) private _tokenURIs;

  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  /*
  * 0x5b5e139f ===
  *     bytes4(keccak256('name()')) ^
  *     bytes4(keccak256('symbol()')) ^
  *     bytes4(keccak256('tokenURI(uint256)'))
  */


  constructor (string memory name, string memory symbol, string memory baseTokenURI) public  {
    // TODO: set instance var values
    _name = name;
    _symbol = symbol;
    _baseTokenURI = baseTokenURI;

    //_registerInterface(_INTERFACE_ID_ERC721_METADATA);
  }

  // TODO: create external getter functions for name, symbol, and baseTokenURI
  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function BaseTokenURI() external view returns (string memory) {
    return _baseTokenURI;
  }


  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    return _tokenURIs[tokenId];
  }



  // TODO: Create an internal function to set the tokenURI of a specified tokenId
  // It should be the _baseTokenURI + the tokenId in string form
  // TIP #1: use strConcat() from the imported oraclizeAPI lib to set the complete token URI
  // TIP #2: you can also use uint2str() to convert a uint to a string
  // see https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol for strConcat()
  // require the token exists before setting
  function setTokenInfo(uint256 tokenId) internal {
    require(_exists(tokenId), "Token does not exist");
    _tokenURIs[tokenId] = strConcat(_baseTokenURI, uint2str(tokenId));
  }
}



//  TODO's: Create CustomERC721Token contract that inherits from the ERC721Metadata contract. You can name this contract as you please
//  1) Pass in appropriate values for the inherited ERC721Metadata contract

//  2) create a public mint() that does the following:
//      -can only be executed by the contract owner
//      -takes in a 'to' address, tokenId, and tokenURI as parameters
//      -returns a true boolean upon completion of the function
//      -calls the superclass mint and setTokenURI functions
contract Tender is ERC721Metadata {

  mapping(uint256 => Auction) private auction; // tokenID to tender auction information

  address constant GUARD = address(1);

  struct Auction {
    uint256 minBid;
    uint256 openingTime;
    uint256 closingTime;

    mapping(address => Bid) bids;
    mapping(address => address) _nextBidders;
    uint256 listSize;

    address contractWinner;
    MultiSign sign;
  }

  struct Bid {
    address bidder;
    uint256 price;
    string contractBudget;
  }

  struct MultiSign {
    bool owner;
    bool bidder;
  }

  /*
    Events
  */

  event BidRemoved(uint256 token);
  event Winner(uint256 token, address winner);
  event Approved(uint256 token, address winner);
  event Signed(uint256 token, address winner);
  /*
    Modifiers
  */

  modifier _isMultiSign(uint256 token) {
    require(isSigned(token),"Winner or owner have not been signed.");
    _;
  }

  modifier _isBidderSign(uint256 token) {
    require(bidderSigned(token),"Bidder winner has not signed.");
    _;
  }

  modifier _isOwnerSign(uint256 token) {
    require(ownerSigned(token),"Owner has not signed.");
    _;
  }

  modifier _hasWinner(uint256 token) {
    require(hasWinner(token), "Winner has not been selected");
    _;
  }

  modifier onlyWhileOpen(uint256 token) {
      require(isOpen(token), "Auction not open");
      _;
  }
  modifier onlyWhileClosed(uint256 token) {
    require(hasClosed(token), "Auction is still open");
    _;
  }

  /*
    Multi Sign functions
  */

  function approve(address to, uint256 tokenId)
  public
    _isBidderSign(tokenId)
    _isOwnerSign(tokenId)
  {
    super.approve(to, tokenId);
    emit Approved(tokenId,to);
  }

  function signContract(uint256 token)
  public
  onlyWhileClosed(token)
  {
    require(auction[token].contractWinner != address(0x0),"Winning has not been choosen.");
    require(auction[token].contractWinner == msg.sender || _owner == msg.sender,"Address not assocated with token");
    if (msg.sender == _owner) {
      auction[token].sign.owner = true;
    }else{
      auction[token].sign.bidder = true;
    }
  }


  function chooseWinner(uint256 token, address bidder)
  public
  onlyWhileClosed(token)
  {
    require(msg.sender == _owner);
    auction[token].contractWinner = bidder;
    setApprovalForAll(bidder,true);
    emit Winner(token,bidder);
  }

  /*
    Auction functions
  */

  function addBid(uint256 token,uint256 _price, string memory _contractBudget)
  public
  onlyWhileOpen(token)
  {
    require(auction[token]._nextBidders[msg.sender] == address(0),"Bid has already been placed"); // check if bidder has already bid
    require(_price != 0, "Cant add a bid of price of zero");
    //require(auction[token]._nextBidders[msg.sender])
    // create new bid within token auction
    Bid memory newBid;
    newBid.price = _price;
    newBid.contractBudget = _contractBudget;
    newBid.bidder = msg.sender;
    auction[token].bids[msg.sender] = newBid;

    address index = _findIndex(token,_price);
    auction[token]._nextBidders[msg.sender] = auction[token]._nextBidders[index];
    auction[token]._nextBidders[index] = msg.sender;
    auction[token].listSize++;

  }

  function updateBid(uint256 token,uint256 newPrice, string memory newContractBudget)
  public
  onlyWhileOpen(token)
  {
    require(auction[token]._nextBidders[msg.sender] != address(0));
    address prevBidder = _findPrevBidder(token,msg.sender);
    address nextBidder = auction[token]._nextBidders[msg.sender];
    if(_verifyIndex(token,prevBidder,newPrice,msg.sender)){ // check if index is the same
       auction[token].bids[msg.sender].price = newPrice;
       auction[token].bids[msg.sender].contractBudget = newContractBudget;
       // no need to update bidder address
    }else{ // update with new location
      removeBid(token);
      addBid(token, newPrice, newContractBudget);
    }
  }

  function removeBid(uint256 token)
  public
  onlyWhileOpen(token)
  {
    address prevBidder = _findPrevBidder(token,msg.sender);
    auction[token]._nextBidders[prevBidder] =  auction[token]._nextBidders[msg.sender];
    auction[token]._nextBidders[msg.sender] = address(0);

    auction[token].bids[msg.sender].price = 0;
    auction[token].bids[msg.sender].bidder = address(0);
    auction[token].bids[msg.sender].contractBudget = "";

    auction[token].listSize--;
  }

  /**

  Bid tracker

  **/

  function _verifyIndex(uint256 token, address prevBid, uint256 newValue, address nextBid)
    internal
    view
    returns(bool)
  {
    return  (prevBid == GUARD || auction[token].bids[prevBid].price >= newValue) &&
            (nextBid == GUARD || newValue > auction[token].bids[nextBid].price);
  }

  function _findIndex(uint256 token ,uint256 newValue)
    internal
    view
    returns(address)
  {
    // loop from GUARD through list ot find valid index by checking with _verifyIndex
    // This guarantee that we will find a valid index
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex(token, candidateAddress,newValue,auction[token]._nextBidders[candidateAddress]))
          return candidateAddress;
      candidateAddress = auction[token]._nextBidders[candidateAddress];
    }
  }

  function _isPrevBidder(uint256 token, address bidder, address prevBidder)
    internal
    view
    returns(bool)
  {
    return auction[token]._nextBidders[prevBidder] == bidder;
  }

  function _findPrevBidder(uint256 token, address bidder)
    internal
    view
    returns(address)
  {
    address currentAddress = GUARD;
    while(auction[token]._nextBidders[currentAddress] != GUARD){
      if(_isPrevBidder(token,bidder,currentAddress))
        return currentAddress;
      currentAddress = auction[token]._nextBidders[currentAddress];
    }
    return address(0);
  }

  /**

  Getters

  **/

  function getBidInfo(uint256 token,address _bid)
  public
  view
  returns(
          address bidder,
          uint256 price,
          string memory contractBudget
         )
  {

    return (auction[token].bids[_bid].bidder,
            auction[token].bids[_bid].price,
            auction[token].bids[_bid].contractBudget
    );
  }

  function getAuctionSize(uint256 token)
  public
  view
  returns(uint256 size)
  {
    return (auction[token].listSize);
  }

  function getTokenAuctionInfo(uint256 token)
  public
  view
  returns(uint256 minBid,
          uint256 bidderCount,
          uint256 openingTime,
          uint256 closingTime,
          bool isAvailable
          )
  {
    Auction memory _auction = auction[token];
    return(
      _auction.minBid,
      _auction.listSize,
      _auction.openingTime,
      _auction.closingTime,
      isAvailable
    );
  }

  function getTop(uint256 token, uint256 k)
  public
  view
  returns(address[] memory)
  {
    require(k <= auction[token].listSize);
    address[] memory topBidders = new address[](k);
    address currentAddress = auction[token]._nextBidders[GUARD];
    for(uint256 i = 0; i < k; ++i) {
      topBidders[i] = currentAddress;
      currentAddress = auction[token]._nextBidders[currentAddress];
    }
    return topBidders;
  }

  function getWinner(uint256 token)
  public
  view
  onlyWhileClosed(token)
  _hasWinner(token)
  returns(address winner)
  {
    Auction memory _auction = auction[token];
    return (_auction.contractWinner);
  }

  function isOpen(uint256 token)
  public
  view
  returns(bool open)
  {
    Auction memory _auction = auction[token];
    return (block.timestamp >= _auction.openingTime && block.timestamp <= _auction.closingTime);
  }

  function hasClosed(uint256 token)
  public
  view
  returns (bool)
  {
      Auction memory _auction = auction[token];
      return block.timestamp > _auction.closingTime;
  }

  function hasWinner(uint256 token)
  public
  view
  returns(bool)
  {
    return(auction[token].contractWinner != address(0x0));
  }

  function bidderSigned(uint256 token)
  public
  view
  returns(bool)
  {
    return(auction[token].sign.bidder == true);
  }

  function ownerSigned(uint256 token)
  public
  view
  returns(bool)
  {
    return(auction[token].sign.owner == true);
  }

  function isSigned(uint256 token)
  public
  view
  returns(bool)
  {
    return(auction[token].sign.owner == true && auction[token].sign.bidder == true);
  }


  /**

  Default ERC721

  **/

  event Mint(uint256 tokenId);

  constructor(string memory name, string memory symbol) public
    ERC721Metadata(name, symbol, "https://github.com/MitchTODO/") // Could be used to show pic with url
  {

  }

  // New tokens are minted
  function mint(address to, uint256 tokenId, uint256 _minBid,uint256 _openingTime,uint256 _closingTime)
  public
  returns (bool)

  {
    require(_openingTime >= block.timestamp, "Cant start auction opening time is before current time");
    require(_closingTime > _openingTime, "Cant start auction opening time is not before closing time");

    super._mint(to, tokenId);
    setTokenInfo(tokenId);

    Auction memory newTokenAuction;
    newTokenAuction.minBid = _minBid;
    newTokenAuction.openingTime = _openingTime;
    newTokenAuction.closingTime = _closingTime;

    auction[tokenId] = newTokenAuction;
    auction[tokenId]._nextBidders[GUARD] = GUARD;

    emit Mint(tokenId);
    return (true);
  }

}
