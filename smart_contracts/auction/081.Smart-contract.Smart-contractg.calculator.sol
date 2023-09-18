pragma solidity 0.6.0;

contract calculator{
   
     
     function add(int _a, int _b) public  pure returns(int){
          int c = _a + _b;
          require(c >= _a);
          return c;
          
         
     }
     
     function sub(int _a, int _b) public pure returns(int){
         
         require(_a >= _b, "overflow");
         int c = _a - _b;
         return c;
         
         }
         
     function multiply(int _a, int _b)public pure returns(int){
         
         if(_a == 0 || _b == 0){
             
             return 0;
         }
         
         int c = _a*_b;
         require(c/_a==_b);
         return c;
         
    }
    
    function division(int _a, int _b) public pure returns(int){
        
        require(_b > 0);
        int c = _a / _b;
        return c;
        
    }
    
    function mod(int _a, int _b) public pure returns(int){
        require(_b != 0);
        int c = _a % _b;
        return c;
    }
    
} 
