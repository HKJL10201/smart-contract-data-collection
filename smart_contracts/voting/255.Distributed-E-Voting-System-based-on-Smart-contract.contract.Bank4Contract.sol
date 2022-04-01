    pragma solidity ^0.4.0;                                        
                                                                   
    contract Bank4Contract {                                           
        
        struct entry  {
            uint time;
            uint256 txnseq;
            uint256 amount;
            bytes32 from;
            bytes32 to;
            bytes32 note;  // Cr: Credit (+)  Dr: Debit (-)  R+/R-: Reversal  
        }
         
    	struct log {
		    uint256 size;    
		    mapping(uint256 => entry) entries;  // use txnseq as index
	    }
	    
	    log private transactionLog;
	    
        uint256 private bank_balance;    // total balance of Bank4
        bytes32 private bank_name = "Bank4";
        uint256 private constant DEFAULT_QUOTA = 30000; // default quota

        struct quota  {
            bytes32 [] indices;         // indexes
            mapping(bytes32 => uint256) dailyAmounts;
            mapping(bytes32 => uint256) dailyQuotas;
            mapping(bytes32 => bool) hasEntry;
        }
        
        quota private transferQuota;
        
        uint256 private init_balance;
        
        struct ledger {
            bytes32 [] indices;
            mapping(bytes32 => uint256) balances;
            mapping(bytes32 => bool) hasEntry;
        }

        ledger private ledgers;        
        
        event EventForTransferTo(uint256 amount,uint256 txnseq, bytes32 to);                    
        event EventForReceiveFrom(uint256 amount,uint256 txnseq, bytes32 from);                    
        event EventForReverseTransferTo(uint256 amount,uint256 txnseq);                    
        event EventForReverseReceiveFrom(uint256 amount,uint256 txnseq);                    

        function Bank4Contract(uint256 initBalance, address fisc_account, address admin_account)
        {   
            bank_balance = initBalance;
            init_balance = initBalance;
            fiscAccount=fisc_account;
            
            bankAdminCount = 1;
            bankAdmins[admin_account]=true;
        }                                                          

        // number of Bank administrators
        uint256 private bankAdminCount;
        
        // accounts of Bank administrators
        mapping(address => bool) private bankAdmins;

        // only Bank administrators are allowed to add or remove 
        // member banks, other administrators, as well as FISC accounts.
	    modifier mustBeBankAdmin() {
		    if (bankAdmins[msg.sender]) {
		        _;
		    } else {
		        throw;
		    }
	    }

        // only Bank administrators are allowed to add other administrators
	    function addBankAdmin(address addr) mustBeBankAdmin {
		    if (!bankAdmins[addr]) {
		        bankAdmins[addr] = true;
		        bankAdminCount++;
		    }
	    }

        // only Bank administrators are allowed to remove other administrators
    	function removeBankAdmin(address addr) mustBeBankAdmin {
	        if (bankAdminCount == 1) throw;

	        if (bankAdmins[addr]) {
	            delete bankAdmins[addr];
    	        bankAdminCount--;
	        }
	    }

        address private fiscAccount;

	    modifier mustBeFiscAccount() {
		    if (msg.sender == fiscAccount) {
		        _;
		    } else {
		        throw;
		    }
	    }

        function setFiscAccount(address addr) mustBeBankAdmin {
            fiscAccount = addr;
        }

	    function getFiscAccount() constant returns (address) {
	        return fiscAccount;
	    }

        function transferTo(uint256 amount, uint256 txnseq, bytes32 to) 
                            mustBeFiscAccount {                            

		    if(transactionLog.entries[txnseq].txnseq != 0) {
		        throw;   // wrong txnseq
		    }
		    
		    uint256 daily_amount = transferQuota.dailyAmounts[to]+amount;
		    uint256 daily_quota  = transferQuota.dailyQuotas[to];

            if(!transferQuota.hasEntry[to]) {   
                // new entry, add index
                transferQuota.indices.push(to);
                transferQuota.hasEntry[to]=true;
            }

		    if (daily_quota == 0) {  // use default setting
		        daily_quota = DEFAULT_QUOTA; 
		    }  

            if(daily_amount >= daily_quota) {
                throw;
            }

            uint256 res1 = bank_balance - amount;
            bank_balance = res1;     

            if(!ledgers.hasEntry[to]) {   
                // new entry, add index
                ledgers.indices.push(to);
                ledgers.hasEntry[to]=true;
                ledgers.balances[to]=init_balance;
            }

            ledgers.balances[to] -= amount;
            transferQuota.dailyAmounts[to] = daily_amount; // update daily transfer amount
            
            uint time = now;

            transactionLog.size=transactionLog.size+1;
            transactionLog.entries[txnseq]=entry(time , txnseq, amount, bank_name, to, "Dr"); 
            
            EventForTransferTo(amount, txnseq, to);                    
        }                                                          

        function receiveFrom(uint256 amount, uint256 txnseq, bytes32 from) 
                             mustBeFiscAccount {                            

		    if(transactionLog.entries[txnseq].txnseq != 0) {
		        throw;   // wrong txnseq
		    }

            uint256 res1 = bank_balance + amount;
            bank_balance = res1;          

            if(!ledgers.hasEntry[from]) {   
                // new entry, add index
                ledgers.indices.push(from);
                ledgers.hasEntry[from]=true;
                ledgers.balances[from]=init_balance;
            }

            ledgers.balances[from] += amount;

            uint time = now;

            transactionLog.size=transactionLog.size+1;
            transactionLog.entries[txnseq]=entry(time, txnseq, amount, from, bank_name,"Cr"); 

            EventForReceiveFrom(amount, txnseq, from);                    
        }                                                          

        function reverseTransferTo(uint256 amount, uint256 txnseq) 
                            mustBeFiscAccount {
            
            uint256 log_amount = transactionLog.entries[txnseq].amount;
            
            if (log_amount == 0) throw; // no such transaction record
            if (log_amount != amount) throw; // wrong input amount
            
            bytes32 log_note = transactionLog.entries[txnseq].note;
            
            if (log_note == "Dr->R+") {
                throw;   // check if already reversed
            }

            bank_balance = bank_balance + amount;  // reversal of balance


            bytes32 to = transactionLog.entries[txnseq].to;

            ledgers.balances[to] += amount;
            transferQuota.dailyAmounts[to]-=amount;    //  reversal of daily transfer amount 
                        
            transactionLog.entries[txnseq].note = "Dr->R+"; // record this operation            

            EventForReverseTransferTo(amount, txnseq);                    
        }

        function reverseReceiveFrom(uint256 amount, uint256 txnseq) 
                            mustBeFiscAccount {
            
            uint256 log_amount = transactionLog.entries[txnseq].amount;
            
            if (log_amount == 0) throw; // no such transaction record
            if (log_amount != amount) throw; // wrong input amount

            bytes32 log_note = transactionLog.entries[txnseq].note;
            
            if (log_note == "Cr->R-") {
                throw;   // check if already reversed
            }

            bank_balance= bank_balance - amount;  // reversal of balance

            bytes32 from = transactionLog.entries[txnseq].from;
            ledgers.balances[from] -= amount;

            transactionLog.entries[txnseq].note = "Cr->R-"; // record this operation            

            EventForReverseReceiveFrom(amount, txnseq);                    
        }

        function changeTxnDate() mustBeFiscAccount {
            for(uint i=0;i<transferQuota.indices.length;i++) {
                transferQuota.dailyAmounts[transferQuota.indices[i]] = 0;
            }
        }

        function setDailyQuota(uint256 amount, bytes32 name) mustBeBankAdmin{
            if(!transferQuota.hasEntry[name]) {
                // new entry, add index   
                transferQuota.indices.push(name);
                transferQuota.hasEntry[name]=true;
            }
            transferQuota.dailyQuotas[name] = amount;
        }

        function checkDailyQuota(bytes32 name) constant returns (uint256) {
            return transferQuota.dailyQuotas[name];
        }

        function checkDailyAmount(bytes32 name) constant returns (uint256){
            return transferQuota.dailyAmounts[name];
        }

        function checkLedgerBalance(bytes32 name) constant returns (uint256){
            if(!ledgers.hasEntry[name]) {   
                // new entry, add index
                ledgers.indices.push(name);
                ledgers.hasEntry[name]=true;
                ledgers.balances[name]=init_balance;
            }
            return ledgers.balances[name];
        }

        function checkTxnLogByTxnSeq(uint256 txnseq) constant returns(uint,uint256,uint256,bytes32,bytes32,bytes32){
            uint time = transactionLog.entries[txnseq].time;
            uint256 seqno = transactionLog.entries[txnseq].txnseq;
            uint256 amount = transactionLog.entries[txnseq].amount;
            bytes32 from = transactionLog.entries[txnseq].from;
            bytes32 to = transactionLog.entries[txnseq].to;
            bytes32 note = transactionLog.entries[txnseq].note;
            
            return (time,seqno,amount,from,to,note);
        }

        function checkTxnLogSize() constant returns(uint256){
            return transactionLog.size;
        }

        function checkBankBalance() constant returns(uint256) {           
            return bank_balance;                           
        }                                                          
                                                                   
        function checkAddress() constant returns(address) {        
            return this;                                           
        }                                                          

        function checkMsgSender() constant returns(address) {
            return msg.sender;
        }
        
    } 