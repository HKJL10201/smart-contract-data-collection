// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// ERC20 Token Supply – Uncapped Lazy Supply
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Turing is ERC20 {
    // os usuarios contem codinome e endereco
    mapping (bytes32 => address) public usuarios;

    // salvar os votos feitos por cada usuario
    mapping (address => mapping (address => uint256)) public votos;

    // flag para permitir que haja votacao
    bool public votacaoOpen = true;
    
    constructor() ERC20("Turing", "TUR") {
        // os usuarios autorizados a votar sao:
        usuarios['Andre'] = 0xD07318971e2C15b4f8d3d28A0AEF8F16B9D8EAb6;
        usuarios['Antonio'] = 0x127B963B9918261Ef713cB7950c4AD16d4Fe18c6;
        usuarios['Ratonilo'] = 0x5d84D451296908aFA110e6B37b64B1605658283f;
        usuarios['eduardo'] = 0x500E357176eE9D56c336e0DC090717a5B1119cC2;
        usuarios['Enzo'] = 0x5217A9963846a4fD62d35BB7d58eAB2dF9D9CBb8;
        usuarios['Fernando'] = 0xFED450e1300CEe0f69b1F01FA85140646E596567;
        usuarios['Juliana'] = 0xFec23E4c9540bfA6BBE39c4728652F2def99bc1e;
        usuarios['Altoe'] = 0x6701D0C23d51231E676698446E55F4936F5d99dF;
        usuarios['Salgado'] = 0x8321730F4D59c01f5739f1684ABa85f8262f8980;
        usuarios['Regata'] = 0x4A35eFD10c4b467508C35f8C309Ebc34ae1e129a;
        usuarios['Luis'] = 0xDD551702Dc580B7fDa2ddB7a1Ca63d29E8CDCf33;
        usuarios['Nicolas'] = 0x01fe9DdD4916019beC6268724189B2EED8C2D49a;
        usuarios['Rauta'] = 0x726150C568f3C7f1BB3C47fd1A224a5C3F706BB1;
        usuarios['Silva'] = 0xCAFE34A88dCac60a48e64107A44D3d8651448cd9;
        usuarios['Sophie'] = 0xDfb0B8b7530a6444c73bFAda4A2ee3e482dCB1E3;
        usuarios['Thiago'] = 0xBeb89bd95dD9624dEd83b12dB782EAE30805ef97;
        usuarios['Brito'] = 0xEe4768Af8caEeB042Da5205fcd66fdEBa0F3FD4f;
        usuarios['ulopesu'] = 0x89e66f9b31DAd708b4c5B78EF9097b1cf429c8ee;
        usuarios['Vinicius'] = 0x48cd1D1478eBD643dba50FB3e99030BE4F84d468;
        usuarios['Bonella'] = 0xFADAf046e6Acd9E276940C728f6B3Ac1A043054c;
    }
    
    // A funcao só pode ser executado pelo endereco 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad
    function issueToken( address receiver, uint256 amount) public {
        // require(msg.sender == 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad);
        require(msg.sender == 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad, "Voce nao tem permissao para executar essa funcao");
        _mint(receiver, amount);
    }

    // funcao para votar
    function vote(bytes32 codinome, uint256 amount) public {
        // 0. A votacao deve estar aberta
        require(votacaoOpen == true, "A votacao esta fechada");
        // 1. O próprio usuário não pode votar em si mesmo; 
        require(usuarios[codinome] != msg.sender, "Voce nao pode votar em si mesmo");
        // 2. Esse método pode ser executado por qualquer usuário autorizado, mas um mesmo usuário só pode votar uma vez em um endereco;
        require(votos[msg.sender][usuarios[codinome]] == 0, "Voce so pode votar uma vez em cada endereco");
        // 3. A quantidade de turings não pode ser maior do que 2 (neste caso 2*10^18 saTurings)
        require(amount <= 2 * 10**18, "Voce nao pode votar mais de 2 Turing");
        votos[msg.sender][usuarios[codinome]] = amount;
        // 4. Aqui haverá minting da quantidade de saTurings especificada, para o Addr associado ao codinome)
        _mint(usuarios[codinome], amount);
        // 5. Além disso, a pessoa que vota também ganha 0,2 Turing (neste caso 0,2*10^18 saTurings)
        _mint(msg.sender, 0.2 * 10**18);
    }

    // A funcao só pode ser executado pelo endereco 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad e finaliza o processo de votacao
    function endVoting() public {
        require(msg.sender == 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad);
        votacaoOpen = false;
    }

    function startVoting() public {
        require(msg.sender == 0xA5095296F7fF9Bdb01c22e3E0aC974C8963378ad);
        votacaoOpen = true;
    }

    // funcao que retorna a quantidade de saTurings que um usuario votou em outro
    function getVote(address voter, address voted) public view returns (uint256) {
        return votos[voter][voted];
    }
}