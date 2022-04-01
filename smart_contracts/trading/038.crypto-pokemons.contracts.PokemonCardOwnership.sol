pragma solidity >=0.5.0 <0.6.0;

import "./PokemonCardAttack.sol";
import "./ERC721.sol";

contract PokemonCardOwnership is PokemonCardAttack, ERC721 {

	mapping (uint => address) pokemonApprovals;

	function balanceOf(address _owner) external view returns (uint256) {
		return ownerPokemonCount[_owner];
	}

	function ownerOf(uint _tokenId) external view returns (address) {
		return pokemonToOwner[_tokenId];
	}

	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		require(_to != address(0));
		require(_to != address(this));
		ownerPokemonCount[_to] = ownerPokemonCount[_to].add(1);
		ownerPokemonCount[_from] = ownerPokemonCount[_from].sub(1);
		pokemonToOwner[_tokenId] = address(uint160(_to));
		emit Transfer(_from, _to, _tokenId);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
		require(pokemonToOwner[_tokenId] == msg.sender || pokemonApprovals[_tokenId] == msg.sender);
		_transfer(_from, _to, _tokenId);
	}

	function approve(address _approved, uint256 _tokenId) external payable ownerOfPokemon(_tokenId) {
		pokemonApprovals[_tokenId] = _approved;
		emit Approval(msg.sender, _approved, _tokenId);
	}

}