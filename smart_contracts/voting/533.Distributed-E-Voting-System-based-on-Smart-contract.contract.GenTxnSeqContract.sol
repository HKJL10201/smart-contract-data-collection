    pragma solidity ^0.4.0;                                        
                                                                   
    contract GenTxnSeqContract {                                           
        
        uint256 private transactionSequenceNumber;

        event EventForGenTxnSequence(uint256 txnseq);                    

        function GenTxnSeqContract(uint256 init_number, address fisc_account)
        {   
            transactionSequenceNumber=init_number;
            fiscAccount = fisc_account; 
        }                                                          

        address private fiscAccount;

	    modifier mustBeFiscAccount() {
		    if (msg.sender == fiscAccount) {
		        _;
		    } else {
		        throw;
		    }
	    }

	    function getFiscAccount() constant returns (address) {
	        return fiscAccount;
	    }

        function genTxnSequence() 
                             mustBeFiscAccount {                            
  
            transactionSequenceNumber++;
		    
            EventForGenTxnSequence(transactionSequenceNumber);                    
        }                                                          

        function checkTxnSeqence() constant returns(uint256) {        
            return transactionSequenceNumber;                                           
        }                                                          

        function checkAddress() constant returns(address) {        
            return this;                                           
        }                                                          

        function checkMsgSender() constant returns(address) {
            return msg.sender;
        }
        
    } 