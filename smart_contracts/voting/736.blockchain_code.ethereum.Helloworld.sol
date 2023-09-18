pragma solidity 0.5.3;


/**
 * The Ownable contract does this and that...
 */
contract Ownable {
  address payable public owner;
  event OwnerShipTransferred(address newOwner);
 
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() { 
    require (msg.sender == owner, "Vc não é o dono"); 
    _; 
   }

  function transferOwnerShip (address payable newOwner) onlyOwner public {
      owner = newOwner;

      emit OwnerShipTransferred(owner);
  }

}

contract Helloworld {
  using SafeMath for uint;

  string public text;
  uint public number;
  address public userAddress;
  bool public answer;

  mapping (address => uint) public hasIntereacted;

  mapping (address => uint) public balances;
      

  function setText(string memory myText) onlyOwner public {
  	text = myText;
  	setIntereacted();
  }

  function setNumber(uint myNumber) public payable{
  	require(msg.value >= 0.01 ether, "Insuficiente Ether");
  	
  	balances[msg.sender] = balances[msg.sender].sum(msg.value);
  	number = myNumber;
  	setIntereacted();
  }

  function setAddress() public{
  	userAddress = msg.sender;
  	setIntereacted();
  }
  
  function setAnswer(bool TrueOrFalse)public {
      answer = TrueOrFalse;
      setIntereacted();
  }

  function setIntereacted() private {
  	hasIntereacted[msg.sender] = hasIntereacted[msg.sender].sum(1);
  }


  function sendETH (address payable targetAddress) public payable {
  	targetAddress.transfer(msg.value);
  }
  
  function withDraw () public {
  	require (balances[msg.sender] > 0 , "Saldo Insuficiente");
  	
  	uint amount = balances[msg.sender];
  	balances[msg.sender] = 0; 
  	msg.sender.transfer(amount);

  }

	function sumNumber(uint num1) public view returns(uint){
      return num1.sum(number);
  }

}

/**
 * The SafeMath library does this and that...
 */

library SafeMath {
  
   function sum(uint a, uint b) internal pure returns(uint) {
  	uint c = a + b;

  	require (c >= a, "Sum Overflow!!!");
  	
  	return c;
  }

   function mul(uint a, uint b) internal pure returns(uint){
   		if(a == 0 || b == 0){
   			return 0;
   		}
   		uint c = a * b;
   		require (c /a == b, "Mul Overflow!!!");
   		
      return c;
  }

	function sub(uint a, uint b) internal pure returns(uint){
      
      require (b >= a, "Sub Overflow!!!");
      
      uint c = a - b;

      return c;
  }

  function div (uint a, uint b) internal pure returns(uint) {
  	uint c = a/b;
  	
  	return c;
  }
  

}
	

