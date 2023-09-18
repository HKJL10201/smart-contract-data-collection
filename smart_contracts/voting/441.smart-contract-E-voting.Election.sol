pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;
import "./Vote.sol";

contract Election
{

    mapping(uint => VoteLibrary.Vote) public Voters;
    uint256 public voterCount = 0;

    mapping(uint => VoteLibrary.Party) public Parties;
    uint256 public partyCount = 0;

    mapping(uint => VoteLibrary.Identity) public Identities;
    uint256 public identityCount = 0;
    
    string public code = uint2str(VerificationCode());

    
    
    function createParty(string memory _name) public returns(uint256)
    {
        require(checkIfCanExist(_name));
        partyCount++;
        Parties[partyCount] = VoteLibrary.Party(_name, 0);
        emit PartyCreate(_name, 0);
    }
    
    function getParty(string memory _partyName) private returns (uint)
    {
        for(uint i=1;i<=partyCount;i++)
        {
            string memory partyNamed = Parties[i].name;
            if(keccak256(abi.encodePacked((partyNamed))) == keccak256(abi.encodePacked((_partyName))))
            {
                return i;
            }
        }
    }
    
    function getPartyCount() public returns (uint)
    {
        return partyCount;
    }
    
    
    
    function checkIfCanExist(string memory _namer) private returns(bool)
    {
        for(uint i=1;i<=partyCount;i++)
        {
            string memory partyNamed = Parties[i].name;
            if(keccak256(abi.encodePacked((partyNamed))) == keccak256(abi.encodePacked((_namer))))
            {
                return false;
            }
        }
        return true;
    }
    
    
    
    
    function registerUser(string memory _votername, string memory _matriculeCardNumber, string memory _email) public returns(uint256)
    {
        require(checkIfIdCanExist(_matriculeCardNumber));
        identityCount++;
        Identities[identityCount] = VoteLibrary.Identity(_votername,_matriculeCardNumber,_email);
        emit IdentityCreate(_votername,_matriculeCardNumber,_email);
    }
    
    
        function checkIfIdCanExist(string memory _namered) private returns(bool)
    {
        for(uint i=1;i<=identityCount;i++)
        {
            string memory idNamed = Identities[i].matriculeCardNumber;
            if(keccak256(abi.encodePacked((idNamed))) == keccak256(abi.encodePacked((_namered))))
            {
                return false;
            }
        }
        return true;
    }
    
    
    
    function generateVote(string memory _adder, string memory _date, string memory _partyName, string memory _code) public returns(uint256)
    {
        require(!checkIfIdCanExist(_code));
        require(checkIfCanVote(_code));
        require(!checkIfCanExist(_partyName));
        voterCount++;
        Voters[voterCount] = VoteLibrary.Vote(voterCount, block.timestamp, _date,_partyName, _code);
        uint partyIndex = getParty(_partyName);
        Parties[partyIndex].voteCount++;
        emit VoteGenerate(voterCount, block.timestamp, _date,_partyName, _code);
    }
    
    
    function checkIfCanVote(string memory _code) private returns(bool)
    {
        for(uint i=1;i<=voterCount;i++)
        {
            string memory voteNamed = Voters[i].code;
            if(keccak256(abi.encodePacked((voteNamed))) == keccak256(abi.encodePacked((_code))))
            {
                return false;
            }
        }
        return true;
    }
    
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) 
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function VerificationCode() private returns (uint) 
    {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, block.difficulty,msg.sender))) % 10000000000000000000;
        return randomnumber;
    }
    
    
    function getVerificationCode() public returns(string memory)
    {
        return code;
    }
    
    event IdentityCreate(string votername, string matriculeCardNumber, string email);
    event PartyCreate(string name, uint voteCount);
    event VoteGenerate(uint voteCount, uint time, string date, string partyName, string code);

}
