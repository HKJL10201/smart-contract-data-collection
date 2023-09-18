//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract MultiSigWallet {
    //Deposit will fire when ether is deposited to this multisigwallet
    //Submit will fire when a transaction is submitted waiting for the other owners to approve
    //Approve will fire when the transaction is approved.
    //Revoke will fire when owners change their mind and revoke approved transaction.
    //Execute will fire when there is sufficient amount approvals, then the contract(Does
    // "contract" mean "transaction"?) can be executed.
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId); //txId is the index where the transaction is stored.
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    //This struct will create transaction records. Then we will store these records in an array.
    struct Transaction {
        address to; // recipient of our transaction.
        uint value;
        bytes data; //data sent with the transaction.
        bool executed; //if transaction is successfull or not.
    }

    //Defining the array of owners. Only the owners will be able to call most of the 
    // functions above.
    address[] public owners;

    //If an address is owner of multisigwallet it will return true.
    mapping(address => bool) public isOwner;

    //number of approvals required to approve transaction.
    //For our exercise, we will assume 3 owners and 2 approvals will be required.
    uint public required;

    //Here will record transactions (in Transaction struct format).
    Transaction[] public transactions;

    //Here we will need to define a mapping to save approvals for each transaction.
    //uint is the index of the transaction. 
    mapping(uint => mapping(address => bool)) public approved;

    //Now we will create a constructor to define owners and number of required.
    //Then we will create a for loop to save each _owners array element to the owner array above.
    //Also we will save it to mapping above. Also we will check to make sure address(0) is not owner.
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length >= 1, "owners required");
        require(_required > 0 && _required <= _owners.length, "required number is wrong. either too small or too big");

        for(uint i=0; i<_owners.length; i++){
            address newOwner = _owners[i];
            require(newOwner != address(0), "not valid address"); //make sure addresses are valid
            require(!isOwner[newOwner], "this address already exists"); // make sure addresses are new
            isOwner[newOwner] = true; // save address to mapping
            owners.push(newOwner);  //save address to array
        }
        required = _required;
    }

    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
        //instead of mapping, we could also search msg.sender inside the owners array
        // but it is not gas efficient.. Thats why we are choosing mapping.
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner{
        Transaction memory newRecord = Transaction(_to, _value, _data, false);
        transactions.push(newRecord);
        emit Submit(transactions.length - 1); //txId is the index where the transaction is stored.
    }

    modifier txExists(uint txId) {
        require(txId <transactions.length, "transaction is not submitted yet");
        _;
    }
    modifier notApproved(uint txId) {
        require(!approved[txId][msg.sender], "transaction is not approved yet");
        _;
    }
    modifier notExecuted(uint txId) {
        require(transactions[txId].executed != true, "transaction is not submitted yet");
        _;
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] == true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns(uint) {
        uint count;
        for(uint i=0; i<owners.length; i++){
            if(approved[_txId][owners[i]] == true) {
                count +=1;
            }
        }
        return count;
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId){
        uint countNumber = _getApprovalCount(_txId);
        require(countNumber >= required, "execution failed because not enough approvals");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "failed to execute");
        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        require(approved[_txId][msg.sender] == true, "you have not approved yet to ");
        approved[_txId][msg.sender] == false;
        emit Revoke(msg.sender, _txId);
    }


}