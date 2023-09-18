contract CowdSource {
    
    Trader[] traders;
    Investor[] investors;
    Txn[] txns;
    mapping (address => Trader) traders_addr;
    mapping (address => Investor) investors_addr;
    

    struct Trader {
        uint id;
        address addr;
        uint balance;
        uint credit_score;
    }

    struct Investor {
        uint id;
        address addr;
        uint balance;
    }

    struct Investment {
        uint value;
        uint investor_id;
    }

    struct Txn {
        uint id;
        uint value;
        uint loanvalue;
        uint exporter;
        uint importer;
        uint interest;
        string ipfs_LC_hash;
        string ipfs_invoice_hash;
        string ipfs_docs_hash;
        string deadline;
        uint investment_cnt;
        uint investmentsum;
        uint stage;
        string stage_name;
        mapping (uint => Investment) investments;
    }

    function create_trader(address addr) external{
        if(msg.sender!=addr) throw;
        traders.push(Trader(traders.length,addr,1000,5));
        traders_addr[addr]=Trader(traders.length-1,addr,1000,5);
    }

    function get_trader_count() returns(uint){
        return traders.length;
    }
    
    function get_trader_balance(address addr) returns(uint){
        if(msg.sender!=addr) throw;
        return traders_addr[addr].balance;
    }

    function create_investor(address addr,uint inv_st) external{
        if(msg.sender!=addr) throw;
        investors.push(Investor(investors.length,addr,inv_st));
        investors_addr[addr]=Investor(investors.length,addr,inv_st);

    }

    function get_investor_count() returns(uint){
        return investors.length;
    }
    
    function get_investor_balance(address addr) returns(uint){
        if(msg.sender!=addr) throw;
        return investors_addr[addr].balance;
    }


    function create_txn(uint valuee, uint loanvaluee,
     address exporterr, address importerr, uint interestt,
      string invoicee, string docc, string datetime) external{
        txns.push(Txn(txns.length,valuee, 
            loanvaluee, traders_addr[exporterr].id,
             traders_addr[importerr].id, 
            interestt,"none",invoicee,docc,
            datetime,0,0,0,
            "Pre Processing/Raw Materials"));
    }

    
    function get_txn_count() returns(uint){
        return txns.length;
    }

    function get_txn_str(uint i) returns(string){
        return txns[i].ipfs_invoice_hash;
        // return 'testnet';
    }

    function update_txn_with_LC(uint id, string LC_hash){
        txns[id].ipfs_LC_hash = LC_hash;
    }

    function update_txn(uint valuee, uint loanvaluee,
     address exporterr, address importerr, uint interestt,
      string invoicee, string docc, string deadline) external{
        txns[id] = Txn(txns.length,valuee, 
            loanvaluee, traders_addr[exporterr].id,
             traders_addr[importerr].id, 
            interestt,txns[id].ipfs_LC_hash,invoicee,docc,deadline);
    }
    //Transaction enpoints on ethereum


    function create_order_statistic(uint valuee,address importerr, uint interestt,
      string invoicee, string docc) returns (uint,uint,uint) external{
        Txn t = txns.get(Txn(txns.length,valuee, 
             traders_addr[exporterr].id,
             traders_addr[importerr].id, 
            interestt));
        return (t.value,t.loanvalue,t.interest)
    }

    function get_escrow_account_balance() returns(uint){
        if(msg.sender!=this.address) throw;
        //get Balance from Dao
        return Ballot.get_balance();
    }

    
    function update_status_endpoint(address addr, index id, string status) returns(bool){
        txns[id].stage_name = status;    
    }  

    function make_investment(address addr, uint tid,uint amount){
        if(msg.sender!=addr) throw;
        if(Ballot.getVote(investors_addr[msg.sender()])){
            if(investors_addr[addr].balance < amount) throw;
            txns[tid].investmentsum += amount;
            txns[tid].investment_cnt++;
            txns[tid].investments[adrr] = amount;
            investors_addr[addr].balance -= amount;
        }

    } 


    
}