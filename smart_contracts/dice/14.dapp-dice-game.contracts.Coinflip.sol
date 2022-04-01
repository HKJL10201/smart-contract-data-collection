pragma solidity 0.5.12;

contract Coinflip {
  address payable public _owner;
  uint public _contractBalance;
  uint public _amountBet;

  event contractFunded(address owner, uint amount);
  event betMade(address _user, uint bet, bool won);
  event drained(address _drainer, bool passed);

  constructor() public {
    _owner = msg.sender;
    _contractBalance == (address(this).balance);
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "Only Owner can do this");
    _;
  }

  modifier minimum(uint cost) {
    require(msg.value >= cost, "Insufficient balance. Bet More!");
    _;
  }

  function createBet(uint headTails) public payable minimum(0.1 ether) {
    require(msg.value <= address(this).balance, "Maximum bet exceeded balance. Chill.");
    _amountBet = msg.value;
    uint result = (now % 2);
    bool wonResult = false;

    // win bet, get double the amount
    if(headTails == result ){
      wonResult = true;
      _contractBalance += _amountBet;
      emit betMade(msg.sender, _amountBet, wonResult);
    }
    // lose, reduce balance by _amountBet
    else if (headTails == result ) {
      wonResult = false;
      _contractBalance -= _amountBet;
      emit betMade(msg.sender, _amountBet, wonResult);
    }
  }

  /* Get Contract Balance */
  function getBalance() public view returns (uint256) {
    return (address(this).balance);
  }

  /* Add to Contract Balance */
  // function() external payable {
  function deposit() public payable {
    require(msg.value >= 0.5 ether, "Minimum deposit is 0.5 Ether");
    _contractBalance += msg.value;
    emit contractFunded(msg.sender, msg.value);
  }

  /* Owner can withdraw all balance */
  function withdrawAll() public onlyOwner returns (uint) {
    uint toTx = (address(this).balance);
    bool drainResult = false;

    /* Set balance to 0 */
    _contractBalance = 0;
    if(msg.sender.send(toTx)) {
      drainResult = true;
      emit drained(msg.sender, drainResult);
      return toTx;
    } else {
      drainResult = false;
      emit drained(msg.sender, drainResult);
      /* Set balance back to toTx */
      _contractBalance = toTx;
      return 0;
    }
  }
}
