pragma solidity ^0.6.2;
//pragma solidity ^0.5.16;

//based on work of author susmit


import "./ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ERC720.sol";

contract DigitalREC is ERC721,Ownable {
    
    using SafeMath for uint256;
    
    struct RECStruct{
        uint stateID;     //unique state assigned ID
        address owner;    //Owner of REC
        uint price;       // price of REC in ether
    }
    
    uint private count = 0;

    ERC20 currencyToken;
    
    // Creates an empty array of REC structs - the index is the id
    RECStruct[] public RECs;

    // Mapping from id of REC to owner's address
    mapping(uint256 => address) public RECToOwner;

    // Mapping from owner's address to tokens owned
    mapping(address => uint256) public ownerRECCount;
    

    // Mapping from token ID to approved address
    mapping(uint256 => address) RECApprovals;

    constructor() public ERC721("DigitalREC", "REC") {}

    // mint the unique token to represent a valid REC
    function mintToken(uint stateID, uint price) public {
        RECStruct memory rec;
        rec.stateID = stateID;
        rec.owner = msg.sender;
        rec.price = price;

        //require(isUnique(stateID));   --ensure this REC has not been sold before
        //verifyREC(msg.sender, stateID);  --ensure this is a valid REC (verify using an API such as M-RETS)

        uint256 recID = count;
        RECs.push(rec);
        RECToOwner[recID] = msg.sender;
        ownerRECCount[msg.sender] +=1;

        count+=1;

    }

    //return the stateIDs of RECs owned 
    function RECsOwned(address _owner) external view returns (uint256[] memory _ownedRECIds) {
        require(_owner != address(0));
        _ownedRECIds = new uint[](ownerRECCount[_owner]);
        uint numFound = 0;
        for (uint i=0; i<RECs.length; i++) {

            RECStruct memory currREC = RECs[i];
            
            if(currREC.owner == _owner) {
                _ownedRECIds[numFound] = currREC.stateID;
                numFound+=1;
            }
        }
        return _ownedRECIds;
    }


    //buy the REC of the given id - transfer ownership of REC and transfer funds
    function buyREC(uint RECid) public payable {
        RECStruct memory rec = RECs[RECid];
        uint256 rec_price = rec.price;
        address prev_owner = rec.owner;
        //require(msg.value >= rec_price)
        //require(balanceOf(msg.sender)>=rec_price)
        //require(highestOffer(RECid,rec_price))

        transferOwnership(prev_owner, msg.sender, RECid);
        currencyToken.transfer(prev_owner, rec_price);
        
    }
    
  
  function transferOwnership(address _from, address _to, uint256 _RECId) public{
      RECStruct memory rec = RECs[_RECId];
      rec.owner = _to;
      RECs[_RECId] = rec;
      RECToOwner[_RECId] = _to;
      ownerRECCount[_to] +=1;
      ownerRECCount[_from] -=1;
      RECApprovals[_RECId] = _to;


  }
  
    

    
}
