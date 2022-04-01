pragma solidity > 0.6.1 < 0.7.0; 
import "./provableAPI.sol";

contract Authenticator is usingProvable{
//contract Authenticator{

    mapping( address => string) internal privateCode;
    mapping( address => uint) internal randomNumber;
    mapping( address => bool) internal hasGetRandomNumber;
    event ranNum(uint ran);

//oracle
    uint256 constant NUM_RANDOM_BYTES_REQUESTED =1;
    uint256 internal latestNumber;

    event LogNewProvableQuery( string description );
    event generatedRandomNumber( uint256 randomNumber );
    

    function setPrivateCode( string memory code ) public {

        privateCode[msg.sender] = code;
    }
    
    constructor() public {
        update();
    }
 
    function getRandomNumber() public payable {
        randomNumber[msg.sender] = latestNumber;
        hasGetRandomNumber[msg.sender] = true;
        emit ranNum(randomNumber[msg.sender]);
        update();
    }
    
    
    function __callback( bytes32 , string memory _result, bytes memory ) override public {
        require( msg.sender == provable_cbAddress() );
   
        uint256 ran = uint256( keccak256( abi.encodePacked( _result) ) ) % 100;
        latestNumber = ran;
        emit generatedRandomNumber(ran);
    
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
    
/* 
    function getRandomNumber() public returns(uint){
        uint ran = 2;
        randomNumber[msg.sender] = ran;
        hasGetRandomNumber[msg.sender] = true;
        emit ranNum(ran);
        return(ran);

    }

*/

    function compareCode( bytes32 encodedCode) public returns(bool) {
        require(hasGetRandomNumber[msg.sender] == true);
        if( encodedCode
            == 
            keccak256( abi.encodePacked( privateCode[msg.sender], randomNumber[msg.sender] ) )
            ){    
                hasGetRandomNumber[msg.sender] = false;
                return true;
                
            }
        else{   
                hasGetRandomNumber[msg.sender] = false;
                return false;
            
        }
        
      
        
        
    }

    
    
    

}