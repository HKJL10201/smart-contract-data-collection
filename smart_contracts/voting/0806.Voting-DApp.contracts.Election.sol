pragma solidity >=0.4.22 <0.8.0;

contract Election{
    //modeliraj kandidat
    //store candidates
    //fetch candidate
    //store candidates count


    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    uint public candidatesCount;
    // _name meanigng local variable

    mapping(uint => Candidate) public candidates; // vaka ke gi zacuvuvame kandidatite
    //preku toa sto ocekuva key (id) i value Candidate, a so toa sto e public solidity pravi getter funkcija za kandidatite

    //koga dodavame kandidat komunucirame so blockchainot
    constructor() public{
        addCandidate("Zaev");
        addCandidate("Mickovski");
        // treba da sledime kolku glasovi dobiva kandidatot
        //da gi referencirame kandidatiet po id
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
    }




}
// web3.eth.getAccounts(); our woters will be the accounts