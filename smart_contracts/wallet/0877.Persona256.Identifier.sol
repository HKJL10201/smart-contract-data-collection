// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "hardhat/console.sol";

contract Identifier {

///EVERYTHING SENT FROM JS MUST BE ENCRYPTED. THERE'S NO PRIVATE INFO ON THE BLOCKCHAIN
///THERE MUST BE A FUNCTION TO DECRYPT ON THE CLIENT-SIDE

///Constructor
    constructor (address _initializer, string memory _password, uint _pin) {
        initializer = _initializer;
        password = _password;
        passwordHash = keccak256(abi.encodePacked(password));
        pin = _pin;
    }

////needs to be deleted before deployment
    function check() public view returns (address, string memory, bytes32, uint) {
        return (initializer, password, passwordHash, pin);
    }

///Structs
    struct Persona {
        address wallet;
        bytes32 IDHash;
        uint256 timesAccessed;
        string fname;
        string lname;
        string sex;
        string dob;
        string issued;
        bool permissionToModify;
        bool activation;
    }

///Mappings
    mapping (address => Persona) public persona;
///The key is address because the address is harder to attain. 
///Secondary security checks come from the hash.

///Events
    event Clear(string __message);
    event Create(bytes32 __identificationHash);
    event Deactivate(string __message);
    event Grant(string __message);
    event Modify(string __message);
    event Read(
        address __persona, bytes32 __identificationHash, uint256 __timesAccessed, string __sex, string __issued,
        string __dob, string __fname, string __lname
        ); 
    event Rescind(string __message);

///Variables
    address internal initializer;
    string internal password;
    bytes32 passwordHash;
    uint pin;

    address public operator;
    uint256 public timesUtilized;
    bytes32 public previousHash;

///Functions
///Creating a Persona:
    function createPersona(
        string memory _fname, string memory _lname,
        string memory _sex, string memory _dob,
        string memory _issued
    ) public {

        ///Set Operator
        operator = msg.sender;

        ///Check to make sure operator doesn't already have a Persona.
        require(persona[operator].wallet == address(0x0), "This address has a persona attached to it already. You may not make another." );

        ///Unique ID
        timesUtilized ++;

        ///Create IDHash
        bytes32 currentHash = keccak256(abi.encodePacked(
            _sex, _issued, _dob, _fname, _lname, operator, timesUtilized, previousHash
            ));
        previousHash = currentHash;

        ///Apply specifics to persona
        persona[operator] = Persona(
            operator, currentHash, 1, _fname, _lname, _sex,
            _dob, _issued, false, true
        );

        ///return IDHash
        emit Create(persona[operator].IDHash);
        
    }

    function readPersona(
        address _belongsTo, bytes32 _IDHash
    ) public {
        ///Signifying operator
        operator = _belongsTo;

        ///Primary security check with _belongsTo
        require( persona[operator].wallet != address(0x0) , "This is not a Persona that exists.");

        ///Secondary security check with _IDHash
        require( persona[operator].IDHash == _IDHash, "This is the incorrect IDHash.");

        ///Tertiary security check requiring activation
        require( persona[operator].activation == true, "This Persona has been deactivated. This usually happens for security reasons. Contact Persona256 support to learn more.");

        ///Update timesAccessed & timesUtilized
        persona[operator].timesAccessed ++;
        timesUtilized ++;

        emit Read(persona[operator].wallet, persona[operator].IDHash, persona[operator].timesAccessed, persona[operator].sex, persona[operator].issued, persona[operator].dob, persona[operator].fname, persona[operator].lname);

    }

    function modifyPersona(
        bytes32 _IDHash, string memory _fname, string memory _lname,
        string memory _sex, string memory _dob
    ) public {
        ///Signifying operator
        operator = msg.sender;

        ///Primary security check with _belongsTo
        require( persona[operator].wallet != address(0x0) , "This is not a Persona that exists.");

        ///Secondary security check with _IDHash
        require( persona[operator].IDHash == _IDHash, "This is the incorrect IDHash.");

        ///Tertiary security check requiring activation
        require( persona[operator].activation == true, "This Persona has been deactivated. This usually happens for security reasons. Contact Persona256 support to learn more.");

        ///Quaternary security check requiring permission to modify
        require( persona[operator].permissionToModify == true, "To modify a Persona, You must be given permission by an administrator. This is for security reasons. You may be required to prove that this information has actually changed.");

        ///Update timesAccessed & timesUtilized
        persona[operator].timesAccessed ++;
        timesUtilized ++;

        ///Check for Modifications
        ///Permission to modify set back to false
        persona[operator] = Persona(
            operator, _IDHash, persona[operator].timesAccessed,
            _fname, _lname, _sex, _dob, persona[operator].issued,
            false, true
        );



        emit Modify("Info successfully updated!");

    }

    ///Administrator Functions

    function grantPermission(
        bytes32 _potentialPasswordHash, uint _potentialPin, address _persona
    ) public {
        require (msg.sender == initializer, "You are not the administrator of this contract.");
        require (_potentialPasswordHash == passwordHash, "Password Hash is incorrect.");
        require (_potentialPin == pin, "Pin is incorrect.");
        persona[_persona].permissionToModify = true;
        timesUtilized ++;
        emit Grant("Permission Granted to Persona!");
    }

    function rescindPermission(
        bytes32 _potentialPasswordHash, uint _potentialPin, address _persona
    ) public {
        require (msg.sender == initializer, "You are not the administrator of this contract.");
        require (_potentialPasswordHash == passwordHash, "Password Hash is incorrect.");
        require (_potentialPin == pin, "Pin is incorrect.");
        persona[_persona].permissionToModify = false;
        timesUtilized ++;
        emit Rescind("Permission rescinded from Persona!");

    }

    function deactivatePersona(
        bytes32 _potentialPasswordHash, uint _potentialPin, address _persona
    ) public {
        require (msg.sender == initializer, "You are not the administrator of this contract.");
        require (_potentialPasswordHash == passwordHash, "Password Hash is incorrect.");
        require (_potentialPin == pin, "Pin is incorrect.");
        persona[_persona].activation = false;
        emit Deactivate("Persona Deactivated! This is reversible");
    }

    function clearPersona(
        bytes32 _potentialPasswordHash, uint _potentialPin, address _persona
    ) public {
        require (msg.sender == initializer, "You are not the administrator of this contract.");
        require (_potentialPasswordHash == passwordHash, "Password Hash is incorrect.");
        require (_potentialPin == pin, "Pin is incorrect.");
        persona[_persona] = Persona(
            address(0x0), bytes32(0x0), 0,
            "", "", "", "", "",
            false, false);
        timesUtilized ++;
        emit Clear("Persona Cleared! This is irreversible");

            }



}
