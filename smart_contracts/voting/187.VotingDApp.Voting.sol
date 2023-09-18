pragma solidity ^0.6.6;

contract Election {

    struct Candidate{                                               // Stanovení parametrů kandidáta
        uint id;
        string name;
        uint voteCount;
    }

    mapping (uint => Candidate) public candidates;                  // Vytvoření funkcí pro parametry kandidáta     // mapping = propojení dvou datových struktur
    uint public candidatecount;                                     // Vytvoření proměnné počet kandidátů
    mapping (address => bool) public voter;

    event eventVote(
        uint indexed _candidateid
    );

    constructor() public{                                           // Spustí se, jakmile se náš smart contract zapíše do blockchainu Etherea
        addCandidate("Alice");
        addCandidate("Bob");
    }

    function addCandidate(string memory _name) private{
        candidatecount++;
        candidates[candidatecount] = Candidate(candidatecount, _name, 0);           //candidatecount se chová jako id kandidáta, protože jsme provedli 
                                                                                    //                                           mapping uint => Candidate na řádku 11


    }

    function vote(uint _candidateid) public{
            require(!voter[msg.sender]);                                            //funkce require - podmínka, že bool hodnota msg.sender nesmí být 0 -> aby nemohl uživatel hlasovat znovu
            require(_candidateid > 0 && _candidateid <= candidatecount);            //podmínka, že candidateid musí být větší než 0 a menší rovno počtu kandidátů

            voter[msg.sender] = true;                                               //pokud volič zkusí spustit tuto funkci ještě jednou, vrátí bool hodnotu msg.sender na 0 (true) -> nemůže znovu hlasovat
            candidates[_candidateid].voteCount ++;

            emit eventVote(_candidateid);
    }
}