pragma experimental ABIEncoderV2;
contract ApostilleContract
{
    struct Apostille {
        bytes32 tag;
        address owner;
        uint timestamp;
    }
    
    mapping(bytes32=>Apostille) apostiles;
    
    mapping(address=>bytes32[]) users;
    
    function addApostille(bytes32 _hash,bytes32 _tag) public {
        apostiles[_hash] = Apostille({tag:_tag,owner:msg.sender,timestamp:block.timestamp});
        users[msg.sender].push(_hash);
    }
    function getApostillesOfUser(address _owner) public view returns(bytes32[] memory){
        return users[_owner];
    }
    function getApostille(bytes32 _hash) public view returns(Apostille memory){
        return apostiles[_hash];
    }
    function verify(bytes32 _hash, address _owner) public view returns(bool){
        Apostille storage a = apostiles[_hash];
        require(a.timestamp>0);
        require(a.owner==_owner);
        return true;
    }
    
}