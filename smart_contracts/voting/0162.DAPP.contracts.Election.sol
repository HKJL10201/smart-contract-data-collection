 pragma solidity 0.4.20;

 contract Elections {

 uint nbtotvot;
 uint nbtotcand;

// solidity par conventions chaque nom d'attribut de fonction commence par un _
  struct Votant{
    string id;
  }

 struct Candidat{
   bytes32 nom;
   bytes32 parti;
   uint id;
   uint nbvotes;
 }

 mapping(uint => Candidat) candidats;
 mapping(address => bool) votants;

 function AjoutCandidat(bytes32 nom, bytes32 parti, uint id) private
 {
   nbtotcand++;
   candidats[id] = Candidat(nom,parti,id,0);
 }

 function Election () public {
     AjoutCandidat("MACRON", "EN MARCHE",1);
     AjoutCandidat("LE PEN","FRONT NATIONAL",2);
 }

 function Vote(uint idcand) public {
   require(!votants[msg.sender]);
   if (candidats[idcand].id==idcand){
     votants[msg.sender] = true;
     candidats[idcand].nbvotes++;
     nbtotvot++;
   }
 }

 function getNumOfCandidates() public view returns(uint) {
     return nbtotcand;
 }

 function getCandidate(uint candidateID) public view returns (uint,bytes32, bytes32, uint) {
     return (candidateID,candidats[candidateID].nom,candidats[candidateID].parti, candidats[candidateID].nbvotes);
 }

 }
