pragma solidity ^0.5.0;

contract Election {

    event Vote(string candidateName, uint voteCount);
    event res(string candidateName, uint voteCount);
    event NewCandidate(string candidateName);
    event Newvoter(string voterName);

    struct Candidate {
        string name;
        uint voteCount;
        string first_name;
    }
    struct Voter {

        bool voted;
        uint vote;
        bool ins;
        uint id;
    }
   
     struct citizen {

        bytes32 nameCa;
        bytes32 first_nameCa;
        bytes32 wilayaCa;
        bytes32 code;
        bool insc;
    }

    mapping(uint => citizen) private citizens;
    uint public totalVotes;
    Candidate[] public candidates;
    mapping(address => Voter) public voters;
    address private owner;
    uint public datef ;
    uint public datef2 ;
    uint public datef3;


    constructor() public {
     //  owner = msg.sender;
         
       datef = now +400;
       datef2 =datef + 200;
       datef3 = datef2 + 200;


       add1(1111,"benmeddah","mohamed","blida");
       add1(1112,"benmeddah","yacin","blida");
       add1(1113,"hamzi","khaled","alger");
       
       add2(1114,"bouzian","smain","blida",1234);
       add2(1115,"bodiaf","mohamed","blida",12340);
       add2(1116,"kobi","rabah","blida",123400);
       add2(1117,"zbayer","ahmed","blida",1234000);
   

      
    }
    
    function add1(uint id, string memory n,  string memory fn, string memory w) private{

        citizens[id]=citizen(keccak256(abi.encode(n)),keccak256(abi.encode(fn)),keccak256(abi.encode(w)),0,false);
        
    }
      function add2(uint id, string memory n,  string memory fn, string memory w, uint c) private{

        citizens[id]=citizen(keccak256(abi.encode(n)),keccak256(abi.encode(fn)),keccak256(abi.encode(w)),keccak256(abi.encode(c)),false);
        
    }

    function getNumCandidate() public view returns (uint) {
        return candidates.length;
    }

    function addCandidate(uint  _id,string memory _name,string memory _first_name,string memory _wilaya,uint  _code)  public {

      require(timeSub1(),"Phase d'inscription terminée");
      require(testStr2(_id,_name,_first_name,_wilaya),"Ereur syntaxe");
      require(!voters[msg.sender].ins,"Vous étes déja inscrit");
      require(!citizens[_id].insc,"Vous étes déja inscrit avec une autre adresse");
      require(citizens[_id].nameCa == keccak256(abi.encode(_name)),"Votre nom ou votre ID est invalide");
      require(citizens[_id].first_nameCa == keccak256(abi.encode( _first_name)),"Votre prénom est invalide");
      require(citizens[_id].wilayaCa == keccak256(abi.encode(_wilaya)),"Votre adresse est invalide");
      require(citizens[_id].code == keccak256(abi.encode(_code)),"Votre code est invalide");
        
        citizens[_id].insc= true;
        voters[msg.sender].ins= true;
        candidates.push(Candidate(_name, 0, _first_name));
        emit NewCandidate(_name);
       
    }

    function addVoter(uint  _id,string memory _name,string memory _first_name,string  memory _wilaya)  public  {
       
       require(timeSub2(),"Phase d'inscription terminée");
       require(testStr2(_id,_name,_first_name,_wilaya),"Erreur syntaxe");
       require(!voters[msg.sender].ins,"Vous étes déja inscrit ");
       require(!citizens[_id].insc,"Vous étes deja incrit avec une autre adresse");
       require(citizens[_id].nameCa == keccak256(abi.encode(_name)),"Votre nom ou votre ID est invalide");
       require(citizens[_id].first_nameCa == keccak256(abi.encode( _first_name)),"Votre prénom est invalide");
       require(citizens[_id].wilayaCa == keccak256(abi.encode(_wilaya)),"Votre code est invalide");
       require(!voters[msg.sender].voted);
      
         citizens[_id].insc= true;
         voters[msg.sender].ins= true;
         emit Newvoter(_name);
     
    }

    function vote(uint _candidate) public {
       
        require(timeVote(),"Phase du vote terminée");
        require(_candidate >= 0);
        require(voters[msg.sender].ins, "Vous n'etes pas autorisé a voter");
        require(!voters[msg.sender].voted, "Vous avez déja voter");
        require(_candidate < candidates.length, "Candidat invalide");

        voters[msg.sender].vote = _candidate;
        voters[msg.sender].voted = true;
        candidates[_candidate].voteCount += 1;
        totalVotes += 1;
        emit Vote(candidates[_candidate].name, candidates[_candidate].voteCount);
    }
    
    function result()  public view returns(string memory, string memory, uint ){
       // require(timeResult());
        require(candidates.length>0);
       
        uint v=0;
        uint p;
        for(uint l=0;l<candidates.length;l++){
            if(candidates[l].voteCount>v) {v=candidates[l].voteCount; p=l;   } 
    }

        return (candidates[p].name,candidates[p].first_name,candidates[p].voteCount);
        
    }
    
    function timeSub1 () view public returns(bool) 
    {
        if(now < datef ) return true;
        else return false;
        
    }
    
    function timeSub2 () view public returns(bool) 
    {
        if(now< datef2) return true;
        else return false;
    }
    
       function timeVote () view public returns(bool) 
    {
        if((now < datef3)&&(now > datef2) ) return true;
        else return false;
    }
     
        function timeResult () view public returns(bool) 
    {
        if(now > datef3)  return true;
        else return false;
    }


   function testStr(uint _str,string memory _str1,string memory _str2,string memory _str3,uint _c) public pure returns (bool){
    uint  b = _str;
    uint bb= _c;
    bytes memory b1 = bytes(_str1);
    bytes memory b2= bytes(_str2);
    bytes memory b3 = bytes(_str3);
    if((b <= 0 )||(b1.length == 0)||(b2.length == 0)||(b3.length == 0)||(bb <= 0)) return false;
    
      for(uint i0; i0<b1.length; i0++){
        bytes1 char = b1[i0];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }
    
      for(uint i0; i0<b2.length; i0++){
        bytes1 char = b2[i0];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }
    
      for(uint i0; i0<b3.length; i0++){
        bytes1 char = b3[i0];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }

    return true;
  }
       

    function testStr2(uint _str,string memory _str1,string memory _str2,string memory _str3) public pure returns (bool){
         
          uint  b = _str;
          bytes memory b1 = bytes(_str1);
          bytes memory b2= bytes(_str2);
          bytes memory b3 = bytes(_str3);
        
          if((b <= 0 )||(b1.length == 0)||(b2.length == 0)||(b3.length == 0)) return false;

    
    
      for(uint i0; i0<b1.length; i0++){
        bytes1 char = b1[i0];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }
    
      for(uint i0; i0<b2.length; i0++){
        bytes1 char = b2[i0];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }
    
      for(uint i0; i0<b3.length; i0++){
        bytes1 char = b3[i0];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x2E) //.
        )
            return false;
    }

    return true;
}

}
