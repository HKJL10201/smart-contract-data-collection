// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract DatosUsuarios {

    struct Usuario {
        string nombre;
        uint edad;
        string nickInstagram;
        string nickTwitter;
    }

   mapping(address => Usuario) private listaDatosUsuarios;

   function registrar(string memory nombre, uint edad, string memory nickInstagram, string memory nickTwitter) public {
        Usuario storage _usuario = listaDatosUsuarios[msg.sender];
        
        _usuario.nombre = nombre;
        _usuario.edad = edad;
        _usuario.nickInstagram = nickInstagram;
        _usuario.nickTwitter = nickTwitter;
   }

   function consultar() public view returns(Usuario memory){
    return listaDatosUsuarios[msg.sender];
   }

   function borrar() public {
    delete listaDatosUsuarios[msg.sender];
   }
}