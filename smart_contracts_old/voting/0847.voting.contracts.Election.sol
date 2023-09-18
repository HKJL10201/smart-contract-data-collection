pragma solidity >=0.4.22 <0.9.0;

contract Election {

  struct candidate { //Regle
    uint id;
    string name;
    string descriptif;
    uint voteCountPour;
    uint voteCountContre;
  }
  struct personne {
    uint id;
    string nom;
    string prenom;
    string sexe;
    string fonction;
    //candidate[] voterPourvar;
    //uint[] deCisionpour;
  }

    mapping(uint=>uint[]) public deCisionpour;
    mapping(uint=>uint[]) public deCisioncontre;

function getdeCisionpour(uint inte) public view returns(uint[] memory ){
  return deCisionpour[inte];
}

function getdeCisioncontre(uint inte) public view returns(uint[] memory ){
  return deCisioncontre[inte];
}
  //Person VAR
  uint public personCount;

  mapping(uint=>personne) public personnes;
  mapping(address => bool) public Inscrits;


  //*************END PERSON VAR


  //************************candidate VAR

//  mapping (uint=>string)mapping entier string = name de la regle
  mapping(uint=>address[]) votsPour;

  mapping(address => bool) public voters;

  mapping(uint=>candidate) public candidates;
  uint public candidatesCount; //Nbre de lois par la suite

  mapping(address =>uint[] ) public voterFor;

  mapping(address => mapping(uint256 => bool)) public votedPour;
      //relation between account and candidate
  mapping(address => mapping(uint256 => bool)) public votedContre;

  //*************END PERSON VAR

  //uint[] public tabIdCandidat = new uint[](7);
  uint[] public tabIdCandidat;
  uint[] public tabIdCandidatContre;


  //candidate[] tmpCandidate;

  // *************PERSON FUNCTION
  function getCandidatesCount() public returns(uint){
    return candidatesCount;
  }

  function InitializeTableau() public {
    delete tabIdCandidat;
  }

  event personEvent (
      uint indexed _candidateId
  );

  function getPersonCount() public returns(uint){
    return personCount;
  }

  function addPerson(string memory _nom,string memory _prenom, string memory _sexe, string memory _fonction) public returns (uint){

    require(!Inscrits[msg.sender]);
    personCount++;
    personnes[personCount] = personne(personCount, _nom,_prenom,_sexe,_fonction);//,tabIdCandidat
    Inscrits[msg.sender]=true;
    deCisionpour[personCount]=tabIdCandidat;
    deCisioncontre[personCount] = tabIdCandidatContre;
    delete tabIdCandidat;
    //delete tabIdCandidatContre;
    return personCount;

  }

  //******* END FUNCTION PERSON


  //************************candidate FUNCTION
  // voted event
  event votedEvent (
      uint indexed _candidateId
  );

  function addCandidate(string memory _name,string memory _descriptif) public {

      candidatesCount++;
      candidates[candidatesCount] = candidate(candidatesCount,_name,_descriptif,0,0);
  }

  function getVoters(uint _id) public view returns (address[] memory) {
        //require(msg.sender==_adress );
        return votsPour[_id];
    }

//on reecup le titre du candidat et on le push dans un tableau
  function votePour (uint _candidateId) public { //returns (bool) {

    require(!votedPour[msg.sender][_candidateId], "You already voted for this descision");
    require(!votedContre[msg.sender][_candidateId], "You already voted for this descision");

    require(_candidateId > 0 && _candidateId <= candidatesCount);
    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    candidates[_candidateId].voteCountPour ++;

    voterFor[msg.sender].push(_candidateId);

    tabIdCandidat.push(_candidateId);

    votsPour[_candidateId].push(msg.sender);

    votedPour[msg.sender][_candidateId] = true;
    // trigger voted event
    emit votedEvent(_candidateId);
    //return a_voter;
  }

  function voteContre (uint _candidateId) public {
    // require that they haven't voted before
    //require(!voters[msg.sender]);
    require(!votedPour[msg.sender][_candidateId], "You already voted for this descision");
    require(!votedContre[msg.sender][_candidateId], "You already voted for this descision");
    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);
    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    candidates[_candidateId].voteCountContre ++;
    //votedContre[msg.sender] = _candidateId;
    // trigger voted event

    tabIdCandidatContre.push(_candidateId);

    votedContre[msg.sender][_candidateId] = true;
    emit votedEvent(_candidateId);
  }
}