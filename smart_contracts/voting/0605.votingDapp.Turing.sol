// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Turing is ERC20{

    // Define se é possível ou não votar
    bool varEndVoting = false;

    // Var que guarda quem é o atual usuário do contrato
    address voterAddress;
    
    // Modificador que garante que uma dada função será chamada
    // apenas pela professora.
    // endereço da professora 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad
    // meu endereço 0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a
    address private teacherAddress = 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad;
    modifier onlyTeacher() {
        require(msg.sender == teacherAddress, "Esta funcao somente pode ser usada pela professora");
        _;
    }

    modifier onlyAutorized() {        
        require(bytes(addressToCodename[msg.sender]).length > 0, "Usuario nao autorizado");
        _;
    }

    modifier checkVarEndVoting() {
        require(varEndVoting == false, "Votacao foi finalizada");
        _;
    }

    // Lista de candidatos a serem votados
    mapping(string => address) public codenameToAddress;
    function fillCodenameToAddress () private {
        codenameToAddress["Andre"] = 0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6;
        codenameToAddress["Antonio"] = 0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6;
        codenameToAddress["Ratonilo"] = 0x5d84D451296908aFA110e6B37b64B1605658283f;
        codenameToAddress["eduardo"] = 0x500E357176eE9D56c336e0DC090717a5B1119cC2;
        codenameToAddress["Enzo"] = 0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8;
        codenameToAddress["Fernando"] = 0xFED450e1300CEe0f69b1F01FA85140646E596567;
        codenameToAddress["Juliana"] = 0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e;
        codenameToAddress["Altoe"] = 0x6701D0C23d51231E676698446E55F4936F5d99dF;
        codenameToAddress["Salgado"] = 0x8321730F4D59c01f5739f1684ABa85f8262f8980;
        codenameToAddress["Regata"] = 0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a;
        codenameToAddress["Luis"] = 0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33;
        codenameToAddress["Nicolas"] = 0x01fe9DdD4916019beC6268724189B2EED8C2D49a;
        codenameToAddress["Rauta"] = 0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1;
        codenameToAddress["Silva"] = 0xCAFE34A88dCac60a48e64107A44D3d8651448cd9;
        codenameToAddress["Sophie"] = 0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3;
        codenameToAddress["Thiago"] = 0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97;
        codenameToAddress["Brito"] = 0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f;
        codenameToAddress["ulopesu"] = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;
        codenameToAddress["Vinicius"] = 0x48cd1D1478eBD643dba50FB3e99030BE4F84d468;
        codenameToAddress["Bonella"] = 0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c;
    }

    // Checa se o codename é válido a ser votado
    function checkCodename(string memory codename) internal view {
        bool isAddress = codenameToAddress[codename] == address(codenameToAddress[codename]);
        require(isAddress, "O codinome passado ja foi votado ou nao e valido");
    }

    // Converte endereço em codenome
    mapping(address => string) public addressToCodename;
    function fillAddressToCodename () private {
        addressToCodename[0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6] = "Andre";
        addressToCodename[0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6] = "Antonio";
        addressToCodename[0x5d84D451296908aFA110e6B37b64B1605658283f] = "Ratonilo";
        addressToCodename[0x500E357176eE9D56c336e0DC090717a5B1119cC2] = "eduardo";
        addressToCodename[0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8] = "Enzo";
        addressToCodename[0xFED450e1300CEe0f69b1F01FA85140646E596567] = "Fernando";
        addressToCodename[0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e] = "Juliana";
        addressToCodename[0x6701D0C23d51231E676698446E55F4936F5d99dF] = "Altoe";
        addressToCodename[0x8321730F4D59c01f5739f1684ABa85f8262f8980] = "Salgado";
        addressToCodename[0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a] = "Regata";
        addressToCodename[0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33] = "Luis";
        addressToCodename[0x01fe9DdD4916019beC6268724189B2EED8C2D49a] = "Nicolas";
        addressToCodename[0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1] = "Rauta";
        addressToCodename[0xCAFE34A88dCac60a48e64107A44D3d8651448cd9] = "Silva";
        addressToCodename[0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3] = "Sophie";
        addressToCodename[0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97] = "Thiago";
        addressToCodename[0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f] = "Brito";
        addressToCodename[0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee] = "ulopesu";
        addressToCodename[0x48cd1D1478eBD643dba50FB3e99030BE4F84d468] = "Vinicius";
        addressToCodename[0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c] = "Bonella";
    }

    string[20] codenameList = ["Andre", "Antonio", "Ratonilo", "eduardo", "Enzo", "Fernando","Juliana", "Altoe", "Salgado", "Regata", "Luis", "Nicolas", "Rauta", "Silva", "Sophie", "Thiago", "Brito", "ulopesu", "Vinicius", "Bonella"];

    function getCodenameList () external view returns(string[20] memory){
        return codenameList;
    }

    // Mapa de votos dados por um dado codename a algum codename    
    mapping(string => mapping(string => bool)) public userBlockVote;
    function blockVoteOnCodename (string memory voter, string memory candidate) internal {
        userBlockVote[voter][candidate] = true;
    }
    function checkVoteOnCodename (string memory voter, string memory candidate) public view returns(bool) {
        return userBlockVote[voter][candidate];
    }
    function balanceOfCodename(string memory codename) external view returns(uint256) {
        return balanceOf(codenameToAddress[codename]);
    }
    function getUserAddress() external view returns(address) {
        return voterAddress;
    }
    function getUserCodeName() external view returns(string memory) {
        return addressToCodename[voterAddress];
    }
    function getTeacherCodeName() external view onlyTeacher returns(string memory) {
        return "Professora";
    }
    function isTeacher() external view returns(bool) {
        return msg.sender == teacherAddress;
    }

    constructor() ERC20("Turing", "TUR"){
        // Preenche lista de candidatos por codenome
        fillCodenameToAddress();

        // Preenche lista de mapeamento endereço -> codinome
        fillAddressToCodename();

        // Guarda quem é o usuário atual do contrato
        voterAddress = msg.sender;

    }

    // Cria a quantidade de saTurings na carteira do receptor dado como parametro.
    // Essa função apenas pode ser executada pela professora.
    function issueToken (address receiver, uint256 saTuringAmount) external onlyTeacher{
        _mint(receiver, saTuringAmount);
    }

    function vote (string memory codinome, uint256 saTuringAmount) external onlyAutorized checkVarEndVoting {
        
        // Consulta codinome do endereço do vontante (atual usário do contrato)
        string memory voter = addressToCodename[voterAddress];

        // Candidato não pode votar em si mesmo
        require (keccak256(bytes(voter)) != keccak256(bytes(codinome)), ("Usuario nao pode votar em si mesmo"));

        // Não se pode votar num usuário que nao exista
        //  require(bytes(codenameToAddress[codinome]).length > 0, "Codinome não encontrado");
        
        // Candidato não pode votar duas vezes num mesmo candidato
        require (!checkVoteOnCodename(voter, codinome), ("Usuario nao pode votar duas vezes no mesmo codinome"));
       
        // Uma vez que o candidato conseguiu votar em outro ele deve ser impossibilitado de votar nesse outro
        blockVoteOnCodename(voter, codinome);

        // Quantidade de turins não pode ser maior que 2 (neste caso 2*10^18 saTurings)
        require (saTuringAmount < 2*(10**(18)), "Quantidade de saTurings nao pode ser maior que 2 Turings");

        // Minting da quantidade de saTurings especificada, para o Addr associado ao codinome)
        address addrAssociado = codenameToAddress[codinome];
        _mint(addrAssociado, saTuringAmount);

        // A pessoa que vota também ganha 0,2 Turing
        _mint(msg.sender, 2*(10**(17)) );
    }

    function endVoting() external onlyTeacher{
        varEndVoting = true;
    }

    
}