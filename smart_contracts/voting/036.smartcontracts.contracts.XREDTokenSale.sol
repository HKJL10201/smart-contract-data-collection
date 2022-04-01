pragma solidity ^0.4.15;

import "zeppelin/contracts/math/SafeMath.sol";
import "./interface/TokenController.sol";
import "./XREDCoin.sol";
import "./XREDCoinPlaceholder.sol";
import "./SaleWallet.sol";

/**
 * Copyright 2017, Konstantin Viktorov (XRED Foundation)
 * Copyright 2017, Jorge Izquierdo (Aragon Foundation)
 * Copyright 2017, Jordi Baylina (Giveth)
 *
 * Based on SampleCampaign-TokenController.sol from https://github.com/Giveth/minime
 **/

contract XREDTokenSale is TokenController {
    uint public initialBlock;             // Block number in which the sale starts. Inclusive. sale will be opened at initial block.
    uint public finalBlock;               // Block number in which the sale end. Exclusive, sale will be closed at ends block.
    uint public initialPrice;             // Number of wei-XREDCoin tokens for 1 wei, at the start of the sale (18 decimals)
    uint public finalPrice;               // Number of wei-XREDCoin tokens for 1 wei, at the end of the sale
    uint8 public priceStages;             // Number of different price stages for interpolating between initialPrice and finalPrice
    address public XREDDevMultisig;       // The address to hold the funds donated
    address public communityMultisig;     // Community trusted multisig to deploy network
    bytes32 public capCommitment;

    uint public totalCollected = 0;               // In wei
    bool public saleStopped = false;              // Has XRED Dev stopped the sale?
    bool public saleFinalized = false;            // Has XRED Dev finalized the sale?

    mapping (address => bool) public activated;   // Address confirmates that wants to activate the sale

    XREDCoin public token;                             // The token
    XREDCoinPlaceholder public networkPlaceholder;      // The network placeholder
    SaleWallet public saleWallet;                    // Wallet that receives all sale funds

    uint constant public dust = 1 finney;         // Minimum investment
    uint public hardCap = 1000000 ether;          // Hard cap to protect the ETH network from a really high raise

    event NewPresaleAllocation(address indexed holder, uint256 XREDCoinAmount);
    event NewBuyer(address indexed holder, uint256 XREDCoinAmount, uint256 etherAmount);
    event CapRevealed(uint value, uint secret, address revealer);
/// @dev There are several checks to make sure the parameters are acceptable
/// @param _initialBlock The Block number in which the sale starts
/// @param _finalBlock The Block number in which the sale ends
/// @param _XREDDevMultisig The address that will store the donated funds and manager
/// for the sale
/// @param _initialPrice The price for the first stage of the sale. Price in wei-XREDCoin per wei.
/// @param _finalPrice The price for the final stage of the sale. Price in wei-XREDCoin per wei.
/// @param _priceStages The number of price stages. The price for every middle stage
/// will be linearly interpolated.
/*
 price
        ^
        |
Initial |       s = 0
price   |      +------+
        |      |      | s = 1
        |      |      +------+
        |      |             | s = 2
        |      |             +------+
        |      |                    | s = 3
Final   |      |                    +------+
price   |      |                           |
        |      |    for priceStages = 4    |
        +------+---------------------------+-------->
          Initial                     Final       time
          block                       block


Every stage is the same time length.
Price increases by the same delta in every stage change

*/

  function XREDTokenSale (
      uint _initialBlock,
      uint _finalBlock,
      address _XREDDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages,
      bytes32 _capCommitment
  )
      non_zero_address(_XREDDevMultisig)
  {
      require(_communityMultisig != 0);
      assert (_initialBlock >= getBlockNumber());
      assert (_initialBlock < _finalBlock);
      assert (_initialPrice > _finalPrice);
      assert(_priceStages >= 2);
      assert (_priceStages <= _initialPrice - _finalPrice);
      assert(uint(_capCommitment) != 0);

      // Save constructor arguments as global variables
      initialBlock = _initialBlock;
      finalBlock = _finalBlock;
      XREDDevMultisig = _XREDDevMultisig;
      communityMultisig = _communityMultisig;
      initialPrice = _initialPrice;
      finalPrice = _finalPrice;
      priceStages = _priceStages;
      capCommitment = _capCommitment;
  }

  modifier only(address x) {
    require(msg.sender == x);
    _;
  }

  modifier verify_cap(uint256 _cap, uint256 _cap_secure) {
    require(isValidCap(_cap, _cap_secure));
    _;
  }

  modifier only_before_sale {
    require(getBlockNumber() < initialBlock);
    _;
  }

  modifier only_during_sale_period {
    require(getBlockNumber() >= initialBlock);
    require(getBlockNumber() < finalBlock);
    _;
  }

  modifier only_after_sale {
    require(getBlockNumber() >= finalBlock);
    _;
  }

  modifier only_sale_stopped {
    require(saleStopped);
    _;
  }

  modifier only_sale_not_stopped {
    require(!saleStopped);
    _;
  }

  modifier only_before_sale_activation {
    require(!isActivated());
    _;
  }

  modifier only_sale_activated {
    require(isActivated());
    _;
  }

  modifier only_finalized_sale {
    require(getBlockNumber() >= finalBlock);
    require(saleFinalized);
    _;
  }

  modifier non_zero_address(address x) {
    require(x != 0);
    _;
  }

  modifier minimum_value(uint256 x) {
    require(msg.value >= x);
    _;
  }

  // @notice Deploy XREDCoin is called only once to setup all the needed contracts.
  // @param _token: Address of an instance of the XREDCoin token
  // @param _networkPlaceholder: Address of an instance of XREDCoinPlaceholder
  // @param _saleWallet: Address of the wallet receiving the funds of the sale

  function setXREDCoin(address _token, address _networkPlaceholder, address _saleWallet) payable
           non_zero_address(_token)
           only(XREDDevMultisig)
           public {

    require(_networkPlaceholder != 0);
    require(_saleWallet != 0);
    // Assert that the function hasn't been called before, as activate will happen at the end
    assert(!activated[this]);

    token = XREDCoin(_token);
    networkPlaceholder = XREDCoinPlaceholder(_networkPlaceholder);
    saleWallet = SaleWallet(_saleWallet);

    assert(token.controller() == address(this)); // sale is controller
    assert(token.totalSupply() == 0); // token is empty

    assert(networkPlaceholder.sale() == address(this)); // placeholder has reference to Sale
    assert(networkPlaceholder.token() == address(token)); // placeholder has reference to XREDCoin
    assert(saleWallet.finalBlock() == finalBlock); // final blocks must match
    assert(saleWallet.multisig() == XREDDevMultisig); // receiving wallet must match
    assert(saleWallet.tokenSale() == address(this)); // watched token sale must be self

    // Contract activates sale as all requirements are ready
    doActivateSale(this);
  }

  // @notice Certain addresses need to call the activate function prior to the sale opening block.
  // This proves that they have checked the sale contract is legit, as well as proving
  // the capability for those addresses to interact with the contract.
  function activateSale()
           public {
    doActivateSale(msg.sender);
  }

  function doActivateSale(address _entity)
    non_zero_address(token)               // cannot activate before setting token
    only_before_sale
    private {
    activated[_entity] = true;
  }

  // @notice Whether the needed accounts have activated the sale.
  // @return Is sale activated
  function isActivated() constant public returns (bool) {
    return activated[this] && activated[XREDDevMultisig] && activated[communityMultisig];
  }

  // @notice Get the price for a XREDCoin token at any given block number
  // @param _blockNumber the block for which the price is requested
  // @return Number of wei-XREDCoin for 1 wei
  // If sale isn't ongoing for that block, returns 0.
  function getPrice(uint _blockNumber) constant public returns (uint256) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;

    return priceForStage(stageForBlock(_blockNumber));
  }

  // @notice Get what the stage is for a given blockNumber
  // @param _blockNumber: Block number
  // @return The sale stage for that block. Stage is between 0 and (priceStages - 1)
  function stageForBlock(uint _blockNumber) constant internal returns (uint8) {
    uint blockN = SafeMath.sub(_blockNumber, initialBlock);
    uint totalBlocks = SafeMath.sub(finalBlock, initialBlock);

    return uint8(SafeMath.div(SafeMath.mul(priceStages, blockN), totalBlocks));
  }

  // @notice Get what the price is for a given stage
  // @param _stage: Stage number
  // @return Price in wei for that stage.
  // If sale stage doesn't exist, returns 0.
  function priceForStage(uint8 _stage) constant internal returns (uint256) {
    if (_stage >= priceStages) return 0;
    uint priceDifference = SafeMath.sub(initialPrice, finalPrice);
    uint stageDelta = SafeMath.div(priceDifference, uint(priceStages - 1));
    return SafeMath.sub(initialPrice, SafeMath.mul(uint256(_stage), stageDelta));
  }

  // @notice XRED Dev needs to make initial token allocations for presale partners
  // This allocation has to be made before the sale is activated. Activating the sale means no more
  // arbitrary allocations are possible and expresses conformity.
  // @param _receiver: The receiver of the tokens
  // @param _amount: Amount of tokens allocated for receiver.
  function allocatePresaleTokens(address _receiver, uint _amount, uint64 cliffDate, uint64 vestingDate)
           only_before_sale_activation
           only_before_sale
           non_zero_address(_receiver)
           only(XREDDevMultisig)
           public {

    assert(_amount <= 12 ** 25); // 12 million XREDCoin. Presale partners will not have more than this allocated. Prevent overflows.

    assert(token.generateTokens(address(this), _amount));
    token.grantVestedTokens(_receiver, _amount, uint64(now), cliffDate, vestingDate, true, false);

    NewPresaleAllocation(_receiver, _amount);
  }

/// @dev The fallback function is called when ether is sent to the contract, it
/// simply calls `doPayment()` with the address that sent the ether as the
/// `_owner`. Payable is a require solidity modifier for functions to receive
/// ether, without this modifier functions will throw if ether is sent to them

  function () public payable {
    return doPayment(msg.sender);
  }

/////////////////
// Controller interface
/////////////////

/// @notice `proxyPayment()` allows the caller to send ether to the Token directly and
/// have the tokens created in an address of their choosing
/// @param _owner The address that will hold the newly created tokens

  function proxyPayment(address _owner) payable public returns (bool) {
    doPayment(_owner);
    return true;
  }

/// @notice Notifies the controller about a transfer, for this sale all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    // Until the sale is finalized, only allows transfers originated by the sale contract.
    // When finalizeSale is called, this function will stop being called and will always be true.
    return _from == address(this);
  }

/// @notice Notifies the controller about an approval, for this sale all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    // No approve/transferFrom during the sale
    return false;
  }

/// @dev `doPayment()` is an internal function that sends the ether that this
///  contract receives to the XREDDevMultisig and creates tokens in the address of the
/// @param _owner The address that will hold the newly created tokens

  function doPayment(address _owner)
           only_during_sale_period
           only_sale_not_stopped
           only_sale_activated
           non_zero_address(_owner)
           minimum_value(dust)
           internal {

    assert(totalCollected + msg.value <= hardCap); // If past hard cap, throw

    uint256 boughtTokens = SafeMath.mul(msg.value, getPrice(getBlockNumber())); // Calculate how many tokens bought

    assert(saleWallet.send(msg.value)); // Send funds to multisig
    assert(token.generateTokens(_owner, boughtTokens)); // Allocate tokens. This will fail after sale is finalized in case it is hidden cap finalized.

    totalCollected = SafeMath.add(totalCollected, msg.value); // Save total collected amount

    NewBuyer(_owner, boughtTokens, msg.value);
  }

  // @notice Function to stop sale for an emergency.
  // @dev Only XRED Dev can do it after it has been activated.
  function emergencyStopSale()
           only_sale_activated
           only_sale_not_stopped
           only(XREDDevMultisig)
           public {

    saleStopped = true;
  }

  // @notice Function to restart stopped sale.
  // @dev Only XRED Dev can do it after it has been disabled and sale is ongoing.
  function restartSale()
           only_during_sale_period
           only_sale_stopped
           only(XREDDevMultisig)
           public {

    saleStopped = false;
  }

  function revealCap(uint256 _cap, uint256 _cap_secure)
           only_during_sale_period
           only_sale_activated
           verify_cap(_cap, _cap_secure)
           public {

    assert(_cap <= hardCap);

    hardCap = _cap;
    CapRevealed(_cap, _cap_secure, msg.sender);

    if (totalCollected + dust >= hardCap) {
      doFinalizeSale(_cap, _cap_secure);
    }
  }

  // @notice Finalizes sale generating the tokens for XRED Dev.
  // @dev Transfers the token controller power to the XREDCoinPlaceholder.
  function finalizeSale(uint256 _cap, uint256 _cap_secure)
           only_after_sale
           only(XREDDevMultisig)
           public {

    doFinalizeSale(_cap, _cap_secure);
  }

  function doFinalizeSale(uint256 _cap, uint256 _cap_secure)
           verify_cap(_cap, _cap_secure)
           internal {
    // Doesn't check if saleStopped is false, because sale could end in a emergency stop.
    // This function cannot be successfully called twice, because it will top being the controller,
    // and the generateTokens call will fail if called again.

    // XRED Dev owns 14% of the total number of emitted tokens at the end of the sale. (12 purchased + 2 bounty)
    uint256 XREDTokens = token.totalSupply() * 7 / 43; // totalSupply here 86%, then we 14%/86% to get amount 14% of total tokens
    assert(token.generateTokens(XREDDevMultisig, XREDTokens));
    token.changeController(networkPlaceholder); // Sale loses token controller power in favor of network placeholder

    saleFinalized = true;  // Set stop is true which will enable network deployment
    saleStopped = true;
  }

  // @notice Deploy XRED Network contract.
  // @param networkAddress: The address the network was deployed at.
  function deployNetwork(address networkAddress)
           only_finalized_sale
           non_zero_address(networkAddress)
           only(communityMultisig)
           public {

    networkPlaceholder.changeController(networkAddress);
  }

  function setXREDDevMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(XREDDevMultisig)
           public {

    XREDDevMultisig = _newMultisig;
  }

  function setCommunityMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(communityMultisig)
           public {

    communityMultisig = _newMultisig;
  }

  function getBlockNumber() constant internal returns (uint) {
    return block.number;
  }

  function computeCap(uint256 _cap, uint256 _cap_secure) constant public returns (bytes32) {
    return sha3(_cap, _cap_secure);
  }

  function isValidCap(uint256 _cap, uint256 _cap_secure) constant public returns (bool) {
    return computeCap(_cap, _cap_secure) == capCommitment;
  }
}
