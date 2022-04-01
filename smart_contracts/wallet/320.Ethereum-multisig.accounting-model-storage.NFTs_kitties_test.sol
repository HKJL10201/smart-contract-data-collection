// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2;


// ERC721 standard for NFTs

contract KittyContract{
    string public constant name = "TestKitties";
    string public constant symbol = "TK";
     
    //------------------------------------------------------
    // events
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    
    event Birth(
        address owner,
        uint256 kittenId,
        uint32 momId,
        uint32 dadId,
        uint256 genes);
    
    //--------------------------------------------------------
    // Data Storage for crypto-kitties
    struct Kitty{
        uint256 genes;
        uint64 birthTime;
        uint32 momId;
        uint32 dadId;
        uint16 generation;
    }  
    
    Kitty[] kitties;
    
    // index of NFT to owner address
    struct kittyIndex2Owner_struct{
        address adrs;
        uint256 pointer;
    }
    mapping(uint256 => kittyIndex2Owner_struct) public kittyIndex2Owner;
    
    
    // address of owner to Number of NFTs owned
    mapping(address => uint256) NtokensOwned;
    
    // address of owner to all kittens owned (array)
    mapping(address => uint256[]) tokensOwned;
    
    
    //--------------------------------------------------------
    // functions query info of the NFT owners account (crypto kitties)
    
    /*
    // @dev balanceOf: returns the number of crypto kitties tokens owned by input address
    // @param _owner: address of the account to ask its balance
    */
    function balanceOf(address _owner) external view returns (uint256 _balance){
        _balance = NtokensOwned[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view returns(address _owner){
        _owner = kittyIndex2Owner[_tokenId].adrs;
    }
    
    function _owns(address _claimer, uint256 _tokenId) internal view returns(bool){
        return kittyIndex2Owner[_tokenId].adrs == _claimer;
    }
    
    /*
    // time-wise inefficient, iterates over an increasing array
    function getAllCatsFor(address _owner) public view returns(uint[] memory cats){
        uint[] memory result = new uint[](NtokensOwned[_owner]);
        uint counter = 0;
        for (uint i=0; i<kitties.length; i++){
            if (kittyIndex2Owner[i] == _owner){
                result[counter] += 1;
                counter += 1;
            }
        }
        return result;
    }
    */
    
    function getAllCatsFor(address _owner) public view returns(uint[] memory){
        return tokensOwned[_owner];
    }
    
    
    //------------------------------------------------------------
    // functions to create NFTs
    function totalSupply() public view returns(uint256 _TotSupply){
        _TotSupply = kitties.length;
    }
    
    function _createKitty(
        uint32 _momId,
        uint32 _dadId,
        uint16 _generation,
        uint256 _genes,
        address _owner
    ) private returns(uint256){
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            momId: uint32(_momId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        
        kitties.push(_kitty);
        uint256 newKittenId = kitties.length + 1;
        
        emit Birth(_owner, newKittenId, _momId, _dadId, _genes);
        
        _transfer(address(0), _owner, newKittenId);
        
        return newKittenId;
    }
        
    //------------------------------------------------------------
    // Create genesis kitten
    function createKittyGen0(uint256 _genes) public returns (uint256) {
        return _createKitty(0, 0, 0, _genes, msg.sender);
    }
    
    // function to create kitties after genesis
    function createKitty(
        uint32 _momId,
        uint32 _dadId,
        uint16 _generation,
        uint256 _genes,
        address _owner
    ) public returns (uint256){
        require(kitties.length != 0, "Genesis cat needs to be created before creating new cats");
        return _createKitty(_momId, _dadId, _generation, _genes, _owner);
    }
    
    
    //------------------------------------------------------------
    // functions to transact NFTs
    /*
    // @dev _transfer: 
    */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        NtokensOwned[_to] += 1;
        kittyIndex2Owner[_tokenId].adrs = _to;
        
        if (_from != address(0)){
            NtokensOwned[_from] -= 1;
            uint256 pointer2delete = kittyIndex2Owner[_tokenId].pointer;               // a) grab the pointer of the cat of the array for the sender
            uint256 elem2reuse = tokensOwned[_from][tokensOwned[_from].length -1];     // b) grab the last element in the cats-owned sender's array
            tokensOwned[_from][pointer2delete] = elem2reuse;                           // c) replace b) id in the cats-owned sender's array
            tokensOwned[_from].pop();                                                  // d) pop the last element in the sender's array
            tokensOwned[_to].push(_tokenId);                                           // e) append the token id to the receiver's array
        }
        tokensOwned[_to].push(_tokenId);                                               // if sending from address(0) do e) as well
        emit Transfer(_from, _to, _tokenId);                                           
    }
    
    
    /*
    // @dev transfer: tranfers an NFT from one account to another
    // @param _to: receiver address
    // @param _tokenId: Id of the token
    */
    function transfer(address _to, uint256 _tokenId) external{
        require(_to != address(0), "Not a valid address");
        require(_to != address(this), "Can not auto-trnasfer");
        require(_owns(msg.sender, _tokenId), "This address is not the owner");
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
     
}

