contract CrowdSource {
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
        uint exporter;
        uint importer;
        uint interest;
        string ipfs_LC_hash;
        string ipfs_invoice_hash;
        string ipfs_docs_hash;
        string deadline;
        uint investment_cnt;
        mapping (uint => Investment) investments;
        uint stage;
        string stage_name;
    }

    uint trader_cnt;
    mapping (uint => Trader) traders;
    mapping (address => Trader) traders_addr;
    uint txn_cnt;
    mapping (uint => Txn) txns;
    uint inv_cnt;
    mapping (uint => Investor) investors;
    mapping (address => Investor) investors_addr;

    function CrowdSource() {
		trader_cnt = 0;
		txn_cnt = 0;
		inv_cnt=0;
	}

	function create_trader(address addr) public{
		traders[trader_cnt] = Trader(trader_cnt,addr,1000,5);
	}

}
