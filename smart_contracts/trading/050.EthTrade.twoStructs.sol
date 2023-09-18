pragma solidity ^0.4.0;

contract TwoStructs { 
    struct A { 
        address[] count; 
    } 
    
    struct B { 
        uint8[] count; 
    } 
    
    mapping (address => A) a; 
    
    mapping (address => B) b; 
    
    function add(address c, uint8 g) { 
        a[msg.sender].count.push(c); 
        b[msg.sender].count.push(g); 
    } 
    
    function get1(address sender) constant returns (address, uint8) { 
        return (a[sender].count[0], b[sender].count[0]); 
    } 
    
    function get2() constant returns (address, uint8) { 
        return (a[msg.sender].count[0], b[msg.sender].count[0]); 
    } 
    
    function getMsgSender() constant returns (address) { 
        return msg.sender; 
    }
}

/***** This worked 


var twoStructsSource='contract TwoStructs { struct A { address[] count; } struct B { uint8[] count; } mapping (address => A) a; mapping (address => B) b; function add(address c, uint8 g) { a[msg.sender].count.push(c); b[msg.sender].count.push(g); } function get1(address sender) constant returns (address, uint8) { return (a[sender].count[0], b[sender].count[0]); } function get2() constant returns (address, uint8) { return (a[msg.sender].count[0], b[msg.sender].count[0]); } function getMsgSender() constant returns (address) { return msg.sender; }}'

var twoStructsCompiled = web3.eth.compile.solidity(twoStructsSource);


var twoStructsContract = web3.eth.contract(twoStructsCompiled.TwoStructs.info.abiDefinition);
var twoStructs = twoStructsContract.new({from:web3.eth.accounts[0], data: twoStructsCompiled.TwoStructs.code, gas: 1000000}, 
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        console.log("Contract transaction send: TransactionHash: " + 
          contract.transactionHash + " waiting to be mined...");
      } else {
        console.log("Contract mined! Address: " + contract.address);
        console.log(contract);
      }
    }
  }
)

twoStructs.add(eth.accounts[0], 1, {
  from:web3.eth.accounts[0], 
  data: twoStructsCompiled.TwoStructs.code,
  gas: 1000000
});

******/
