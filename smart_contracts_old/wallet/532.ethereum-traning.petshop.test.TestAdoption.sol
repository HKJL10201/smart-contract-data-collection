pragma solidity ^0.4.17;

import "truffle/Assert.sol"; // テスト結果の成否を返すためのモジュール
import "truffle/DeployedAddresses.sol"; // コントラクトのテスト用インスタンスを新規生成するためのモジュール
import "../contracts/Adoption.sol"; // 

contract TestAdoption {
    // テスト時のコントラクト実行者のEthereumアドレスを取得
    Adoption adoption = Adoption(DeployedAddresses.Adoption());

    // adopt()関数の動作確認
    function testUserCanAdoptPet() public {
        uint returnedId = adoption.adopt(8);

        uint expected = 8;

        Assert.equal(returnedId, expected, "Adoption of pet ID 8 should be recorded.");
    }

    // 指定したペットIDにオーナーが存在することを確認
    function testGetAdopterAddressByPetId() public {
        // テスト時のコントラクト実行者のEthereuemアドレスを取得
        address expected = this;

        // ペットIDが8番に格納されているEthereumアドレスを取得
        address adopter = adoption.adopters(8);

        Assert.equal(adopter, expected, "Owner of pet ID 8 should be recorded.");
    }

    // getAdopters()の動作確認
    function testGetAdopterAddressByPetIdInArray() public {
        // テスト時のコントラクト実行者のEthereuemアドレスを取得
        address expected = this;

        // コントラクトに格納されているペットIDとそのオーナーを全件取得
        address[16] memory adopters = adoption.getAdopters();

        // ペットID 8番にテスト時のコントラクト実行者のEthereumアドレスが格納されているか確認
        Assert.equal(adopters[8], expected, "Owner of pet ID 8 should be recorded.");
    }
}
