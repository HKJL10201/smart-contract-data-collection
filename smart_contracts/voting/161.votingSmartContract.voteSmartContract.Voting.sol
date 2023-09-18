// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract sevenbits{

    string public question;
    string public option1;
    string public option2;
   
    uint option1vote= 0;
    uint option2vote= 0;

     
    
    function startquiz(string memory _question, string memory _option1, string memory _option2)public{
                question=_question;
                option1=_option1;
                option2=_option2;
    }
        function voteOption1()public returns(uint){
            return option1vote= option1vote+1;
        }

          function voteOption2()public returns(uint){
            return option2vote= option2vote+1;
        }
    function result() public view returns(string memory){

         
         string memory str;

         if(option1vote>option2vote){
          
             str = "option 1 won";
         }
         else if(option1vote<option2vote){
             
             str="option 2 won";
         }
         else{
             str="invalid, please vote";
         }
        
         return str;
    }

   
        
}