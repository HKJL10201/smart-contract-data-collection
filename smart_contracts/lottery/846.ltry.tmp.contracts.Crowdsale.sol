pragma solidity ^0.4.11;


import './lib/SafeMathLib.sol';
import './ownership/Owned.sol';
import './LotteryToken.sol';


// Crowdsale contract
//
contract Crowdsale is Owned {


  using SafeMathLib for uint;


  address public beneficiary;
  uint public amountRaised;
  uint public fundingGoal;
  uint public price;
  uint public startTime;
  uint public endTime;
  LotteryToken public tokenReward;


  // Crowdsale Statistics
  //
  uint256 public tokensLimit;
  uint256 public tokensIssued;
  uint256 public weiRefunded;


  // Crowdsale state
  //
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}
  State state;


  // List of investor addresses, used when finalizing the crowdsale
  //
  address[] public addresses;


  // Tokens to be issued to the given address
  //
  mapping(address => uint256) public tokens;


  // Amount funded by each address
  //
  mapping(address => uint256) public invested;



  bool fundingGoalReached = false;
  bool crowdsaleOpen = false;


  // Crowdsale contract constructor
  //
  // @param _beneficiary Address of crowdsale beneficiary
  // @param _fundingGoal Target goal of the crowdfunding in Ethereum
  // @param _price Price of each token in Ethereun
  // @param _startTime Crowdsale starting time
  // @param _endTime Crowdsale ending time
  // @param _tokensLimit Token limit after which minting starts
  // @param _tokenReward Address of the token used as reward
  //
  function Crowdsale(address _beneficiary, uint _fundingGoal, uint _price, uint _startTime, uint _endTime, uint256 _tokensLimit, LotteryToken _tokenReward) {
    beneficiary = _beneficiary;
    fundingGoal = _fundingGoal * 1 ether;
    price = _price * 1 ether;
    startTime = _startTime;
    endTime = _endTime;
    tokensLimit = _tokensLimit;
    tokenReward = LotteryToken(_tokenReward);
    state = State.Preparing;

    require(startTime < endTime);
  }


  // The function without name is the default function that is called whenever
  // anyone sends funds to a contract
  //
  function () payable duringCrowdsale {
    uint amount = msg.value;
    uint tokensAmount = amount.div(price);

    // Store details about crowdsale investors
    if (invested[msg.sender] == 0) addresses.push(msg.sender);
    invested[msg.sender] = invested[msg.sender].plus(amount);
    tokens[msg.sender] = tokens[msg.sender].plus(tokensAmount);

    // Update crowdsale statistics
    amountRaised = amountRaised.plus(amount);
    tokensIssued = tokensIssued.plus(tokensAmount);

    FundTransfer(msg.sender, amount, true);
  }


  // Receives the approveAndCall function call. It might be useful for
  // intercontract communication in the future.
  //
  // @param _spender The address of the account able to transfer the tokens
  // @param _value The amount of tokens to be approved for transfer
  // @param _extraData Any extra data that might be sent
  // @return Whether the approval was successful or not
  //
  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) {
    ReceivedApproval(_from, _value, _tokenContract, _extraData);
  }


  // Withdraw the amount raised after the crowdsale
  //
  function withdraw() afterCrowdsale {
    if (beneficiary == msg.sender) {
      require(beneficiary.send(amountRaised));
      FundTransfer(beneficiary, amountRaised, false);
    }
  }


  // Finalize a succcesful crowdsale.
  //
  // The owner can trigger a call to the contract that provides post-crowdsale
  // actions, like releasing the tokens.
  //
  function finalize() public onlyOwner {
    // Already finalized
    require(!inState(State.Finalized));

    // Total number of tokens transferred until now, used to check whether to
    // transfer or mint tokens
    uint totalTokensTransferred = 0;

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    //
    for (uint i = 0; i < addresses.length; i++) {
      uint tokensToTransfer = tokens[addresses[i]];

      if (tokensToTransfer == 0) continue;
      totalTokensTransferred = totalTokensTransferred.plus(tokensToTransfer);

      // Start minting tokens if crowdsale token limit reached
      if (totalTokensTransferred <= tokensLimit) {
        tokenReward.transfer(addresses[i], tokensToTransfer);
      } else {
        tokenReward.mint(addresses[i], tokensToTransfer);
      }
    }

    setState(State.Finalized);
  }


  // Investors can claim refund.
  //
  // Note that any refunds from proxy buyers should be handled separately,
  // and not through this contract.
  //
  function refund() public {
    require(inState(State.Refunding));

    uint256 weiValue = invested[msg.sender];

    require(weiValue != 0);

    invested[msg.sender] = 0;
    weiRefunded = weiRefunded.plus(weiValue);

    Refund(msg.sender, weiValue);
    require(msg.sender.send(weiValue));
  }


  // Start refund period if the crowdsale doesn't succeed
  //
  function setState(State _state) public onlyOwner {
    state = _state;
  }


  // Start refund period if the crowdsale doesn't succeed
  //
  function inState(State _state) constant returns (bool _inState) {
    return state == _state;
  }


  // Check whether the action is being called during the crowdsale
  //
  modifier duringCrowdsale() {
    if (now >= startTime && now <= endTime) _;
  }


  // Check whether the crowdsale has ended
  //
  modifier afterCrowdsale() {
    if (now > endTime) _;
  }

  event GoalReached(address _beneficiary, uint _amountRaised);
  event FundTransfer(address _backer, uint _amount, bool _isContribution);
  event ReceivedApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);
  event Refund(address _to, uint _amount);
}
