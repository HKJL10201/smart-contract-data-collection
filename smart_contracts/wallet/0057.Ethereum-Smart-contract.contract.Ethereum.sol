// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;


//
contract ENS {
    event NewUser(string _username, address walletAddress);

    event Sent_Eth(address sender, address receiever, uint256 amount);

    // Mapping system that connects name to address
    mapping(string => address) user;

    // A variable to check if the address has a name based of the state of its boolen
    mapping(address => bool) public wallet_Address;

    // A variable to store a 5 digit minified address as we will use it to protect against errors that can be generated from capitalization as James and james are two different things entirely
    mapping(uint => address) minified_Address;

    //We will be using this variable to store the amount of digit we will be using for minified address and since it is a constant we store it directly with 5
     uint hashdigit = 5;

     //Modulus variable to make it 10 ^ 8

    uint hashModulus = 10 ** hashdigit;

    /**
        @dev allows unregistered users to create a profile with a username
        @param _username username of user
     */


    // This is three step process where you would sumbit username, use the same name to get a uniue digit code and also verify your digit code/ unique id
    function  submitUsername(string memory _username) public returns(uint) {
         require(bytes(_username).length > 0, "Empty username");
         require(
            wallet_Address[msg.sender] == false,
            "This user has already been registered"
        );
        //packing strings to byte 
         uint pack_string = uint(keccak256(abi.encodePacked(_username)));   
         uint min_Digits = pack_string % hashModulus;  
          // This check was put in place to prevent users from picking a username that is already in use
        require(
            minified_Address[min_Digits] == address(0),
            "This Minified digit is already taken"
        ); 
         minified_Address[min_Digits] = msg.sender; 
         wallet_Address[msg.sender] = true;
         return min_Digits;
    }


    // Input the name to obtain your unique ID 

    function getDigitCode(string memory _username) public view returns (uint){

       uint pack_string = uint(keccak256(abi.encodePacked(_username)));

         uint min_Digits = pack_string % hashModulus;

        return min_Digits;
    }


    // Verification to make sure that the unique code is rightly associated with the correct address

    function verifyDigitCodeAddress(uint _digits) public view returns (address){
       return minified_Address[_digits];
    }

    /**
     *  @dev allow users to transfer funds to another user by using their address
     * @param _myUniqueCode username of the user
     */
    function sendEth(uint _myUniqueCode) public payable {
        address receiverAddress = verifyDigitCodeAddress(_myUniqueCode);
        require(receiverAddress != address(0), "Query of nonexistent user");
        (bool sent, ) = payable(receiverAddress).call{value: msg.value}("");
        require(sent, "Failed Transaction");
        emit Sent_Eth(msg.sender, receiverAddress, msg.value);
    }
}
