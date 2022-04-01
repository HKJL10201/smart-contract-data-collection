pragma solidity 0.4.25;

contract Election {
    // Modèle d'un candidat
    struct Candidate {
        uint id;
        string matricule;
        bytes32 name;
        bytes32 fname;
        bytes32 date;
        string adresss;
        bytes32 email;
        bytes32 poste;
        uint voteCount;
    }
    // Modèle d'un électeur
    struct Electeur {
        uint id;
        string matricule_ele;
        string email;
        string password;
    }
    // L'état des élections
    struct ElectionState {
        uint id;
        uint election_state;
    }

    // Stocker les comptes qui ont déja voté 
    mapping(address => uint) public voters;
    
    // Stocker les candidats
    mapping(uint => Candidate) public candidates;
    // Stocker les candidats
    mapping(uint => Electeur) public electeurs;

    // Stocker l'état des élection
    mapping(uint => ElectionState) public electionState;
    
    // Stocker le nombres de voie pour chaque candidat
    uint public candidatesCount;
    uint public electeursCount;

    //Déclancher  l'évenement de vote 
    event votedEvent (
        uint indexed _candidateId
    );

    
    event candidateAddedEvent();
    event electeurAddedEvent();
    event electionInitEvent();

    constructor () public {

        addElecteur("admin","admin@gmail.com","admin");
        initState(0);

   }

    function addCandidate (string _matricule,bytes32 _name,bytes32 _fname,bytes32 _date,string _adresss, bytes32 _email,bytes32 _poste) public {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,_matricule,_name,_fname,_date,_adresss,_email,_poste, 0);

        // Déclancher l'évenement de l'ajout d'un candidat a la blockchain
        emit candidateAddedEvent();
    }
    function addElecteur( string matricule_ele,string email,string password )public{
        electeursCount++;
        electeurs[electeursCount]= Electeur(electeursCount,matricule_ele ,email,password);

        // Déclancher l'évenement de l'ajout d'un électeur a la blockchain
        emit electeurAddedEvent();
    }

    function initState(uint _state)public{
        electionState[1] = ElectionState(1,_state);

        // L'évenement du déployement du contrat
        emit electionInitEvent();
    }

    function vote (uint _candidateId) public {
        // Vérifier s'ils n'ont pas voté avant
        require(voters[msg.sender] == 0);

        // exiger un candidat valide
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // Vérifier si un électeur a voté
        voters[msg.sender] = _candidateId;

        // La mise à jour de compte des vote
        candidates[_candidateId].voteCount ++;

        
        emit votedEvent(_candidateId);
    }
}
