    pragma solidity ^0.4.11;
    // We have to specify what version of compiler this code will compile with

    contract Voting {
        /* Mapping field below is equivalent to an associative array or hash.
        The key of the mapping is candidate name stored as type bytes32 and value is
        an unsigned integer to store the vote count
        */
        mapping (bytes32 => uint8) public votesReceived;
        // TODO: Renombrar este att, da confusion
        uint8 public blankVotes;

        /* List of voters. Prevent a user from voting more than once and register who can vote
        */
        struct registrationData {
        bool exists;
        bool voted;
        uint timestamp;
        }
        mapping (address => registrationData) public votersRegistration;
        address[] public voters;


        /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
        We will use an array of bytes32 instead to store the list of candidates
        */
        struct candidateData {
        bool exists;
        bytes32 name;
        bytes32 description;
        }
        mapping (bytes32 => candidateData) public candidateList;
        bytes32[] public politicalNames;

        uint public startTimestamp;
        uint public endTimestamp;




        // ["PP", "PSOE"], ["Jose", "Paco"], ["Des1", "Des2"], ["0xc9531cc2919daa4be9bf4b77fa1d4ee1307ed0bd","0x5f01c807165007ea15363cde47f6431379023d79","0xbE443Dfd767Ab1275a031faA5E513B3bA398A2ea"], 1511395505, 1514206188


        // ---> TODO: Candidato con hash, nombre, descripción, etc. (struct)
        // ---> TODO: Guardar lista del censo electoral (constructor)
        // ---> TODO: Guardar lista de los que han votado (booleano en el censo)
        // ---> TODO: Guardar la hora que ha votado
        // ---> TODO: Function ¿estoy en el censo?
        // ---> TODO: Function ¿he votado?
        // ---> TODO: Permitir voto en blanco
        // ---> TODO: Devolver informacion de candidatos
        // TODO: Liberar resultados cuando voten todos (Programa externo)

        /* This is the constructor which will be called once when you
        deploy the contract to the blockchain. When we deploy the contract,
        we will pass an array of candidates who will be contesting in the election
        */
        function Voting(bytes32[] politicalParties, bytes32[] candidateNames, bytes32[] candidateDescriptions, address[] votersAddress, uint start, uint end) {
            startTimestamp = start;
            endTimestamp = end;
            politicalNames = politicalParties;
            voters = votersAddress;

            for(uint i = 0; i < politicalParties.length; i++) {
                candidateList[politicalParties[i]].exists = true;
                candidateList[politicalParties[i]].name = candidateNames[i];
                candidateList[politicalParties[i]].description = candidateDescriptions[i];
            }

            for(uint j = 0; j < votersAddress.length; j++) {
                votersRegistration[votersAddress[j]].exists = true;
                votersRegistration[votersAddress[j]].voted = false;
            }
        }

        // Métodos para los partidos políticos
        function getPoliticalCount() public returns(uint count) {
            return politicalNames.length;
        }

        function getPoliticalAtIndex(uint row) public returns (bytes32, bytes32, bytes32) {
            if(candidateList[politicalNames[row]].exists != true) {
                revert();
            }
            return (politicalNames[row], candidateList[politicalNames[row]].name, candidateList[politicalNames[row]].description);
        }

        // Métodos para extraer el censo
        function getVotersCount() public returns(uint count) {
            return voters.length;
        }

        function getVotersAtIndex(uint row) public returns (address, bool, uint) {
            if(votersRegistration[voters[row]].exists != true) {
                revert();
            }
            return (voters[row], votersRegistration[voters[row]].voted, votersRegistration[voters[row]].timestamp);
        }

        // Métodos para votar
        // This function increments the vote count for the specified candidate. This
        // is equivalent to casting a vote
        function voteForCandidate(bytes32 candidate) public returns (bool) {
            if(validateTimestamp() == false) {
                revert();
            }

            // Check if candidate exists
            if (validCandidate(candidate) == false){
                revert();
            }

            if(iAmRegistered(msg.sender) == false) {
                revert();
            }

            if(iVoted(msg.sender) == true) {
                revert();
            }

            // Vote and mark voted for address
            votesReceived[candidate] += 1;
            votersRegistration[msg.sender].voted = true;
            votersRegistration[msg.sender].timestamp = now;
            return true;
        }

        function blankVote() returns (bool) {
            if(validateTimestamp() == false) {
                revert();
            }

            if(iAmRegistered(msg.sender) == false) {
                revert();
            }

            if(iVoted(msg.sender) == true) {
                revert();
            }

            blankVotes++;
            votersRegistration[msg.sender].voted = true;
            votersRegistration[msg.sender].timestamp = now;
            return true;
        }

        // Métodos para consulta propia
        // Returns true if the address is registered
        function iAmRegistered(address sender) public returns (bool){
            if(votersRegistration[sender].exists == true) {
                return true;
            }
            return false;
        }

        // Returns true if the address voted
        function iVoted(address sender) public returns (bool){
            if(votersRegistration[sender].voted == true) {
                return true;
            }
            return false;
        }

        // Utils
        function validateTimestamp() private returns (bool) {
            if(startTimestamp < now && endTimestamp > now) {
                return true;
            } else {
                return false;
            }
        }

        function validCandidate(bytes32 politicalParty) internal returns (bool) {
            if(candidateList[politicalParty].exists == true) {
                return true;
            }
            return false;
        }

        function simulateVote(address sender, bytes32 candidate) public returns (bool){
            if(validateTimestamp() == false) {
                revert();
            }

            // Check if candidate exists
            if (validCandidate(candidate) == false){
                revert();
            }

            if(iAmRegistered(sender) == false) {
                revert();
            }

            if(iVoted(sender) == true) {
                revert();
            }

            // Vote and mark voted for address
            votesReceived[candidate] += 1;
            votersRegistration[sender].voted = true;
            votersRegistration[sender].timestamp = now;
            return true;
        }

        function simulateBlankVote(address sender) public returns (bool) {
            if(validateTimestamp() == false) {
                revert();
            }

            if(iAmRegistered(sender) == false) {
                revert();
            }

            if(iVoted(sender) == true) {
                revert();
            }

            blankVotes++;
            votersRegistration[sender].voted = true;
            votersRegistration[sender].timestamp = now;
            return true;
        }


    }


    // Crear 3 cuentas en cada wallet