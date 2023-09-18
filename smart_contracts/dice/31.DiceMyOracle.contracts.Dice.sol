pragma solidity ^0.8.0;


// Oracle interface
abstract contract Oracle {
    address public cbAddress;
    function query(string memory _query) public virtual returns (bytes32 id);
}

// OracleResolver interface
abstract contract OracleResolver {
    function getOracleAddress() public virtual view returns(address);
}

// 給dapp開發者使用的合約
contract UsingMyOracle {
    OracleResolver resolver;
    Oracle oracle;
    constructor(address _address) {
        // resolver = OracleResolver(0x9431dBA1450345B92d84980dc6EAB81741624ba3);
        resolver = OracleResolver(_address);
        oracle = Oracle(resolver.getOracleAddress());
    }

    modifier myOracleAPI {
        // address(resolver);
        //  if (address(resolver) == 0) {
        // //     // 指定OracleResolver的合約地址，要替換成你自己的
            
        // //     //resolver = OracleResolver(0x9431dBA1450345B92d84980dc6EAB81741624ba3);
        // //     //oracle = Oracle(resolver.getOracleAddress());
        //  }
        _;
    }

    modifier onlyFromCbAddress {
        if (msg.sender != oracle.cbAddress())
            revert(); 
        _;
    }
    
    function myOracleQuery(string memory _query) internal myOracleAPI returns(bytes32 id) {
        return oracle.query(_query);
    }

    function _callback(bytes32 _id, string memory result) public onlyFromCbAddress virtual{
        // do nothing, 只是確保Oracle有一個_callback可以使用
    }

    function showOracleResolver() public view returns(address){
        return address(resolver);
    }

    function showOracle() public view returns(address){
        return address(oracle);
    }
}

// 要繼承UsingMyOracle
contract Dice is UsingMyOracle {
    address owner;
    mapping(address => bytes32) myids;
    mapping(bytes32 => string) dice_result;
    
    // 輔助的event，沒有也不影響功能
    event newMyOracleQuery(string description);
    event diceResult(string result);
    
    // function Dice() {
    //     owner = msg.sender;
    // }  
    constructor(address _address) UsingMyOracle(_address) {
        owner = msg.sender;
    }
    
    // 擲骰子
    function dice() public{
        emit newMyOracleQuery("MyOracle query was sent, standing by for the answer..");
        bytes32 myid = myOracleQuery("0-1000"); //指定範圍
        myids[msg.sender] = myid;
    }
    
    // override
    function _callback(bytes32 _id, string memory result) public onlyFromCbAddress override {
        dice_result[_id] = result;
        emit diceResult(result);
    }
    
    function checkResult() public view returns (string memory) {
        return dice_result[myids[msg.sender]];
    }
}