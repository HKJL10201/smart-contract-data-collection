pragma solidity 0.8.14;

contract EthEscrow {
    mapping(uint => address) escrow;
    mapping(uint => address payable) payer;
    mapping(uint => address payable) recipient;
    mapping(uint => uint) amount;
    mapping(uint => uint) balance;
    mapping(uint => bool) escrowFinished;

    uint iterator;

    constructor() {
        iterator = 0;
    }

    function createEscrowTrade(address _escrow, address payable _payer, address payable _recipient, uint _amount) public returns (uint){
        escrow[iterator] = _escrow;
        payer[iterator] = _payer;
        recipient[iterator] = _recipient;
        amount[iterator] = _amount;
        escrowFinished[iterator] = false;

        iterator++;
        return iterator - 1;
    }
    
    //deposit
    function deposit(uint _id) public payable {
        require(msg.sender == payer[_id], "only payer address can deposit");

        balance[_id] == msg.value;
    }

    //withdraw
    function withdraw(uint _id) public {
        require(msg.sender == escrow[_id], "only authorised escrow address can call withdraw");
        require(balance[_id] >= amount[_id], "more funds need to be deposited");

        balance[_id] -= amount[_id];
        recipient[_id].transfer(amount[_id]);

        if (balance[_id] != 0) {
            uint leftOverEth = balance[_id];
            balance[_id] = 0;
            payer[_id].transfer(leftOverEth);
        }

        escrowFinished[_id] = true;
    }

    function getEscrowInfo(uint _id) public view returns(address, address, address, uint, uint, bool) {
        return (escrow[_id], payer[_id], recipient[_id], amount[_id], balance[_id], escrowFinished[_id]);
    }
    
}