pragma solidity >=0.4.24;

import "../app/node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract StarNotary is ERC721("Star", "STR") {

    struct Star {
        string name;
    }

    mapping(uint256 => Star) public tokenIdToStarInfo;
    mapping(uint256 => uint256) public starsForSale;


    // Create Star using the Struct
    function createStar(string memory _name, uint256 _tokenId) public { // Passing the name and tokenId as a parameters
        Star memory newStar = Star(_name); // Star is a struct so we are creating a new Star
        tokenIdToStarInfo[_tokenId] = newStar; // Creating in memory the Star -> tokenId mapping
        _mint(msg.sender, _tokenId); // _mint assign the star with _tokenId to the sender address (ownership)
    }

    // Putting an Star for sale (Adding the star tokenid into the mapping starsForSale, first verify that the sender is the owner)
    function putStarUpForSale(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == msg.sender, "You can't sale the Star you don't owned");
        starsForSale[_tokenId] = _price;
    }


    // Function that allows you to convert an address into a payable address
    function _make_payable(address x) internal pure returns (address payable) {
        return payable(address(uint160(x)));
    }

    // TODO: Share solution here https://knowledge.udacity.com/questions/684111
    function allowBuying(uint256 _tokenId, address _by) public {
        approve(_by, _tokenId);
    }

    function buyStar(uint256 _tokenId) public  payable {
        require(starsForSale[_tokenId] > 0, "The Star should be up for sale");

        uint256 starCost = starsForSale[_tokenId];
        address ownerAddress = ownerOf(_tokenId);

        require(msg.value >= starCost, "You need to have enough Ether to buy this star");

        // Transfer the token ownership
        transferFrom(ownerAddress, msg.sender, _tokenId); // We can't use _addTokenTo or_removeTokenFrom functions, now we have to use _transferFrom
        address payable ownerAddressPayable = _make_payable(ownerAddress); // We need to make this conversion to be able to use transfer() function to transfer ethers
        
        // Transfer token cost to the previous owner
        ownerAddressPayable.transfer(starCost);

        if(msg.value > starCost) {
            // Transfer change to the new owner
            _make_payable(msg.sender).transfer(msg.value - starCost);
        }
    }

    // function sellStar(uint256 _tokenId, address buyer) public  payable {
    //     require(starsForSale[_tokenId] > 0, "The Star should be up for sale");

    //     uint256 starCost = starsForSale[_tokenId];
    //     address ownerAddress = msg.sender;

    //     require(buyer.balance > starCost, "You need to have enough Ether to buy this star");

    //     // Transfer the token ownership
    //     transferFrom(ownerAddress, buyer, _tokenId); // We can't use _addTokenTo or_removeTokenFrom functions, now we have to use _transferFrom
    //     address payable ownerAddressPayable = _make_payable(ownerAddress); // We need to make this conversion to be able to use transfer() function to transfer ethers
        
    //     // Transfer token cost to the previous owner
    //     ownerAddressPayable.transfer(starCost);

    //     if(buyer.balance > starCost) {
    //         // Transfer change to the new owner
    //         _make_payable(buyer).transfer(buyer.balance - starCost);
    //     }
    // }

}