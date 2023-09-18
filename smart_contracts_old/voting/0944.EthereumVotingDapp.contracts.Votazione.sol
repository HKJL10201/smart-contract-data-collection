pragma solidity ^0.4.24;

contract Votazione {
    
    // Elettore è un tipo complesso che rappresenta un elettore
    // (cioè un utente votante) che contiene le variabili 
    // necessarie.
    struct Elettore {        
        bool votato;  // vero = l'elettore ha già votato
        uint indice_candidato;   // indice del candidato votato
        bool autorizzato; // vero = avente diritto di voto    
    }


    // Candidato è un tipo complesso che rappresenta un
    // candidato votabile da un elettore 
    struct Candidato {        
        string nome_candidato;   // nome del candidato
        uint conteggio_voti; // numero di voti raccolti    
    }
    
    
    // indirizzo del proprietario del contratto cioè
    // di colui che lo andrà a creare nella blockchain (deploying)
    address public proprietario;


    // associa ad ogni chiave address inserita una relativa
    // struct Elettore
    mapping(address => Elettore) public info_elettore;
    
    // Controllo è un tipo complesso che contiene dati di controllo
    struct Controllo {
        bool votazioni_aperte;
        bool candidati_bloccati;
        bool risultato_visibile;
        int totale_voti;
        int numero_elettori;
        int numero_candidati;
    }
    Controllo public info;

     
    
    // Array (di dimensioni dinamiche) di tipo struct Candidato
    // contenente tutti i candidati richiamati dall'indice
    // (candidati_e_voti è visibile ma inizialmente è vuoto)
    //
    // array_di_candidati verrà copiato in candidati_e_voti alla
    // chiusura delle votazioni, rendendo visibile questo struct
    Candidato[] private array_di_candidati;
    Candidato[] public candidati_e_voti;


    // evento che conferma che il voto è avvenuto
    event Success(bool _status, string cand);

    // Costruttore
    constructor() public {
        
        // L'indirizzo pubblico del proprietario del contratto viene
        // qui memorizzato nella variabile proprietario
        proprietario = msg.sender;

        // disabilita la votazione per tutti i votanti
        info.votazioni_aperte = false;


        // sblocca l'inserimento di nuovi candidati
        info.candidati_bloccati = false;

        // nasconde il risultato delle votazioni
        info.risultato_visibile = false;

        // i voti totali inizialmente sono pari a zero
        info.totale_voti = 0;

        // il numero di elettori e di candidati inizialmente è zero
        info.numero_elettori = 0;
        info.numero_candidati = 0;

    }


    
    // Questa funzione crea un nuovo oggetto Candidato 
    // aggiungendolo alla fine dell'array array_di_candidati
    //
    // Ad ogni candidato viene associato un numero di indice
    function aggiungi_candidato (string _candidato) public {

        // La funzione viene terminata se il chiamante
        // non è il proprietario
        require (msg.sender == proprietario);

        // Termina se l'inserimento di nuovi candidati è stato bloccato
        require (!info.candidati_bloccati);
        
        // Viene aggiunto all'array array_di_candidati il nuovo candidato
        // col nome passato dalla funzione.
        // Il candidato avrà inizialmente zero voti
        array_di_candidati.push (   
            Candidato({
                nome_candidato: _candidato,
                conteggio_voti: 0
            }) 
        );
        
        // Aggiorna la variabile pubblica info.numero_candidati prelevandola
        // dal parametro lenght della array privato array_di_candidati
        info.numero_candidati = int256 (array_di_candidati.length);
    }
 
    function avvia_votazioni () public {
       
        // La funzione viene terminata se il chiamante
        // non è il proprietario
        require (msg.sender == proprietario);

        // Termina se le votazioni sono già avviate
        require (!info.votazioni_aperte);

        // Termina se le votazioni erano state già avviate e chiuse
        // non è possibile riaprire le votazioni una volta chiuse
        // (se candidati_bloccati è true, significa che erano già
        // state avviate le votazioni in precedenza)
        require (!info.candidati_bloccati);
 
        // Blocca l'inserimento di nuovi candidati
        info.candidati_bloccati = true;

        // Abilita le votazioni per tutti i votanti
        info.votazioni_aperte = true;
    }

    function chiudi_votazioni () public {

        // La funzione viene terminata se il chiamante
        // non è il proprietario
        require (msg.sender == proprietario);

        // Termina la funzione se le votazioni non erano aperte
        require (info.votazioni_aperte);
 
        // Disabilita le votazioni per tutti i votanti
        info.votazioni_aperte = false; 

        // Rendi visibili i risultati
        info.risultato_visibile = true;

        // Copia il contenuto non visibile dell'array array_di_candidati
        // nell'array pubblico candidati_e_voti
        candidati_e_voti = array_di_candidati;
    }


    // Questa funzione consente di dare il diritto di voto 
    // ad uno specifico indirizzo ethereum
    // Può essere chiamata solo dal proprietario
    function assegna_diritto_di_voto (address _elettore) public {
        
        // La funzione viene terminata se l'indirizzo
        // aveva già diritto di voto
        require (!info_elettore[_elettore].autorizzato);
        
        // La funzione viene terminata se il chiamante
        // non è il proprietario
        require (msg.sender == proprietario);
        
        // Imposta il diritto di voto per l'indirizzo _elettore
        // settando a vero la variabile autorizzato dell'oggetto
        // elettore
        info_elettore[_elettore].autorizzato = true;

        // Incrementa il numero totale di elettori
        info.numero_elettori += 1;
    }
 
 
    // Assegna un voto ad un candidato
    function vota_un_candidato (uint candidato_scelto) public {
     
        // Inserisce in sender un oggetto Elettore preso
        // dall'array "info_elettore" avente indice
        // pari all'indirizzo del chiamante della funzione.
        Elettore storage sender = info_elettore[msg.sender];
        
        // Termina la funzione se le votazioni non sono ancora aperte
        require(info.votazioni_aperte);
        
        // Termina la funzione se il votante ha già votato
        require(!sender.votato);
        
        // Termina se il votante non è autorizzato
        require(sender.autorizzato);
       
        // Imposta che questo elettore ha votato 
        // (non potrà votare di nuovo)
        sender.votato = true;
        
        // Imposta l'indice del candidato dell'oggetto Elettore
        // (omettere per rendere il voto anonimo)
        sender.indice_candidato = candidato_scelto;

        // Incrementa il numero di voti per il candidato con indice
        //"candidato scelto"
        array_di_candidati[candidato_scelto].conteggio_voti += 1;

        // Incrementa il conteggio dei voti totali
        info.totale_voti += 1;

        // conferma che il voto è stato assegnato e restituisce il nome del candidato
        emit Success(true, array_di_candidati[candidato_scelto].nome_candidato);
    } 
 
    
    // Restituisce il numero di indice del vincitore
    // "view" significa che non può modificare lo stato di nessuna variabile
    function indice_vincitore () public view returns (uint indice) {

        // Termina la funzione se il risultato deve restare nascosto
        require (info.risultato_visibile);

        // Scorre i voti di tutti i candidati e sovrascrive "voto_temporaneo"
        // se il relativo conteggio risultasse maggiore del precedente ciclo
        uint voto_temporaneo = 0;
        for (uint p = 0; p < array_di_candidati.length; p++) {
            if (array_di_candidati[p].conteggio_voti > voto_temporaneo) {
                voto_temporaneo = array_di_candidati[p].conteggio_voti;
                indice = p;
            }
        }
    }


    // Usa la funzione "indice_vincitore" per restituire il nome contenuto
    // nell'"array_di_candidati" (identificandolo con l'indice del vincitore)
    function nome_vincitore () public view returns (string n)
    {
        // Termina la funzione se il risultato deve restare nascosto
        require (info.risultato_visibile);

        // estrae il nome dall'oggetto array_di_candidati
        n = array_di_candidati[indice_vincitore()].nome_candidato;
    }

    // Restituisce il nome del candidato inserendo l'indice (getter)
    function nome_candidato_da_indice (uint i) public view returns (string nomecand) {
        // Se l'indice passato alla funzione è tra quelli presenti in memoria
        if (i<array_di_candidati.length){
            nomecand = array_di_candidati[i].nome_candidato;
        // Se l'indice passato è troppo grande
        } else {
            nomecand = "Nessun candidato in questo indice!";
        }
    }


    
}