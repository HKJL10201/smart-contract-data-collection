pragma solidity > 0.6.1 < 0.7.0; 
import "./provableAPI.sol";

contract RandomNumGenerator is usingProvable{
    uint256 constant NUM_RANDOM_BYTES_REQUESTED =1;
    uint256 public latestNumber;
    
    event LogNewProvableQuery( string description );
    event generatedRandomNumber( uint256 randomNumber );
    
    constructor() public {
        update();
    }
    
    function __callback( string memory _result) public {
        require( msg.sender == provable_cbAddress());
        
        uint256 randomNumber = uint256( keccak256( abi.encodePacked( _result) ) ) % 100;
        latestNumber = randomNumber;
        emit generatedRandomNumber(randomNumber);
    
    }
    
    function update() payable public {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );
        
        emit LogNewProvableQuery("Provable query sent, standing by for the answer ...");
    }
    
 
}