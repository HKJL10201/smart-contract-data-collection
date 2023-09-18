// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage{
      uint number;
      function getNumber() internal view returns(uint){
            return number;
      } 

      function setNumber(uint _number) internal{
            number=_number;
      }
      
}














// How to call the function internally

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// contract Storage{
//       uint number;
//       function getNumber() internal view returns(uint){
//             return number;
//       } 

//       function setNumber(uint _number) internal returns(uint){
//            return number=_number;
//       }

//       function callinginternal() public view returns(uint){
//             return getNumber();
//       } 
      
//       function settingthenumberandgivingnewvalue(uint _n) public returns(uint){
//             return setNumber(_n);
//       }
// }