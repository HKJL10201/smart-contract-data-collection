
pragma solidity 0.5.0;
 
import "token2.sol";

contract crowdsale{
    
     Token public mytoken; // token being sold
     
      address payable public wallet;  // whre funds are located;
      
      uint public rate; // how many token unit a buyer gets per wei
      uint public weiraised; // amount of weiraised
      
       event token_purchased(address indexed purchaser, address indexed benefeciary, uint value, uint amount);
       
       constructor(uint _rate, address payable _wallet, Token  _token) public{
         require(_rate > 0);
         require(_wallet != address(0));
       //  require(_token != address(0));
          rate = _rate;
          wallet = _wallet;
          mytoken = _token;
         
       }
       function buytokens(address _beneficiary) public payable{
            uint wei_amount = msg.value;
            _prevalidate_purchase(_beneficiary, wei_amount);
            
            // calculate Token amount to be created 
            
            uint tokens = _gettokenamount(wei_amount);
            
            // update state;
            
            weiraised = weiraised + wei_amount;
            
            _processpurchase(_beneficiary, tokens);
            emit token_purchased(msg.sender, _beneficiary, wei_amount, tokens);
            _forwardfunds();
            
       }
       
       function () external payable{
           buytokens(msg.sender);
       }
       
       function _prevalidate_purchase(address _beneficiary, uint wei_amount) internal  {
           require(_beneficiary != address(0));
           require(wei_amount != 0);
       }
       
       
       function _delivertokens(address _beneficiary, uint _tokenamount) internal{
           mytoken.transfer(_beneficiary, _tokenamount);
       }
       
       function  _processpurchase(address _beneficiary, uint _tokenamount) internal{
           _delivertokens(_beneficiary, _tokenamount);
       }
       
       
       
       
       function _gettokenamount(uint wei_amount) internal view returns(uint){
           return wei_amount * rate;
       }
       
       function _forwardfunds() internal {
           
            
            wallet.transfer(msg.value);
           
       }
       
       
}