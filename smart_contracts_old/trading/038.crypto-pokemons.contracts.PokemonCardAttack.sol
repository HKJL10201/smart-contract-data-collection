pragma solidity >=0.5.0 <0.6.0;

import "./PokemonCardHelper.sol";

contract PokemonCardAttack is PokemonCardHelper {

    uint randNonce = 0;
    event PokemonBattle(uint pokemonId1, uint pokemonId2, uint[] turns, uint8[] whosTurn);

    function randMod(uint _modulus) internal returns(uint) {
        randNonce = randNonce.add(1);
        return uint(keccak256(abi.encodePacked(block.number, msg.sender, randNonce))) % _modulus;
    }

    function sub(uint a, uint b) internal pure returns (uint){
        if (a >= b) {
            return a - b;
        }
        else {
            return 0;
        }
    }

    function abs(uint a, uint b) internal pure returns (uint) {
        if (a >= b) {
            return a - b;
        }
        else {
            return b - a;
        }
    }

	function attack(uint _pokemonId, uint _enemyPokemonId) external returns(uint){
		require(msg.sender == pokemonToOwner[_pokemonId] || msg.sender == _pokemonToSharee[_pokemonId], "must own or share the pokemon");
        require(!isPregnant(_pokemonId), "can't attack with a Pregnant Pokemon");
        require(pokemonToOwner[_enemyPokemonId] != msg.sender, "can't attack your own Pokemon");
		Pokemon storage myPokemon = pokemons[_pokemonId];
		Pokemon storage enemyPokemon = pokemons[_enemyPokemonId];
		uint rand;
		uint outlevel = abs(myPokemon.level, enemyPokemon.level);
		require(outlevel < 5);

		uint my_damage = myPokemon.baseStats.attack / 10 * 3 + sub(myPokemon.baseStats.attack, enemyPokemon.baseStats.defense);
		uint enemy_damage = enemyPokemon.baseStats.attack / 10 * 3 + sub(enemyPokemon.baseStats.attack, myPokemon.baseStats.defense);
		uint my_hp = myPokemon.baseStats.hp;
		uint enemy_hp = enemyPokemon.baseStats.hp;

		uint[] memory turns = new uint[](25);
		uint8[] memory whosTurn = new uint8[](25);
		uint counter = 0;

		while (my_hp > 0 && enemy_hp > 0) {
			// Determine which pokemon goes first using speed attribute
			if (myPokemon.baseStats.speed > enemyPokemon.baseStats.speed) {
				rand = randMod(500);
				if (rand > enemyPokemon.baseStats.speed){
					enemy_hp = sub(enemy_hp, my_damage);
					turns[counter] = my_damage;
					whosTurn[counter] = 1;
					if (enemy_hp == 0) {
						break;
					}
				} else {
					turns[counter] = 0;
					whosTurn[counter] = 1;
				}
				counter = counter.add(1);

				rand = randMod(500);
				if (rand > myPokemon.baseStats.speed) {
					my_hp = sub(my_hp, enemy_damage);
					turns[counter] = enemy_damage;
					whosTurn[counter] = 2;
					if (my_hp == 0) {
						break;
					}
				} else {
					turns[counter] = 0;
					whosTurn[counter] = 2;
				}
				counter = counter.add(1);
			} else {
				rand = randMod(500);
				if (rand > myPokemon.baseStats.speed) {
					my_hp = sub(my_hp, enemy_damage);
					turns[counter] = enemy_damage;
					whosTurn[counter] = 2;
					if (my_hp == 0) {
						break;
					}
				} else {
					turns[counter] = 0;
					whosTurn[counter] = 2;
				}
				counter = counter.add(1);

				rand = randMod(500);
				if (rand > enemyPokemon.baseStats.speed){
					enemy_hp = sub(enemy_hp, my_damage);
					turns[counter] = my_damage;
					whosTurn[counter] = 1;
					if (enemy_hp == 0) {
						break;
					}
				} else {
					turns[counter] = 0;
					whosTurn[counter] = 1;
				}
				counter = counter.add(1);
			}
		}

		if (enemy_hp == 0) {
			if (isPregnant(_enemyPokemonId)) {
				abortBirth(_enemyPokemonId);
			}
			levelUp(_pokemonId);
			emit PokemonBattle(_pokemonId, _enemyPokemonId, turns, whosTurn);
			return _pokemonId;
		} else {
			emit PokemonBattle(_pokemonId, _enemyPokemonId, turns, whosTurn);
			return _enemyPokemonId;
		}

		
	}
}
