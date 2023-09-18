pragma solidity ^0.4.17;
contract Prime
{
    uint public number;
    string public isprime;
    uint public f;
    function setvalue(uint a)public
    {
        number = a;
        if(number>2)
        {
            
            for(uint i=2;i<number;i++)
            {
                
                if(number%i == 0)
               
                {
                    f=i;
                    
                    isprime="it is not a prime number";
                    break;
                   
                  
                }
                else
                {
                    f=i;
                    isprime="it is the prime number";
                    
                }
            }
        }
        else
        {
            if(number == 0)
            {
                isprime ="the number should greater than 1";
            }
            else if(number ==1)
            {
                isprime="it is nor prime or composite";
            }
            else if(number ==2)
            {
                isprime="it is not a prime number";
            }
        }
    }
    function getvalue()constant public returns(uint)
    {
        return number;
    }
    
}