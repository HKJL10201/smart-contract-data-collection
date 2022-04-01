//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/access/Ownable.sol";
import "contracts/utils/cryptography/MerkleProof.sol";
import "contracts/utils/Counters.sol";

contract VelorexNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint;
    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;


    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public presaleCost = 0.03 ether;
    uint256 public maxSupply = 1000;
    uint256 public maxMintPerTransaction = 2;
    bool public paused = false;

    uint256 public saleState;
    PresaleData[] public presaleData;
    
    Counters.Counter public nftPerAddressCounter;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;
    

      struct PresaleData {
        //uint256 maxMintPerTransaction;
        //uint256 price;
        bytes32 merkleroot;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);

        //send 15 nfts to owner address upon deployment
        mint(msg.sender, 3);
    }


    modifier whenSaleStarted() {
        require(saleState > 0 || saleState < 5,"Sale not active");
        _;
    }

    modifier whenSaleStopped() {
        require(saleState == 0,"Sale already started");
        _;
    } 

    
    
    modifier whenAddressOnWhitelist(bytes32[] memory _merkleproof) {
        require(MerkleProof.verify(
            _merkleproof,
            getPresale().merkleroot,
            keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on white list"
        );
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _maxMintPerTransaction) public payable {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(_to);
        require(!paused);
        require(_maxMintPerTransaction > 0);
        require(_maxMintPerTransaction <= maxMintPerTransaction);
        require(supply + _maxMintPerTransaction <= maxSupply);

        if(msg.sender != address(0)){
             require(tokenCount <  5, "Mint limit reached for this wallet!");
        }
        if (msg.sender != owner()){
            if (whitelisted[msg.sender] != true) {
                if (presaleWallets[msg.sender] != true) {
                    //general public
                     require(msg.value >= cost * _maxMintPerTransaction);
                    
                } else {
                    //presale
                    require(msg.value >= presaleCost * _maxMintPerTransaction);
                }
            }
        }


        for (uint256 i = 1; i <= _maxMintPerTransaction; i++) {
            _safeMint(_to, supply + i);
            
        }

        //fund goes straight to the owner's address
        payable(owner()).transfer(msg.value);
    }



    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;

    }



    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }



    function getPresale() private view returns (PresaleData storage) {
        return presaleData[saleState];
    }


    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }


    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    //change max mint amount
    function setmaxMintPerTransaction(uint256 _newmaxMintPerTransaction) public onlyOwner {
        maxMintPerTransaction = _newmaxMintPerTransaction;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    //stop sales
   function stopSale() external whenSaleStarted() onlyOwner() {
        saleState = 0;
    }

    //Pause the contract
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    //Add whitelist members
    function whitelistUser(address _user) public  onlyOwner {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

   

    function addPresaleUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 2; i++) {
            presaleWallets[_users[i]] = true;
        }
    }

    function removePresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
