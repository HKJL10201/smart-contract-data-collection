pragma solidity 0.7.5;
pragma abicoder v2;

contract MULTISIG{
    
    // n_approvals
    uint Napproval = 2;
    address[] Validators;  // all validator (aprovers) addresses are appended here
    
    // store Client in a mapping, where every element of the map is a struct
    mapping (address => Cli) Client;
    struct Cli{
        bool isOwner;
        uint funds;
        address adrs;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    }
    
    // transfers history struct
    struct TransfersHist{
        uint id;
        address payer;
        address recipient;
        uint amount;
        uint n_approvals;       // number of approvals out of Napproval=2 (defined at the top)
        bool already_approved;  // if the transaction already went through this will be true
    }
    
    TransfersHist[] transfers_hist;  // transfers_hist is a vector which elements are structs
    
    // approvals mapping, approvals[id]["address"] = 0|1
    mapping (address => mapping (uint => uint)) approvals;
    
    // contract creator
    address contract_creator;
    
    modifier only_contract_creator{
        require(msg.sender == contract_creator);
        _;
    }
    // n_approvals needed
    constructor() {
        contract_creator = msg.sender;
        Client[contract_creator] = Cli(true, Client[contract_creator].funds, contract_creator);  // contract_creator is by default a validator
        Validators.push(contract_creator);                                                       // contract creator is by default validator
    }
    
    
    // create logs
    event add_funds_log(address deposit_address, uint amount_added, uint current_balance);
    event client_added_log(address client_address, bool is_client_validator);
    event succesfull_transfer_log(uint transaction_id, address sender_address, address recipient_address, uint amount_transfered);
    
    
    // add funds function, anyone can add funds
    function addFunds() public payable returns(uint){
        Client[msg.sender].funds += msg.value;
        emit add_funds_log(msg.sender, msg.value, Client[msg.sender].funds);
        return Client[msg.sender].funds;
    }
    
    // Add clients and their validator status
    function addClient(bool _isValidator, address add_address) public {
        Cli memory new_client = Cli(_isValidator, Client[add_address].funds, add_address);
        Client[add_address] = new_client;
        emit client_added_log(add_address, _isValidator);
        
        if (Client[add_address].isOwner == true){  // if client is set as validartor, they are appended to the validators list
            Validators.push(add_address);
        }
    }
    
    
    // get client 
    function getClient() public view returns(Cli memory){
        return Client[msg.sender];
    }
    
    // get Validators
    function getValidators() public view returns(address[] memory){
        return (Validators);
    }
    
    
    // transact function moves money from one account to another
    function transact_proceed(address _from, address _to, uint _amount) private {
        Client[_from].funds -= _amount;
        Client[_to].funds += _amount;
    }
    
    // Aprove transaction function
    function Aprove(uint _transaction_ID) public {
        require(Client[msg.sender].isOwner == true);
        TransfersHist storage current_transaction = transfers_hist[_transaction_ID]; // refer to the element of the array, each element is a struct
        require(current_transaction.already_approved == false, "The transaction already went through");
        
        // check that addresses have not approved a transacition
        require(approvals[msg.sender][_transaction_ID] == 0, "This address has already approved the transaction");
        
        current_transaction.n_approvals += 1;         // add +1 to the count of number of approvals
        approvals[msg.sender][_transaction_ID] = 1;   // change the state of the approvals mapping
        
        // check if the number of approvals meet Napp=2, if so proceed with the transaction
        if (current_transaction.n_approvals >= Napproval){
            transact_proceed(current_transaction.payer, current_transaction.recipient, current_transaction.amount);  // call fucntion transact
            current_transaction.already_approved = true;                                                             // change transaction status
            emit succesfull_transfer_log(_transaction_ID, current_transaction.payer, current_transaction.recipient, current_transaction.amount);
        }
    }
    
    // post transaction into transfers_hist vector, this then is proceeded once the number of approvals is >= 2
    function transact(address _from, address _to, uint _amount) public {
       require(Client[_from].funds >= _amount, "Not enough balance in account");
       require(_from != _to, "Can't auto-deposit");
       
       uint n0 = 0;
       transfers_hist.push(TransfersHist(transfers_hist.length, _from, _to, _amount, n0, false));  // add an element to transaction history array
       
    }
    
    
       
    function getTranscactionHist() public view returns(TransfersHist[] memory){
        return transfers_hist;
    }
}


