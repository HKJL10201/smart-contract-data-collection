pragma solidity ^0.4.17;

contract Votacion {
    // Variables
    address public managerElectoral; // Cuenta para Comite Electoral
    address public managerTribunal; // Cuenta para Tribunal Electoral

    mapping(address => uint8) participantes; // Alumnos quienes podran votar

    struct Contendiente { // Estructura que representa a una candidatura
      uint8 id;
      string nombreCandidatura;
      uint16 votos;
    }

    Contendiente[] candidatos; // Arreglo de candidaturas contendientes

    bool votacionEnCurso; // Booleano que expresa si la votacion esta abierta o
                          // no

    bool resultadosPublicos; // Booleano que expresa si los resultados de la
                             // votacion estan publicos o no

    function getParticipanteStatus(address _participante) public view returns (uint8) {
      return participantes[_participante];
    }


    function Votacion(address mgTribunal, address[] parts, string[] contendientes) public {
        managerElectoral = msg.sender;
        managerTribunal = mgTribunal;
        for (uint i = 0; i < parts.length; i++) {
            participantes[parts[i]] = 1;
        }
        candidatos[0] = Contendiente({id:0,nombreCandidatura:"Nulo",votos:0});
        for (uint8 j = 0; j < contendientes.length; j++) {
            if(j == 0){
                candidatos[j] = Contendiente({id:j,nombreCandidatura:"Nulo",votos:0});
            } else {
                candidatos[j] = Contendiente({id:j,nombreCandidatura:contendientes[j-1],votos:0});
            }
        }
    }

    function getCandidatos() public view returns (Contendiente[]){
        return candidatos;
    }

    function iniciarVotacion() public soloElectoral {
        votacionEnCurso = true;
    }

    function terminarVotacion() public soloElectoral{
        votacionEnCurso = false;
    }

    function altaImpugnaciones(uint8[] impugnaciones) public soloTribunal {
        for (uint i = 0; i < candidatos.length; i++) {
            candidatos[i].votos *= 1 - impugnaciones[i];
        }
    }

    function bajaAltaCuenta(address pkViejo, address pkNuevo) public soloElectoral {
        delete participantes[pkViejo];
        participantes[pkNuevo] = 1;
    }

    function recliclarContrato(address[]pkViejos, address[]pkNuevos) public soloElectoral{
        for (uint i = 0; i < pkViejos.length; i++) {
            delete participantes[pkViejos[i]];
        }

        for (uint j = 0; j < pkNuevos.length; j++) {
            participantes[pkNuevos[j]] = 0; // El "0" sera usado para expresar
                                            // que el usuario aun no ha votado
        }
    }

    function votar(uint voto) public payable soloParticipantesQueNoHanVotado {
        require(msg.value > .1 ether);
        candidatos[voto].votos += 1;
    }

    function publicarVotacion() public soloElectoral {
        resultadosPublicos = true;
    }

    modifier soloElectoral(){
        require(msg.sender == managerElectoral);
        _;
    }

    modifier soloTribunal(){
        require(msg.sender == managerTribunal);
        _;
    }

    modifier soloParticipantesQueNoHanVotado(){
        // Validar que participante exista y no haya votado
        require(getParticipanteStatus(msg.sender) == 1);
        _;
    }
}
