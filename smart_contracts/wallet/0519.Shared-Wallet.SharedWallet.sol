// SPDX-License-Identifier:GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

/*
This contract is a shared wallet in which anyone can become user.
Then owner will verify the user. And after that, a verified user
will be able to deposit, withdraw, transfer and check Balance.
Owner can check the contract's balance.
*/

contract sharedWallet
{
    /*
    State variables for owner address and user count;
    */
    address public owner;
    uint public userCount;
    

    /*
    Constructor to make deployer the of the contract the owner.
    */
    constructor()
    {
        owner = msg.sender;
    }



    /*
    Modifier to restrict some functions access to owner only.
    */
    modifier onlyOwner()
    {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    
    /*
    Events for create or update funcion.
    */
    event created(address user, string name, uint cnic, uint balance, bool status, uint timeStamp, string action);
    event updated(address user, string name, uint cnic, uint timeStamp, string action);

    
    /*
    Struct for user to store user's data.
    */
    struct user
    {
        address Address;
        string Name;
        uint CNIC;
        uint balance;
        bool status;
        uint flag;
    }

    
    /*
    Mapping to map users's address to its struct.
    */
    mapping(address => user) private users;

    
    /*
    Function to create or update user.
    Owner of the contrcat can not access this function.
    If user is not created previously then if statement will run and new user will be created
    Otherwise else statement will run and user will be updated.
    */
    function createOrUpateUser(string memory _name, uint _cnic) public
    {
        require(msg.sender != owner, "You are the owner and owner can not be the user");
        if (users[msg.sender].flag == 0)
        {
            users[msg.sender] = user(msg.sender, _name, _cnic, 0, false, 1);
            userCount ++;
            emit created(msg.sender, _name, _cnic, 0, false, block.timestamp, "User created successfully");
        }

        else
        {
            users[msg.sender].Name = _name;
            users[msg.sender].CNIC = _cnic;
            emit updated(msg.sender, _name, _cnic, block.timestamp, "User updated successfully");
        }
    }

    
    /*
    Function to verify user.
    Only owner can call this functiion.
    */
    function verifyUser(address userAddress, bool _status) public onlyOwner
    {
        users[userAddress].status = _status;
    }

    
    /*
    Function to deposit Ethers in respective account.
    An unregistered and non-verified user can not call this function.
    */
    function depositEthers() public payable
    {
        require(users[msg.sender].flag != 0, "You are not a registered user, get yourself registered first");
        require(users[msg.sender].status, "You are not a verified user, please get yourself verified first");
        require(msg.value > 0, "No Ethers was sent, Please send Ethers");
        users[msg.sender].balance += msg.value;
    }

    
    
    /*
    Function to withdraw Ethers from respective account.
    An unregistered and non-verified user can not call this function.
    ///////////////////////////////////////////////////////////////////////////////////
    I used the Checks-Effects-Interact pattern to reduce the risk of Reentrancy attack.
    ///////////////////////////////////////////////////////////////////////////////////
    */function withdraw(uint _amount) public
    {
        require(users[msg.sender].flag != 0, "You are not a registered user, get yourself registered first");
        require(users[msg.sender].status, "You are not a verified user, please get yourself verified first");
        require(users[msg.sender].balance >= _amount, "Not enough balance");

        users[msg.sender].balance -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    
    /*
    Function to transfer funds to a specified adddres.
    An unregistered and non-verified user can not call this function.
    */
    function transferFunds(address _address, uint _amount) public
    {
        require(users[msg.sender].flag != 0, "You are not a registered user, get yourself registered first");
        require(users[msg.sender].status, "You are not a verified user, please get yourself verified first");
        require(users[msg.sender].balance >= _amount, "Not enough balance");

        users[msg.sender].balance -= _amount;
        payable(_address).transfer(_amount);        
    }

    
    
    /*
    Function to check balance of the caller's account.
    An unregistered and non-verified user can not call this function.
    */
    function checkBalance() public view returns(uint)
    {
        require(users[msg.sender].flag != 0, "You are not a registered user, get yourself registered first");
        require(users[msg.sender].status, "You are not a verified user, please get yourself verified first");
        return users[msg.sender].balance;
    }

    
    
    /*
    Function to check balance of contract.
    Only owner can call this function.
    ////////////////////////////////////////////////////////////////
    Sum of all users balances should be equal to contract's balance.
    ////////////////////////////////////////////////////////////////
    */
    function getContractBalance() public view onlyOwner returns(uint)
    {
        return address(this).balance;
    }
}
