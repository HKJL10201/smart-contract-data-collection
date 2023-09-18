// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct Campaign {
    address author; //address já tem algumas outras funções, que string não tem
    string title;
    string description;
    string videoUrl;
    string imageUrl;
    uint256 balance;
    bool active;
}

contract DonateCrypto {

    uint256 public fee = 100; //wei - menor fração da moeda, 16 (ou 18) casas antes da virgula
    uint256 public nextId  = 0;
    // mapping é uma lista que permite busca por id. Array não permite.
    //para as variáveis de estado, sempre declarar o acesso (public) 
    //ficam registradas no disco da blockchain, não em memória.
    //ficam no disco do nó da blockchain que tiver processando.
    mapping(uint256 => Campaign) public campaigns; //id => campanha
    //calldata para não salvar os parametros no disco, não tem necessidade
    //public para que qualquer pessoa possa acessar.
    function addCampaing(string calldata title, string calldata description, string calldata videoUrl, string calldata imageUrl) public {
        Campaign memory newCampaign;
        newCampaign.title = title;
        newCampaign.description = description;
        newCampaign.videoUrl = videoUrl;
        newCampaign.imageUrl = imageUrl;
        newCampaign.active = true;
        newCampaign.author = msg.sender; // interagir com o contato, usando o endereço da carteira, de quem chamou essa função. 

        nextId++;
        campaigns[nextId] = newCampaign;
    }

    function donate(uint256 id) public payable {
        require(msg.value > 0, "You must send a donation value > 0");
        require(campaigns[id].active == true, "Cannot donate to this campaign");
        

        campaigns[id].balance += msg.value;
    }

    function withdraw(uint256 id) public {

        Campaign memory campaign = campaigns[id];
        require(campaign.author == msg.sender, "you do not have permission");
        require(campaign.active == true, "this campaign is closed");
        require(campaign.balance > fee,"This campaign does not have enough balance");

        address payable recipient = payable(campaign.author);
        recipient.call{value: campaign.balance - fee}("");
        campaigns[id].active = false;

    }
    
}