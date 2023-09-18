// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Turing is ERC20{

    bool public votingFinished;

    mapping (string => address) public nameToAddress;
    mapping (address => string) public addressToString;

    mapping (address => mapping (address => bool)) private peopleVoted;

    constructor() ERC20("Turing", "TRG"){

        //inicializando mapping de codinome para endereço
        nameToAddress["Andre"]       = 0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6;
        nameToAddress["Antonio"]     = 0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6;
        nameToAddress["Ratonilo"]    = 0x5d84D451296908aFA110e6B37b64B1605658283f;
        nameToAddress["eduardo"]     = 0x500E357176eE9D56c336e0DC090717a5B1119cC2;
        nameToAddress["Enzo"]        = 0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8;        
        nameToAddress["Fernando"]    = 0xFED450e1300CEe0f69b1F01FA85140646E596567;
        nameToAddress["Juliana"]     = 0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e;
        nameToAddress["Altoe"]       = 0x6701D0C23d51231E676698446E55F4936F5d99dF;
        nameToAddress["Salgado"]     = 0x8321730F4D59c01f5739f1684ABa85f8262f8980;
        nameToAddress["Regata"]      = 0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a;
        nameToAddress["Luis"]        = 0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33;
        nameToAddress["Nicolas"]     = 0x01fe9DdD4916019beC6268724189B2EED8C2D49a;
        nameToAddress["Rauta"]       = 0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1;
        nameToAddress["Silva"]       = 0xCAFE34A88dCac60a48e64107A44D3d8651448cd9;
        nameToAddress["Sophie"]      = 0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3;
        nameToAddress["Thiago"]      = 0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97;
        nameToAddress["Brito"]       = 0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f;
        nameToAddress["ulopesu"]     = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;
        nameToAddress["Vinicius"]    = 0x48cd1D1478eBD643dba50FB3e99030BE4F84d468;
        nameToAddress["Bonella"]     = 0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c;

        //
        addressToString[0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6] = "Andre";
        addressToString[0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6] = "Antonio";
        addressToString[0x5d84D451296908aFA110e6B37b64B1605658283f] = "Ratonilo";
        addressToString[0x500E357176eE9D56c336e0DC090717a5B1119cC2] = "eduardo";
        addressToString[0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8] = "Enzo";
        addressToString[0xFED450e1300CEe0f69b1F01FA85140646E596567] = "Fernando";
        addressToString[0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e] = "Juliana";
        addressToString[0x6701D0C23d51231E676698446E55F4936F5d99dF] = "Altoe";
        addressToString[0x8321730F4D59c01f5739f1684ABa85f8262f8980] = "Salgado";
        addressToString[0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a] = "Regata";
        addressToString[0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33] = "Luis";
        addressToString[0x01fe9DdD4916019beC6268724189B2EED8C2D49a] = "Nicolas";
        addressToString[0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1] = "Rauta";
        addressToString[0xCAFE34A88dCac60a48e64107A44D3d8651448cd9] = "Silva";
        addressToString[0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3] = "Sophie";
        addressToString[0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97] = "Thiago";
        addressToString[0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f] = "Brito";
        addressToString[0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee] = "ulopesu";
        addressToString[0x48cd1D1478eBD643dba50FB3e99030BE4F84d468] = "Vinicius";
        addressToString[0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c] = "Bonella";

        //inicializando mapping de pessoas que um endereço ja votou
        peopleVoted[0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6][0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6] = true;
        peopleVoted[0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6][0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6] = true;
        peopleVoted[0x5d84D451296908aFA110e6B37b64B1605658283f][0x5d84D451296908aFA110e6B37b64B1605658283f] = true;
        peopleVoted[0x500E357176eE9D56c336e0DC090717a5B1119cC2][0x500E357176eE9D56c336e0DC090717a5B1119cC2] = true;
        peopleVoted[0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8][0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8] = true;
        peopleVoted[0xFED450e1300CEe0f69b1F01FA85140646E596567][0xFED450e1300CEe0f69b1F01FA85140646E596567] = true;
        peopleVoted[0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e][0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e] = true;
        peopleVoted[0x6701D0C23d51231E676698446E55F4936F5d99dF][0x6701D0C23d51231E676698446E55F4936F5d99dF] = true;
        peopleVoted[0x8321730F4D59c01f5739f1684ABa85f8262f8980][0x8321730F4D59c01f5739f1684ABa85f8262f8980] = true;
        peopleVoted[0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a][0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a] = true;
        peopleVoted[0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33][0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33] = true;
        peopleVoted[0x01fe9DdD4916019beC6268724189B2EED8C2D49a][0x01fe9DdD4916019beC6268724189B2EED8C2D49a] = true;
        peopleVoted[0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1][0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1] = true;
        peopleVoted[0xCAFE34A88dCac60a48e64107A44D3d8651448cd9][0xCAFE34A88dCac60a48e64107A44D3d8651448cd9] = true;
        peopleVoted[0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3][0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3] = true;
        peopleVoted[0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97][0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97] = true;
        peopleVoted[0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f][0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f] = true;
        peopleVoted[0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee][0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee] = true;
        peopleVoted[0x48cd1D1478eBD643dba50FB3e99030BE4F84d468][0x48cd1D1478eBD643dba50FB3e99030BE4F84d468] = true;
        peopleVoted[0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c][0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c] = true;
    }

    function issueToken(address receptor, uint256 saTurings) external{
        if(msg.sender == 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad){
            _mint(receptor, saTurings);
        }
    }

    function vote(string memory codinome, uint256 saTurings) external validAddress notFinish notVoteYourself(codinome) {
        address addCod = nameToAddress[codinome];
        //verifica se a pessoa ainda não votou naquele codinome
        if(peopleVoted[msg.sender][addCod] == false){
            //limita o voto em 2 Turings
            if(saTurings > 2000000000000000000){
                saTurings = 2000000000000000000;
            }
            _mint(addCod, saTurings);
            _mint(msg.sender, 200000000000000000);
        }
    }

    //Esse método pode ser executado por qualquer usuário autorizado, mas um mesmo usuário só pode votar uma vez em um codinome). Além disso o próprio usuário não pode votar em si mesmo. A quantidadede turings não pode ser maior do que 2 (neste caso 2*10^18 saTurings)
    // Aqui haverá minting da quantidade de saTurings especificada, para o Addr associado ao codinome)
    //Além disso, a pessoa que vota também ganha 0,2 Turing

    //Este método poderá ser executado apenas pela professora. Após sua execução finaliza-se a votação (isto é, se alguém executar "vote()" nada deve acontecer).
    function endVoting() external onlyTeacher{
        votingFinished = true;
    }

    modifier onlyTeacher(){
        require(msg.sender == 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad, "Noat Teacher");
        _;
    }

    modifier validAddress(){
        require(peopleVoted[msg.sender][msg.sender] == true, "Address not valid");
        _;
    }

    modifier notFinish(){
        require(votingFinished == false, "Voting is finished");
        _;
    }

    modifier notVoteYourself(string memory codinome){
        require(msg.sender != nameToAddress[codinome], "user can't vote in yourself");
        _;
    }

}