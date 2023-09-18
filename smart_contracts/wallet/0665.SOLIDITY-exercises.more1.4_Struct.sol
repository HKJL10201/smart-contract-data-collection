pragma solidity ^0.8.7;

contract PersonDetails {
   struct Person { 
      string name;
      uint age;
   }
   Person newPerson;

   function setPerson() public {
      newPerson = Person('Harro', 34);
   }
   function getPersonName() public view returns (string memory) {
      return newPerson.name;
   }
   function getPersonAge() public view returns(uint) {
       return newPerson.age;
   }
   function getPerson() external view returns(Person memory){
      return newPerson;
   }
   
}