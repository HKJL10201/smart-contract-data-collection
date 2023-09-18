// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "./Product.sol";
import "./BiDirectionalChannel.sol";

/**
@title Marketplace
A contract for managing products and facilitating transactions between buyers and sellers.
*/
contract Marketplace {
    address payable public owner;

    mapping(address => uint256) public balances;

    // Store the channels by their address.
    //mapping(address => BiDirectionalChannel) public channels;

    event OwnershipChanged(address indexed oldOwner, address indexed newOwner);
    event ProductAdded(address indexed productAddress, string name);
    event ProductRemoved(address indexed productAddress);
    event ProductPurchased(address indexed buyer, address indexed productAddress, uint256 price);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ChannelCreated(address indexed user1, address indexed user2, address indexed channelAddress);

    Product[] public products;

    BiDirectionalChannel[] public channels;

    /**
    Contract constructor.
    Sets the transaction sender as the owner of the contract.
    */
    constructor() payable {
        owner = payable(msg.sender); // = seller
    }

    /**
    Modifier to check that the caller is the owner of the contract.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
    Modifier to check if an address is valid (not the zero address).
    @param _addr The address to check.
    */
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    /**
    Changes the owner of the contract.
    @param _newOwner The new owner address.
    */
    function changeOwner(address payable _newOwner) public onlyOwner validAddress(_newOwner) {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipChanged(oldOwner, _newOwner);
    }

    /**
    Destroys the marketplace contract and transfers remaining funds to the owner.
    */
    function destroyMarketplace() public onlyOwner {
        selfdestruct(owner);
    }

    /**
     * Allows a user to deposit funds into the marketplace contract.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        // Update the balance of the user
        balances[msg.sender] += msg.value;

        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
    Adds a new product to the marketplace.
    @param _seller The address of the seller.
    @param _name The name of the product.
    @param _price The price of the product.
    */
    function addProduct(address payable _seller, string memory _name, uint256 _price) public payable onlyOwner {
        Product newProduct = new Product(_seller, _name, _price);
        products.push(newProduct);
        emit ProductAdded(address(newProduct), _name);
    }

    /**
    Retrieves the details of a product.
    @param _index The index of the product in the products array.
    @return seller The address of the seller.
    @return name The name of the product.
    @return price The price of the product.
    @return productAddr The address of the product contract.
    */
    function getProduct(
        uint256 _index
    ) public view returns (address payable seller, string memory name, uint256 price, address productAddr) {
        Product product = products[_index];
        return (product.owner(), product.name(), product.price(), product.productAddr());
    }

    /**
    Retrieves the total number of products in the marketplace.
    @return count The number of products.
    */
    function getProductCount() public view returns (uint count) {
        return products.length;
    }

    /**
    Retrieves the index of a product based on its name.
    @param _name The name of the product.
    @return index The index of the product in the products array, or -1 if not found.
    */
    function getProductIndex(string memory _name) public view returns (int256) {
        for (uint256 i = 0; i < products.length; i++) {
            if (keccak256(abi.encodePacked(products[i].name())) == keccak256(abi.encodePacked(_name))) {
                return int256(i);
            }
        }
        return int256(-1);
    }

    /**
    Allows a buyer to purchase a product.
    @param _buyer The address of the buyer.
    @param _name The name of the product.
    @param _price The price of the product.
    */
    function buyProduct(
        address payable _buyer,
        string memory _name,
        uint256 _price,
        address _marketplaceAddress
    ) public payable {
        int256 index = getProductIndex(_name);
        require(index >= 0, "Product not found.");
        Product product = products[uint(index)];

        // Check if the product is available
        require(product.isAvailable(), "Product not available");

        // Check if the buyer has enough ether
        require(_buyer.balance >= _price, "Insufficient funds");

        // Transfer ether from the buyer to the seller
        _buyer.transfer(_price);

        product.transferOwnership(_buyer, _marketplaceAddress);

        // Verify that the product has been bought
        require(product.getOwner() == _buyer, "Product purchase failed");

        // Remove the product
        removeProduct(uint(index));

        emit ProductPurchased(_buyer, address(product), _price);
    }

    // TODO: For production we would need to make a change and only allow appropriate users
    /**
    Removes a product from the marketplace.
    @param _index The index of the product to remove.
    */
    function removeProduct(uint256 _index) public {
        address productAddress = address(products[_index]);
        products[_index] = products[products.length - 1];
        products.pop();
        emit ProductRemoved(productAddress);
    }

    /**
    Retrieves the bi-directional channel of a pair of users.
    @param _channelAddress The address of the channel contract.
    @return channel The instance of the bi-directional channel contract or a zero address if the channel is not found.
    */
    function getBiDirectionalChannel(address _channelAddress) public view returns (BiDirectionalChannel channel) {
        for (uint i = 0; i < channels.length; i++) {
            if (address(channels[i]) == _channelAddress) {
                return channels[i];
            }
        }

        return BiDirectionalChannel(address(0));
    }

    /**
    Retrieves the bi-directional channel associated with a given user.
    @param _userAddress The address of the user.
    @return channel The instance of the bi-directional channel contract or a zero address if the channel is not found.
    */
    function getBiDirectionalChannelByUser(address _userAddress) public view returns (BiDirectionalChannel channel) {
        for (uint i = 0; i < channels.length; i++) {
            if (channels[i].users(0) == _userAddress || channels[i].users(1) == _userAddress) {
                return channels[i];
            }
        }

        return BiDirectionalChannel(address(0));
    }

    /**
Creates a new bi-directional payment channel.
@param _users The addresses of the two users participating in the channel.
@param _balances The initial balances of the users in the channel.
@param _expiresAt The expiration timestamp of the channel.
@param _challengePeriod The challenge period of the channel.
@return The address of the newly created channel.
*/
    function createBiDirectionalChannel(
        address payable[2] memory _users,
        uint[2] memory _balances,
        uint _expiresAt,
        uint _challengePeriod
    ) public payable returns (address) {
        require(_users.length == 2, "Two users must be provided");
        require(_balances.length == 2, "Balances for two users must be provided");

        BiDirectionalChannel channel = new BiDirectionalChannel{ value: msg.value }(
            [_users[0], _users[1]],
            [_balances[0], _balances[1]],
            _expiresAt,
            _challengePeriod
        );

        channel.depositByUser{ value: _balances[0] }(_users[0]);
        channel.depositByUser{ value: _balances[1] }(_users[1]);

        channels.push(channel);

        emit ChannelCreated(_users[0], _users[1], address(channel));

        return address(channel);
    }

    //TODO: Only allow valid users to close the channel
    /**
    Withdraws funds from the bi-directional payment channel.
    @param _channelAddress The address of the channel contract.
    */
    function withdrawBiDirectionalChannel(address _channelAddress) public {
        BiDirectionalChannel channel = getBiDirectionalChannel(_channelAddress);
        require(address(channel) != address(0), "Channel not found.");

        address payable user = payable(msg.sender);

        channel.withdrawByUser(user);
    }
}
