pragma solidity ^0.8.1;

contract passManager {


    // mapping which holds the callers address
    // nested mapping holds the website name is the key and the username/password as the value
    mapping(address => mapping(string =>Credintials)) credMap;

    // object to hold the username and password
    struct Credintials{
        string username;
        string password;
    }

    // adds credintials to the mappings
 function addCredentials(string memory _website, string memory _username, string memory _password) public {
        
        // IF SENDER IS THE OWNER
        //require(msg.sender == owner, 'you are not the owner');

        // ADDS CREDENTIALS TO WEBSITE NAME WHICH IS ADDED TO KEY OF USERS WALLET
        credMap[msg.sender][_website] = Credintials(_username, _password);
 }

 function returnCredentials(string memory _websiteName) public view returns(Credintials memory){
     return credMap[msg.sender][_websiteName];
 }




}
