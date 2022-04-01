pragma solidity ^0.4.24;

contract Passport {
   // Model a voter
    struct Voter {
        address uid;
        string fName;
        string lName;
        uint   age;
    }

    // Store voters
    mapping(address => Voter) public voters;
    // Store voters Count
    uint public votersCount;

    constructor () public {
        register("Sara", "Cohneour", 42);
    }

    function voterIsRegistered (address voterAddress) public view returns (bool) {
        return voters[voterAddress].age != 0;
    }

    function register (string _fName, string _lName, uint _age) public {
        // require that they haven't been registered before
        require(voters[msg.sender].age == 0);
        // require a valid candidate
        require(_age >= 18, "Voter must be at least 18 years old");
        // record that voter was registered
        voters[msg.sender] = Voter(msg.sender, _fName, _lName, _age);
        votersCount ++;
    }
}