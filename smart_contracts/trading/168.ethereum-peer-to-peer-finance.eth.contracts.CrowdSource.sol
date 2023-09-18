contract CrowdSource {
    
    Trader[] traders;
    Investor[] investors;
    Txn[] txns;
    mapping (address => Trader) traders_addr;
    

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
        traders.push(Trader(traders.length,addr,1000,5));
        traders_addr[addr]=Trader(traders.length-1,addr,1000,5);
    }

    function get_trader_count() returns(uint){
        // return traders.length;
        return traders.length;
    }
    


    function get_trader_balance(address addr) returns(uint){
        // return traders.length;
        return traders_addr[addr].balance;
    }

    function create_txn(uint valuee, uint loanvaluee,
     address exporterr, address importerr, uint interestt,
      string invoicee, string docc) external{
        txns.push(Txn(txns.length,valuee, 
            loanvaluee, traders_addr[exporterr].id,
             traders_addr[importerr].id, 
            interestt,"none",invoicee,docc,
            "01-08-2016 00:00:00",0,0,0,
            "Procuring Raw Materials"));
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

    
    
}