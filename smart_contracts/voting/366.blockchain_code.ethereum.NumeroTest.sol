pragma solidity 0.5.2;

/**
 * The Ownable contract does this and that...
 */
contract Ownable {
	address payable public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() { 
   	require (msg.sender == owner, "Vc não é o dono"); 
   	_; 
   }

}

contract NumeroTest is Ownable {
  using safeMath for uint;

 
  uint balance;
  uint duplica = 1;
  uint price = 25000000000000000;

  event newPriceNumber(uint newPrice);



   function sayNumber(uint8 a) payable public returns(string memory) {
   	uint newPrice = price.mul(duplica);
   	require (msg.value == newPrice , "Insuficiente Fundos!!!");

   	require (a <= 10, "Número escolhido precisa ser entre 0 e 10");
   	
   	balance = balance.sum(msg.value);
   	duplica = duplica.sum(1);
	emit newPriceNumber(newPrice);
		if(a > 5){
			return "É maior que cinto!!!";
	   	}else{
	   		return "É menor ou igual a cinco!!!";
	   	}
   	
   }
   
   function withDraw (uint quantidade) onlyOwner payable public {
   	require (balance > 0 , "Saldo Insuficiente");
   	require (balance >= quantidade, "Insuficiente Fundos para saque!!!");

   	uint saldo = balance.sub(quantidade);
   	balance = saldo;
   	msg.sender.transfer(quantidade);

   }
   

}

/**
 * The safeMath library does this and that...
 */
library safeMath {
  function sum(uint a, uint b) internal pure returns(uint) {
  	uint c = a + b;

  	require (c >= a, "Sum Overflow!!!");
  	
  	return c;
  }

  	function sub(uint a, uint b) internal pure returns(uint){
      
      require (b <= a, "Sub Overflow!!!");
      
      uint c = a - b;

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
  	
}



	
