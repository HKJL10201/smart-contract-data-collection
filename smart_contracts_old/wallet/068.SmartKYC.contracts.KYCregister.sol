pragma solidity ^0.4.2;

contract KYCregister {

 struct UserDetails {

    address UserID;
    bytes32 UserEmail;
    bytes32 UserFirstName;
    bytes32 UserMiddleName;
    bytes32 UserLastName;
    bytes32 password;
    bytes32 dob;
    bytes32 gender;
    bytes32 country;
    uint aadhar;

    }

    address userid1;
    mapping (address => UserDetails) public user;


function RegisterUserDetails(address userid, bytes32 email, bytes32 firstname, bytes32 middlename, bytes32 lastname, bytes32 password, bytes32 dob, bytes32 gender, bytes32 country, uint aadhar)
{
      userid1 = userid;
      
      user[userid1] = UserDetails(userid,email,firstname,middlename,lastname,password,dob,gender,country,aadhar);
         
}


function getUserDetails(address id1) constant returns(address,bytes32,bytes32,bytes32,bytes32) {
        
         UserDetails ud1 = user[id1];
         

         return(ud1.UserID,ud1.UserEmail,ud1.UserFirstName,ud1.UserLastName,ud1.password);
    
    }
 
}