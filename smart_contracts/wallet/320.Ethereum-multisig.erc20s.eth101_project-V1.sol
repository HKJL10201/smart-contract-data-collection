pragma solidity 0.7.5;
pragma abicoder v2;

contract MULTISIG{
    
    // n_approvals
    uint Napproval = 2;
    
    // store clients in a mapping, where every element of the map is a struct
    mapping (address => Cli) Client;
    struct Cli{
        bool isOwner;
        uint funds;
        address adrs;
    }
    
    // transfers history struct
    struct TransfersHist{
        address sender;
        address recipient;
        uint amount;
        uint n_approvals;
    }
    
    TransfersHist[] transfers_hist;
    
    
    // contract creator
    address public contract_creator;
    
    modifier only_contract_creator{
        require(msg.sender == contract_creator);
        _;
    }
    // n_approvals needed
    constructor() {
        contract_creator = msg.sender;
        Client[contract_creator] = Cli(true, Client[contract_creator].funds, contract_creator);  // contract_creator is by default a validator
    }
    
    
    // emit logs
    event add_funds_log(address deposit_address, uint amount_added, uint current_balance);
    event client_added_log(address client_address, bool is_client_validator);
    
    
    // add funds function, anyone can add funds
    function addFunds() public payable returns(uint){
        
        Client[msg.sender].funds += msg.value;
        emit add_funds_log(msg.sender, msg.value, Client[msg.sender].funds);
        return Client[msg.sender].funds;
    }
    
    // only contract_creator can add clients and their validator status
    function addClient(bool _isValidator, address add_address) public only_contract_creator{
        
        Cli memory new_client = Cli(_isValidator, Client[add_address].funds, add_address);
        Client[add_address] = new_client;
        emit client_added_log(add_address, _isValidator);
    }
    
    
    // get client 
    function getClient() public view returns(Cli memory){
        return Client[msg.sender];
    }
    
    
    // transfer function
    function transact(address _from, address _to, uint _amount) private {
        Client[_from].funds -= _amount;
        Client[_to].funds += _amount;
    }
    
    function transfer(address _from, address _to, uint _amount) public {
       // uint memory napp = 0;
        
        //for (int i=0, i=Client)
        
        //transfers_hist[transfers_hist.length].push(_from, _to, _amount, napp)
    }
    
    function get_l() public view returns(uint){
        Client.length
    }

}
