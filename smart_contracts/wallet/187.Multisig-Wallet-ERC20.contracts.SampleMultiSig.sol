pragma solidity >=0.4.0 <0.6.0;

contract SampleMultiSig {
    
    /* Event */
    
    
    /* Storage */
    mapping (address => bool) isOwner;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping(address => bool)) public confirmations;
    address[] owners;
    uint public required;
    uint private transactionCount;
    
    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    
    
    /* Modifier */
    modifier validRequirement(uint ownerCount, uint _required) {
        require(
            ownerCount >= _required && _required > 0 && ownerCount > 0,
            "Requirement Not Valid"
        );
        _;
    }
    
    modifier notNull(address _recipient) {
        require(_recipient != address(0x0), "Invalid Address");
        _;
    }
    
    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner Doesn't Exist");
        _;
    }
    
    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0x0), "Invalid destination Address Type");
        _;
    }
    
    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], "Transaction Confirmed");
        _;
    }
    
    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner],  "Transaction not Confirmed");
        _;
    }
    
    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "Transaction Executed");
        _;
    }
    
    
    /* Constructor */
    constructor (address[] memory _owners, uint _required) 
        public
        validRequirement(_owners.length, _required) 
    {
        for(uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0x0), "Invalid owner address");
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }
    
    
    /* Fallback */
    function () payable external {
        require(msg.value > 0, "Sent Value should be greater than 0");
    }
    
    
    /* Externalc Function */
    
    
    /* Public Function */
    function submitTransaction (address destination, uint value, bytes memory data) 
        public 
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction (transactionId);
    }
    
    function confirmTransaction (uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        executeTransaction(transactionId);
    }
    
    
    /* Internal Function */
    function addTransaction (address destination, uint value, bytes memory data) 
        internal 
        notNull(destination)
        returns(uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
    }
    
    function executeTransaction (uint transactionId)
        internal
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data)){
                
            } else {
                txn.executed = false;
            }
        }
    }
    
    function isConfirmed(uint transactionId)
        internal
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }
    
    
    /* Private Function */
    function external_call(address destination, uint value, uint dataLength, bytes memory data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) 
            let d := add(data, 32)
            result := call(
                sub(gas, 34710), 
                destination,
                value,
                d,
                dataLength, 
                x,
                0 
            )
        }
        return result;
    }
}