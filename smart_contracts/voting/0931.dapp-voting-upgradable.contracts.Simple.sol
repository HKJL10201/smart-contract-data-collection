// contracts/Simple.sol
pragma solidity >=0.4.20 <0.6.0;

contract Simple {

  struct Person{
    uint id;
    string name;
    bool _is;
  }

  mapping(uint => Person) public mapPerson;
  uint public Personlength;
  event LogaddPerson(string pname);
  event LoggetPersonById(uint pid);
  address public admin;

  function initialize() public {
    Personlength = 0;
    admin = msg.sender;
  }

  function addPerson( string memory pname) public {
    mapPerson[Personlength] = Person(Personlength, pname,true);
    Personlength += 1;
  }

  function getPersonById(uint pid) public view returns (string memory){
    require(mapPerson[pid]._is == true, "Person doesn’t exist");
    Person memory person = mapPerson[pid];
    return person.name;
  }

}