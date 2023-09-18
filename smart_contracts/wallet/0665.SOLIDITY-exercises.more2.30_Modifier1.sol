pragma solidity >=0.8.7;

contract Modifier {

    address myAccount;
    string private surname;

    //constructor sets the creator of the contract to the owner variable
    constructor() {
        myAccount = msg.sender;
    }
    
    //modifier checks that the caller of the function is the owner
    modifier onlyOwner() {
        require(msg.sender == myAccount, "You are not owner");
        _;
    }

    //set name.  Only the owner of the contract can call because a modifier is specified
    function setSurname(string memory newSurname) public onlyOwner{
        surname = newSurname;
    } 

    // get the name
    function getName() public view returns (string memory) {
        return surname;
    }

}

