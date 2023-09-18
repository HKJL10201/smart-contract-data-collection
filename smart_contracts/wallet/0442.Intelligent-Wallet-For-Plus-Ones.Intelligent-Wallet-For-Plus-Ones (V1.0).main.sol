pragma solidity ^0.5.17;

contract sharedWallet {

    address private_owner;

    // Create a mapping so other addresses can interact with this wallet. Uint8 us used to determine if the address is enabled or disabled
    mapping(address => uint8) private_owners;

    // In order to interact with the wallet you need to be the owner so I added a required statemenet to then execute the function _;
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    // Require the msg.sender/the owner OR || Or an owner with a 1 which means enabled owner 
    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }

    event DespitFunds(address from, uint amount);
    event WithdrawFunds(address from, uint amount);
    event TransferFunds(address from, address to, uint amount);

    // The following function is used to add owners of the wallet. Only the isOwner can add addresses. 1 means enabled 
    function addOwner(address owner)
        isOwner
        public {
        _owners[owner] =  0;
    }

    // Remove an owner from the wallet. 0 means disabled
    function removeOwner(address owner)
        isOwner
        public {
        _owners[owners] = 0;
    }
    
    // Anyone can deposit funds into the wallet and emit an event known as depositdunds
    function ()
        external
        payable {
        emit DepositFunds(msg.sender, msg.value);
    }
    
    // To withdraw you need to be an owner, the amount needs to be >= balance of account. THen transfer and emit and event
    function withdraw (unit amount)
        validOwner
        public {
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
        emit WithdrawFunds(msg.sender, amount);
    }

    function transferTo(address payable to, unit amount)
        validOwner
        public {
        require(address(this).balance >= amount);
        to.transfer(amount);
        emit TransferFunds(msg.sender, to, amount);
    }
}