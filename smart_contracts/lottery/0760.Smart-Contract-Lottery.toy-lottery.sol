pragma solidity ^0.4.20;

//CHAN NGAE CHAU ID: 20411891
//Blockchain - No.8 Mid-term
//

library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract WelfareLottery {
  using SafeMath for uint256;
    
  address private owner; 
  address private charity; //address of charity which always get 90%
  uint256 threshold; //the value to start a game
  
  uint256 prev_random = 0; //for checking what was last random number - for diagnostic
  
  struct Gamer {
    uint256 number;
    uint256 val;
    address who;
    bool paid;
  }
  Gamer[] private gamers; //gamers address and the value he pays

  function WelfareLottery() public {
    owner = msg.sender;
    charity = owner; //for simplicity let's set: this charity is the owner, we can also set charity later

    threshold = 10000 ether; //the value to start a game
  }

   /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }
  
  /* Charity */
  function setCharity (address _charity) public {
      //of course we can set chairty
    charity = _charity;
  }
  
  function getBalance() onlyOwner() public view returns (uint256){
    return this.balance;
  }
  
  function getIndividualBalance() public view returns (uint256){
    return msg.sender.balance;
  }
  
  function getPrevRandom() public view returns (uint256){
    return prev_random;
  }
  
  function createGamer (uint256 _number, address _addr, uint256 _value) private returns (uint8) {

    gamers.push(Gamer({
      number: _number,
      who: _addr,
      val: _value,
      paid: false
    }));
    return (getGamerLength() - 1);
  }
  
  /* Withdraw */
  function withdrawAll () onlyOwner() public {
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }
  
  /* Game */
  function joinGame (uint256 _number) payable public {
    //create gamer who will join the game  
    createGamer(_number, msg.sender, msg.value);
    
    if (this.balance >= threshold) //ready to start the game?
    {
      //random number is 0-99
      uint random = (block.timestamp + block.difficulty + block.number + 256) % 100;
      prev_random = random;//for diagnostic
      
      //range 1st-tier, 25%
      uint lower1 = random-5;
      uint upper1 = random+5;
      uint percentage1 = 25;
      
      //range 2nd-tier, 30%
      uint lower2 = random-10;
      uint upper2 = random+10;
      uint percentage2 = 30;
      
      //range 3rd-tier, 35%
      uint lower3 = random-15;
      uint upper3 = random+15;
      uint percentage3 = 35;
      
      //keep the balance for the rest of calculation
      //if always using this.Balance, this variable is actually keeps diminishing after Transfer()
      //charity always get 10%
      uint256 tempBalance = this.balance; 
      
      charity.transfer(tempBalance.div(100).mul(10));
      
      checkWinner(tempBalance, lower1, upper1, percentage1);
      checkWinner(tempBalance, lower2, upper2, percentage2);
      checkWinner(tempBalance, lower3, upper3, percentage3);
      
      //any remaining for next round is the this.balance
      
      //restart game
      restartGame();
      
    }
  }
  
  function checkWinner (uint256 _tempBalance, uint _lower, uint _upper, uint _percentage) internal {
    //check the sum of the values of those winners
      uint256 sum = 0;
      for(uint256 i = 0; i < gamers.length; i++)
      {
          if(gamers[i].paid == false)
          {
            if(gamers[i].number >= _lower && gamers[i].number <= _upper)
            {
                sum += gamers[i].val;
            }
          }
      }
      
      //distribute accoring to the portportion the gamers paid
      for(i = 0; i < gamers.length; i++)
      {
          //Gamer g = gamers[i];
          if(gamers[i].paid == false)
          {
            if(gamers[i].number >= _lower && gamers[i].number <= _upper)
            {
                gamers[i].who.transfer(
                    _tempBalance.div(100).
                    mul(_percentage).
                    mul(gamers[i].val).
                    div(sum));
                    
                gamers[i].paid = true; 
            }
          }
      }
      
  }
  
  function min(uint256 a, uint256 b) private pure returns (uint256) {
    return a < b ? a : b;
  }
  
  function getGamerLength() public view returns (uint8) {
    return uint8(gamers.length);
  }
  
  function getGamer(uint8 _gamerId) public view returns (uint256 _number, bool _paid, address _addr, uint _val){
    require(_gamerId < getGamerLength());
    
    Gamer storage gamer = gamers[_gamerId];
    return (gamer.number, gamer.paid, gamer.who, gamer.val) ;
  }

  function calculateDevCut(uint256 _value) internal pure returns (uint256 _devCut) {
    return _value.div(100).mul(95); // 5% service charge
  }

  function restartGame () internal {
 
    while(gamers.length > 0)
    {
        delete gamers[0];
        gamers.length--;
    }
  }
}