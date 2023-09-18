//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";
contract CollegeContract {
    string public quote = "sfvkdjfbvjlvn";
    address public owner;
    
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct MetaTransaction {
            uint256 nonce;
            address from;
    }
    mapping(address => uint256) public nonces;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from)"));
    bytes32 internal DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("Quote")),
            keccak256(bytes("1")),
            5, // goerli
            address(this)
    ));

function setQuoteMeta(address userAddress,string memory newQuote, bytes32 r, bytes32 s, uint8 v) public {
        
    MetaTransaction memory metaTx = MetaTransaction({
        nonce: nonces[userAddress],
        from: userAddress
    });
    
    bytes32 digest = keccak256(
        abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from))
        )
    );

   require(userAddress != address(0), "invalid-address-0");
   require(userAddress == ecrecover(digest, v, r, s), "invalid-signatures");
	
   quote = newQuote;
   owner = userAddress;
   nonces[userAddress]++;
 }       // Make an instance of the predefined struct
  
//<-- Auth
    // address of the contract deployer.
    mapping(address => bool) private admins;
    string allowedUser = "ipfsLink";
    
    constructor(MinimalForwarder forwarder) ERC2771Context(address(forwarder)) {
        admins[_msgSender()] = true;
    }
    
    modifier onlyAdmin {
        require(admins[_msgSender()], "Unauthorized Request");
        _;
    }

    function addAdmin(address _allowedAdmin) onlyAdmin public {
        admins[_allowedAdmin] = true;
    }

    function addUser(string calldata _allowedUser) onlyAdmin public {
        allowedUser = _allowedUser;
    }

    function getUser() view public returns(string memory){
        return allowedUser;
    }
//-->

    string private postList = "sjhvbwvkvbowrubvowriv";
    function addPost(string calldata _pollList) public{
        postList = _pollList;
    }
    function getPost() public view returns(string memory){
        return postList;
    }

    string private suggestionList = "skvjbsnlvknlkvnw";
    function addSuggestion(string calldata _pollList) public{
        postList = _pollList;
    } 
    function getSuggestion() public view returns(string memory){
        return postList;
    }
    
//Polls

    // results
    // {
    //     "timestamp" : {
    //         0 : 15,
    //         1 : 86, 
    //     }

    // }

    string private pollList = "akub";
    mapping(string => mapping(uint8 => uint256)) private results;
    
    function getPollsList() public view returns(string memory){
        return pollList;
    }

    function addPolls(string calldata _pollList) public{
        pollList = _pollList;
    } // poll creator.
    
    function vote(string calldata polldata, uint8 optionId) public{
        results[polldata][optionId]++;
    } //voter

    function getScore(string calldata polldata, uint8 optionId) public view returns(uint256){
        return results[polldata][optionId];
    }

    function setQuote(string memory newQuote) public {
        quote = newQuote;
        owner = msg.sender;
    }

    function getQuote() public view returns (string memory currentQuote, address currentOwner)
    {
        currentQuote = quote;
        currentOwner = owner;
    }

}






// sjhvbwvkvbowrubvowriv => {
//         "timestamp" : {
//             "add" : fdjkvbkfv
//             "
//         }
//         "newTIme" : {
//             "add" : slfnoivnprv,
//             "content" : {
//                 image : "sfvkudbve", //IPFS UPLOAD
//                 "Text" : "svs"   
//             }
//             "app_flag" : 0,
//         }


         
//     }