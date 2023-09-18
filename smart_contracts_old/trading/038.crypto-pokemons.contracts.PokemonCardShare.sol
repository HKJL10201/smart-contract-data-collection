pragma solidity >=0.5.0 <0.6.0;

import "./PokemonCardFactory.sol";


contract PokemonCardShare is PokemonCardFactory {

    mapping (uint => address payable) internal _pokemonToSharee;
    mapping (address => uint) private _shareePokemonCount;
    event SharedPokemon(uint pokemonId, address sharee);
    event UnsharedPokemon(uint pokemonId, address sharee);

    function shareCard(uint _pokemonId, address payable _sharee) public ownerOfPokemon(_pokemonId) {
        require(!isSharing(_pokemonId));
        require(_sharee != msg.sender);
        _pokemonToSharee[_pokemonId] = _sharee;
        _shareePokemonCount[_sharee] = _shareePokemonCount[_sharee].add(1);
        emit SharedPokemon(_pokemonId, _sharee);
    }

    function isSharing(uint _pokemonId) public view returns(bool) {
        return _pokemonToSharee[_pokemonId] != address(0);
    }

    function unshareCard(uint _pokemonId) public ownerOfPokemon(_pokemonId) {
        require(isSharing(_pokemonId));
        address _sharee = _pokemonToSharee[_pokemonId];
        _pokemonToSharee[_pokemonId] = address(0);
        _shareePokemonCount[_sharee] = _shareePokemonCount[_sharee].sub(1);
        emit UnsharedPokemon(_pokemonId, _sharee);
    }

    function getSharedPokemonCardsByOwner() external view returns (uint[] memory) {
        uint[] memory result = new uint[](_shareePokemonCount[msg.sender]);
        uint counter = 0;
        for (uint i = 0; i < pokemons.length; i++) {
            if (_pokemonToSharee[i] == msg.sender && isSharing(i)) {
                result[counter] = i;
                counter = counter.add(1);
            }
        }
        return result;
    }

}
