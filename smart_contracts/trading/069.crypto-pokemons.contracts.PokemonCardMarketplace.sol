pragma solidity >=0.5.0 <0.6.0;

import "./PokemonCardOwnership.sol";


contract PokemonCardMarketplace is PokemonCardOwnership {

    struct Market {
        address winner;
        address seller;
        uint pokemonId;
        uint price;
        bool ended;
    }

    Market[] public market;
    mapping (uint => bool) private _pokemonInMarket;
    mapping (uint => uint) private _pokemonIdToItemId;
    uint private _totalPokemonsOnMarket;
    uint public creationFee = 0.1 ether;

    event SoldPokemon(uint itemId, uint pokemonId, address buyer);
    event NewItem(uint itemId, uint pokemonId, address seller);
    event PriceChange(uint itemId, address seller, uint newPrice);
    event TakenOffMarket(uint itemId, address seller);

    modifier isNotOnMarket(uint _pokemonId) {
        require(!_pokemonInMarket[_pokemonId]);
        _;
    }
    
    function isSelling(uint _pokemonId) public view returns(bool) {
        return _pokemonInMarket[_pokemonId];
    }

    /**
    Create item in the market
    The pokemon must not already be on the market.
    The sender must own the pokemon.
    Set price must be greater than 0
    **/
    function createItem(uint _pokemonId, uint _price) public payable isNotOnMarket(_pokemonId) ownerOfPokemon(_pokemonId){
        require(msg.value >= creationFee);
        require(_price > 0);
        Market memory item;
        item.seller = msg.sender;
        item.pokemonId = _pokemonId;
        item.price = _price;
        item.ended = false;
        market.push(item);
        _pokemonInMarket[_pokemonId] = true;
        _pokemonIdToItemId[_pokemonId] = market.length - 1;
        _totalPokemonsOnMarket = _totalPokemonsOnMarket.add(1);
        emit NewItem(market.length - 1, _pokemonId, msg.sender);
    }

    function buyItem(uint _itemId) public payable {
        Market storage item = market[_itemId];
        require(msg.value == item.price);
        require(!item.ended);
        uint pokemonId = item.pokemonId;
        address payable owner = pokemonToOwner[pokemonId];
        require(owner != msg.sender);
        item.winner = msg.sender;
        item.ended = true;
        pendingWithdrawals[owner] += msg.value;
        _transfer(owner, msg.sender, pokemonId);
        _pokemonInMarket[pokemonId] = false;
        _pokemonIdToItemId[pokemonId] = 0;
        _totalPokemonsOnMarket = _totalPokemonsOnMarket.sub(1);
        emit SoldPokemon(_itemId, pokemonId, msg.sender);
    }

    function takeOffMarket(uint _itemId) public payable {
        Market storage item = market[_itemId];
        require(!item.ended);
        uint pokemonId = item.pokemonId;
        require(msg.sender == pokemonToOwner[pokemonId]);
        address payable owner = pokemonToOwner[pokemonId];
        require(owner == msg.sender);
        item.ended = true;
        _pokemonInMarket[pokemonId] = false;
        _pokemonIdToItemId[pokemonId] = 0;
        _totalPokemonsOnMarket = _totalPokemonsOnMarket.sub(1);
        emit TakenOffMarket(_itemId, msg.sender);
    }

    function takeOffMarketWithPokemonId(uint _pokemonId) public payable ownerOfPokemon(_pokemonId){
        uint _itemId = _pokemonIdToItemId[_pokemonId];
        Market storage item = market[_itemId];
        require(!item.ended);
        address payable owner = pokemonToOwner[_pokemonId];
        require(owner == msg.sender);
        item.ended = true;
        _pokemonInMarket[_pokemonId] = false;
        _pokemonIdToItemId[_pokemonId] = 0;
        _totalPokemonsOnMarket = _totalPokemonsOnMarket.sub(1);
        emit TakenOffMarket(_itemId, msg.sender);
    }

    function getMarketCount() public view returns (uint) {
        return market.length;
    }

    function getTotalMarketItems() public view returns (uint) {
        return _totalPokemonsOnMarket;
    }

    function getPrice(uint itemId) public view returns (uint) {
        return market[itemId].price;
    }

    function setCreationFee(uint _fee) external onlyOwner {
        creationFee = _fee;
    }

    function getItemInfo(uint _itemId) public view returns (address, uint, uint) {
        Market storage item = market[_itemId];
        return (item.seller, item.pokemonId, item.price);
    }

    function getItemAndPokemonInfo(uint _itemId) public view returns (address, uint, uint, uint, string memory, string memory, uint32, uint32, uint32, uint32, uint32, uint32, bool) {
        Market storage item = market[_itemId];
        Pokemon storage pokemon = pokemons[item.pokemonId];
        return (item.seller, item.pokemonId, item.price, pokemon.pokemonNumber, pokemon.nickname, pokemon.type1, pokemon.baseStats.hp, pokemon.baseStats.attack, pokemon.baseStats.defense, pokemon.baseStats.specialAttack, pokemon.baseStats.specialDefense, pokemon.level, pokemon.gender);
    }

    function getAllMarketplaceItems() public view returns (uint[] memory) {
        uint[] memory result = new uint[](_totalPokemonsOnMarket);
        uint counter = 0;
        for (uint i = 0; i < market.length; i++) {
            if (!market[i].ended) {
                result[counter] = i;
                counter = counter.add(1);
            }
        }
        return result;
    }
}
