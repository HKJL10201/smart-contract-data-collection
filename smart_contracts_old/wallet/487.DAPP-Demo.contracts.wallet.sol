pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

contract Wallet {

    struct User {
        uint id;
        string name;
        uint balance;
    }

    address[] public addressList;
    uint public numberOfUser;
    mapping (address => User) public Users;
    User[] public userStructList;
    bytes32[]  public userBytes32List;



    constructor () public {
        numberOfUser = 0;
    }

    modifier isAccountExist( address _recieverAddress ,  address _senderAaddress){
        uint count = 0;
        for (var index = 0; index < addressList.length; index++) {
            if(_recieverAddress  ==  addressList[index]) {
                count++;
            }
        }
        require(count > 0, "address invalid");
        _;
    }

     modifier isRecieverSameAsSender( address _recieverAddress ,  address _senderAaddress){

        require(_recieverAddress != _senderAaddress);
        _;
    }

    function getUser(address _address) public view returns (string) {
        return Users[_address].name;
    }

    function addUser(address _address, string _name, uint _amount) public {
        numberOfUser++;
        Users[_address] = User(numberOfUser, _name, _amount);
        userStructList.push(Users[_address]);
        addressList.push(_address);
    }

    function getAllUserData(address _address) public returns (string, uint) {
        return (Users[_address].name, Users[_address].balance);
    }

    function payAmount(

            address _recieverAddress,
            address _senderAddress,
            uint _amount
        ) isAccountExist(_recieverAddress ,_senderAddress ) public returns (string)
        {


            if(Users[_senderAddress].balance >= _amount){
                // get the sender user data

                User storage SenderUser = Users[_senderAddress];
                // reduced the balance

                SenderUser.balance = SenderUser.balance-_amount;
                // get the reciever user data

                User storage RecieverUser = Users[_recieverAddress];
                // increasse the balance

                RecieverUser.balance = RecieverUser.balance + _amount;

                return "success";

                }else{
                    return "insufficient Amount";
                }
    }

    function getStructListUser() public view returns (User[]) {
        return userStructList;
    }





}