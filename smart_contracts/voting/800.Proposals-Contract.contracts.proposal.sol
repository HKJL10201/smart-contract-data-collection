// SPDX-License-Identifier: MIT
import "contracts/wrap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract Propuestas is Ownable {
    struct Propuesta {
        string descripcion;
        uint256 votosPositivos;
        uint256 votosNegativos;
        mapping(address => bool) votantes;
    }

    uint256 public constant MIN_VOTOS = 3;
    uint256 public constant MIN_TIEMPO_VOTACION = 10 minutes;
    uint256 public numPropuestas;
    mapping(uint256 => Propuesta) public propuestas;

    function crearPropuesta(string memory _descripcion) public onlyOwner {
        require(
            numPropuestas < 2,
            "Solo se pueden tener hasta 2 propuestas activas a la vez"
        );
        numPropuestas++;
        propuestas[numPropuestas] = Propuesta(_descripcion, 0, 0);
    }

    function obtenerPropuestas() public view returns (string[] memory) {
        string[] memory listaPropuestas = new string[](numPropuestas);
        for (uint256 i = 1; i <= numPropuestas; i++) {
            listaPropuestas[i - 1] = propuestas[i].descripcion;
        }
        return listaPropuestas;
    }

    function votar(uint256 _idPropuesta, bool _voto) public {
        require(msg.sender != owner(), "El owner no puede votar");
        require(
            propuestas[_idPropuesta].votantes[msg.sender] == false,
            "Ya has votado en esta propuesta"
        );
        require(
            WrapToken.balanceOf(msg.sender) >= 1,
            "No tienes suficientes Wrap Tokens para votar"
        );

        propuestas[_idPropuesta].votantes[msg.sender] = true;

        if (_voto) {
            propuestas[_idPropuesta].votosPositivos++;
        } else {
            propuestas[_idPropuesta].votosNegativos++;
        }

        if (
            propuestas[_idPropuesta].votosPositivos +
                propuestas[_idPropuesta].votosNegativos ==
            MIN_VOTOS
        ) {
            propuestas[_idPropuesta].tiempoVotacion = block.timestamp;
        }
    }

    function cerrarVotacion(uint256 _idPropuesta) public onlyOwner {
        require(
            propuestas[_idPropuesta].votosPositivos +
                propuestas[_idPropuesta].votosNegativos >=
                MIN_VOTOS,
            "La votacion debe tener al menos 3 votos"
        );
        require(
            block.timestamp >=
                propuestas[_idPropuesta].tiempoVotacion + MIN_TIEMPO_VOTACION,
            "La votacion no ha alcanzado el tiempo minimo"
        );

        if (
            propuestas[_idPropuesta].votosPositivos >
            propuestas[_idPropuesta].votosNegativos
        ) {
            // Resolución positiva
            //      TO DO: agregar lógica para la resolución positiva
        } else {
            // Resolución negativa
            // TO DO: agregar lógica para la resolución negativa
        }

        // Reiniciar propuesta
        delete propuestas[_idPropuesta];
        numPropuestas--;
    }
}
