// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x05c7b7775caad9077503e465bea47c55202a9dea15b56391215cd22077dca2da), uint256(0x24588cb1bf936f044442b85e709fd97dd25610eec72702084145d6a45342ad02));
        vk.beta = Pairing.G2Point([uint256(0x1fb283d7577102462844950eb5dcb62d3a4faa947418d986e6fb9b05a4b43f5d), uint256(0x104623de38d0071f244e2142047491b86043b6cc026d475ee32ea9785e33dc22)], [uint256(0x1aed898978d927790b7b06b337c36b0e5e7f568892ef66464985b3fa016243b9), uint256(0x1ccae5c92b3233d846fd6a1781c219b8e2a69781f87f7549df11b5ef5179eac5)]);
        vk.gamma = Pairing.G2Point([uint256(0x07d5f639b1a39757c9c314ba6220ee46fb3786c6a0d0ad83a67ac8f77d39a81c), uint256(0x0444a44db581b56b698e41d627492671248fcad34528cb2e671cccdf61ae9ea6)], [uint256(0x266906273ec7269ed7196a313561405d8a0e5972a5ae258601d4b5b39c19a3bd), uint256(0x056418615b6721f7a7e4cded16dc4de5202563aa051f6aa852432ee9bb4c26c6)]);
        vk.delta = Pairing.G2Point([uint256(0x242f4cdd7b60fcf8d2924a77831fcd798cb97e7d036119b4651b7bdaf91ec783), uint256(0x2b900c01c828d8ac1c01f35002ad7ad0a6ef4ac7f66ffecfe56773a83fd8e03e)], [uint256(0x1166909d8ea63245c263cc5dd503a336d6691d7ade3f8d737faf12309cbb9001), uint256(0x2c5698ddd0766710f297718f0a42a559ed46d6801f9abcf4b855adc1f5825b79)]);
        vk.gamma_abc = new Pairing.G1Point[](163);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1bb766970da003ee61e230dc5af53715fac1934505436d9c04165aaabd70d447), uint256(0x217c93cc22e57aed3c6a1cc3ea03d795ed1ea91edff6c7bbc4ac3ab173823530));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2d72cfd9207866d3152590b77bf96f16a5c68c3ca13564ae1ddaaaf550776762), uint256(0x1a349073eb7946223ad72c9007fcfebd6f0bef805685f737cd00b72d3406af73));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2e2403f919e1dfc10e6bb201f27f3aeb202ea557bc835ca9bb8b06dd451ad650), uint256(0x11f3a15588809a1fcc69991744e67c6ef0ae5b9e9d509b0a420db9cb108fb92c));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x09bf677dc438b44e6e291e601d4acaf0c1dccf5c17dfcf29e225000e0bfb1591), uint256(0x28180b8426bc11220d7f2ac02b6f8a8f979757eb56d5bf6c4cf9b848fb88ba1b));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x19a98a90dec011a07cb2d2612467fa7b7f230179fdddb9d9ac16615930916b73), uint256(0x2b02042894f9a9955ee101a4de43e2b57536d7ca7b8e633b62b5385dc88727cd));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x18597826c491d8f3ffe339cbb69f01eb4586c768f2eb8a803a1cee5198da9c20), uint256(0x12fdc41a5cde2df327b5568a25ca63641f1e8e6965321ce889675d64e3877083));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2cf11c8ccae62326141c228d931428a41289ae75d6a84394b5f8c255e1ce0c54), uint256(0x070abe0d4e93350195a89e3d047ed2cf410c443e586d9a3b5ba4d5d398e2a2d3));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x11b91c87659619ffb5bc3bb0b6130a40e43d94e5e84ab3c1e4edcb3441667ab5), uint256(0x15ddd5be0aba93ea027e0ba5f5ba78facbea551cba77b3b2c70e5ff0701985b9));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2719529005feca7486b999d18b38e702705362ce12a5ad6b273bd253b6136710), uint256(0x0c159848504d3fbf46fa6c5b05081a277b69317f0433083815664bc739992ab0));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2da199fdba740440de94a9e432f9c3dd19a68ffd0daf298374a9ef38a783a42a), uint256(0x160ee9ead2af5b8ff70e6f220d696386ad56af54a1e1b3f15164922d57582eb3));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x264f5ba8ce7ed5b93aa0380e6c14a9d9c0dc0eae9c5c91f5eb367bbdd16649bc), uint256(0x2e305d951e1d0034b0c49794c967c1798efc8db51631e573870b0ab72653ad22));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x14786d46010d747257dd84799c13c0650b0d92f3d2adbcebfea1f040164146c6), uint256(0x10c1940888b28910054bb6180f1531c6c5c8c6ebf692cb58798717d24a8781aa));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x18d5006a93925d4bbe5da2c6f14a431918203b5ab9c53da1749041d0a7278e28), uint256(0x05b6b199573d65d7f44d3824694fb5d505f3b3f4c179bba98b818ea9cc7000b6));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x03d77bb1d00d523370327b2e2e053b55be31f7c479f13a68073ddc47192c76f2), uint256(0x26cd3752f0f7520fd4a07955862fa53294d9fa830ead7342046b302090fd5b5c));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1d65671ac44820815dc4a6689c600e1dcbe4e8341109f3f991b8c06b38fc8946), uint256(0x14bc23b1fbc8a148d4fe2737beca0cbceeb6a2ef88f8f60ef07859ac52c7e1cb));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x17479dda5f61684f5c33e22fcd7dabb566e5fb2335c0765bf8023aedb5c92799), uint256(0x1160b48a36da4b00ffbd04d012619a5fa402519c6f9231ddd36f7dd1b23d3f0b));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x21096d46d464940736c8daa1a0fb341f75ec28b6ec0fe00643656ce2b30d9bf5), uint256(0x2cb94a364190c6f8bbcfc2dafc48610d7903bc2ad02688e0bb62aeb34061931e));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x041abc7f5069d3ae428206391a4049f19128ad8bde4959c74f7155fb37053949), uint256(0x29ecb43eaaeeb3fdf0a9b2517872984e31156050936b1092dbafe08a7e92b1b6));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x171cb23dccff0fa000ae07b546254239fddcd638b5c91bf2c97588638734dbf9), uint256(0x14dbb5b080d9148052839cdb80cd517f9ded15c6c088dac9ab9079cfec563906));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x0d41207053f7b92d3f95ce3fac464d2948701d6c10c7d2652c022698fa82be04), uint256(0x14d4c0abf41fad590b6b77326b0e6197b2e611f86917dec5161a4a5bad3abca0));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x1a21f44843e04d8a5f1f9f6b17ce2fabdc924f5511046324a30187046db86369), uint256(0x1081975a51f6c485d76a209a495760b4d988ed7cc7878da3a21df8101488d4b3));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x062dd8ca872921eae6cfbb1d6c9341c0720a565a95054555e39ae035355e6f1e), uint256(0x0eecf040da9afb8814187d756b00aac525b069be94e61b3e3c5b8aacec42b7d1));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x18e2b105b1f0961a7610b25018ab46ca9613a2a12b1165b2315ab2c5ec69c4e0), uint256(0x0358e00601451853c6c1ad312f25f8a09c002f78d4b65af38dbc4de6d00ceff8));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x1fa4b4741fcc6994dcde9d94e9f9de4d507a3f9de4ea70c571e7938fc0458977), uint256(0x0ac1183814b0b857919e2af8d43b591242249d7ea1b55cbc55c574255bda38d2));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x2ddc35b847765b679c02bfd0741cc5d364dfb75c4238910c0bc22d91ec036cb4), uint256(0x0a20d3ea77d4ccf5dad6530d1de25e50f939dc976fc1590d1cc1b38615863876));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1e50c1b220e509a50a07c826089029d9f38ac0d4d7f504d7c3bc9b46eca085c9), uint256(0x2632f27a58637437af3775e7cc72c021259fe94f925673e4aa241ceb091a8f5b));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x23bc7dc87cab18d3a80117d13f9403ea3b3f0253e3c32756ce8dec5d2095832d), uint256(0x2688afd772499d05d8402846679f8a2c33b1ff88464ff1b0ed64e5bfefdd49d1));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x1865c042b30b18b8f7109343ecf7ae9cfb37d94987bd52440dee13f4f380e3cd), uint256(0x1e5b5e9fff80aeff762db0436e200192139fcd397fb6cdcac2f794c71d7eeff1));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x290e038197b1505bec198a2d90bb4b5cd9c53905c7aaefacc5e7cadb6c5a01c6), uint256(0x07e191fe716eff08a53a25b7af4fbd32bcf1faa96497f439d29783bd18d18fc5));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x192519b16d0da9348f4d63b3e2028922547188840d401680f15fcea3b69aa435), uint256(0x2f92e16c073bfe46cbe54ece318adc64acc201f294e5378d829987f81c0cc440));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x0b61b00386755c4e8cc59052b406ecc7ae69533bfd0c5b1596cdaf2c57ac29d3), uint256(0x006022698b76ebd803d5ff7deec86c688c8eca6ff71d77cfe2d2034decce225a));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x093dd534f39b4b6213d03381aeaaef45b591418bd3fe1d84e7dde5ec3d9d6264), uint256(0x1af2145365ee333e608777f8e64caa43fbf781dc55f79ab6ed3ced8c86422189));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x1ab908dde6a8731014145a21792d8e8aec732baf240b40fd86e1dfa720b31c82), uint256(0x228670a3af2958609b15bcaa36e9034427929cf5c533cf5c0f50fb57a31aabf0));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x094d51b3304cdaa910ee068ed905a91fcaeda9a9b4628f119954dfd22454452d), uint256(0x10bc69a394f4de36499950ad36f1c8abac12c6655594fffc2fb84991bafa7239));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x04f30755731a949c8f37e2de3f91f06a898be9dc4286a9d6207e37259fe2b7dd), uint256(0x02eeec54ae142f2cf190300a3356b6ad0268d9115b56b100610f0b2914b12d0f));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x2e1f25a3c77aa4bf0f5c2db0c6c36142bb0b3391f8186b0cf78b921325d68db2), uint256(0x137d468e74e933eff9b19aec1cd94d11c61cfca45b50d28f026ad07130cf0f4c));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x1548c0ca69ae6b03aabeda716c3ce6fc3f71b19f154af4b950fde54ec09a8330), uint256(0x012ee833e3fe7e5ee2a46c740cc8624702785e3ec89f8190d4df516b229c0101));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x2f38a85064084975c02b497a5f92a2b38f1d417bc659e81bddf5e41a56314b4e), uint256(0x0477a9db4300f54e9e780682fa02739e6009114298cf84c75c42f144f8eed7f5));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x25432aa2172b26936fdf8b9bd5915fa994ef1d843543a9d3e739ec90a01dda7e), uint256(0x16f56aee9a55ef90f28dd222aef079242144311a43917573b2713577471be344));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x2fd2481a266e06e3464ec660659977ac225e99ea6e8318aa6358d5e5799f0dfa), uint256(0x1ba3fab6426f6c9606594d1488cc1559721dd60d7385807fa1e28eab176461ab));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x2ebc3a9c0fabc508bd70b78ee9d3859c88f185eecf0cb6894f7d245da22bc382), uint256(0x1759fdd6826bab385d8fc39b797cb5e91d35412df05e95da3a095878bf5a3d0a));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x2054e5721371455c01aa0ffec1b65d54534652268333eaf89293f4c9d1001e6e), uint256(0x189bedfbbe8b02ca7d9ebc5b0c850f43f9ad5130ad7af979e67bc15a60e22bce));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x147cf28c778d73287f3544705f00d155525cf289dc19b8f47bf3a5e8558ce75e), uint256(0x2c4925ad113f138a233379f047c827ca9c57b82e063e4895e2ee813a00502a88));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x2a65d29a8527358a749a0ab8be597af9ab9a820740c1e9730704a091771dd1f6), uint256(0x146c76e2a7480475f73cc92cef2a353b861d732e5e43a0c8eec5a23d1cffd7e0));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x07ff461bc0cb384c1970f211c0b265b620a8dc88ab8b54a471aae7575ed3260a), uint256(0x0fb7e46e6af168f1a63fadeff3df1dba58a63e8b1c5b787b3bcf7c8cfebc88a6));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x2c10c3c17eb77db78a74eba0289cf1566c7f9d8976e99289fa241c69496cc65d), uint256(0x2a21b6687836e58095e6fe1528c2e7e9c70aecd3e92d654ca431904e23e62861));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x212a94ef7ca1b497466a1782f77031b878e6eb463c7305141d70738093d47982), uint256(0x0aea029135095a5de799257392bef1ec5080814e3119630b020affe356e40321));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x1a7276205509483d49f40e4f8d92244bce57376154a50a6c03a931a399c9c7f8), uint256(0x2bada9a650e1a41225f2b346f2d9c23a88b46210f01b6ab9e02115d08a4ef659));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x251fae1d18ee5dca20483eaa921a23adfa06e78ffe1be2cc3119955f291c3135), uint256(0x2fde49c6a81d7a53564543b7d07f73a0b20ad8caeee4b075fad149eafa5a92e1));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x1ae271d9db7514a53c0d0df625104236fc284a8650ff94e75eff55912d185999), uint256(0x0af053a97d668e42857b20338cc6f33a6258b4854ccc46fc1bc5946eee57a827));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x05e718dcbfd4076c76e39b604f6ecf4bb4c1bde0d897df76cadf869f88e4a738), uint256(0x002d83c24b7d338322d5d32fe6d80512177076f9e1d519139d66c364285f3051));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x0b45ac778dc56f98805b1f8f0777bc61c55959767e569924c7324380b857018e), uint256(0x294b8827bcb299c8554524efa6c7333d15195b9f9fddb365d856c804c9174a96));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x0b32dbea5980048cfd8bcd4c82cc4113056fe99261184e78305ed7064bef9f07), uint256(0x2bf7357e9f8d0f04546923b324e0c36d82d356cb46b6a5e95d677ed52037fcab));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x25b1143bbf29d7949d1098a5e6e0447ab14d36cb17dfa176b16cb331f4090351), uint256(0x0852e8d6367a1bacdf88cd02a183b1b0d90906a22eecd48d291b746b42782f58));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x0cf4b3a65fe3b7892f9915a5ce55c3be5b923db0a148cb5cc5690299f63395af), uint256(0x10975d9578e0b2ac096a434ca78454e71e16dbbdbd2af90a52fe214ca769f1a0));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x017300f0a113320bf19b66102a24af72ec4820feaa16c2f6bb735f755f846044), uint256(0x15afa38b072fa2623a48e413ced2311b9c0cff559f85a6c286bd62a72802f3d4));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x066d75865fd8a82fcb409917d1f7b696aeb87930fce591e7a2ce676bcf99eb41), uint256(0x24339b3705b78dd0c52a84899b5301552f16e277969c551f7d226ab72c2aafc8));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x026d03053e16b1ef64a37abbae9d8faf913eec2373903d2596e5028697ad4933), uint256(0x279abe4a2785f965705d067e6085654bcc1f64c397e41b18ab02eef0ca849ec6));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x251d9112c5b766e751dac82aa833dda226dc77c38b18fec2639a69f43c0e179f), uint256(0x2e7d275a49a2728fed87ebf76022ce7df30e7e22761a896c8a26c123a5cee187));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x0db99ef30af7133f654d43d502029901e88f52965d4cb50d1dd246b2c332e698), uint256(0x2a6068336ba0df5132bbb6b4dd5bff68dcc7ded2c03cba84e8a8b6e9088aa630));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x2998788bba7a7392307e901a85aa901ac349a32151dde8be41261ca5e166fd35), uint256(0x1afc7f6a75fb47d6edfbd70e89e20fe12a044e0638d7ac4bc35d3210b90247ca));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x092258c7c8b76c5a44d78c909df256e46a8703b8fdc9df0b9caea5ddd72c6e63), uint256(0x067cb435d66dc667ff852f186b68c1fc8e84f78a990e7e872d5bc610d2a4c4e0));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x212bccf04105044864e730700451db9e4dd1e7e1345e8b64096e286338e3186e), uint256(0x222e834570cc87864640f47fad084a477c26c6b6615980a42ebe9e5e0a38e049));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x125b77e36afdc84768022d45c5471b16c50fdc6d30634f8e8be8019af51702f0), uint256(0x269be98efccacb95eceddb02cba45cab35b378b7c847bda75310b7f6705c83a9));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x2b9f3a3c97ee65f9df612aa5b3aa1663767c9475691a11b2d3053865aea67c65), uint256(0x17ca7635456331f378e4618dc3f851c2c9cc072ff1cca51fcf1f65a6ef018cc6));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x0c1b9704168826e1158ce7122a38220b9fcc3037996739f0be078e927c8b6b4a), uint256(0x0c88a38ba76890765494d683d0716d1103883c9adabb20c25ae63817b4a0b315));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x025771ecf0ca43281503227fd61b833c7d6ccf1cf4e4b86aa1fc6832268c5f5e), uint256(0x011ccfb4ec1bc6e57bd9c7a47b504edc296f3646ee54c38ffe7c83c29706fd1e));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x0e465bf63d2c8376e85f98c0731c681e5e71af6ab9011373845e125dc86d399a), uint256(0x2e3b94e209f148a57674c38271511791af3cfbe84fd0c50a4e692f49117f2592));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x21655dad0b7d5e4f6698d587fc36a3283a3d451cecbbe30d91cdb0b5efa66a0b), uint256(0x19042b5b21113a29b3e012c6c1e810927f1cf1f55201394fb1592684a7ff2135));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x280a4337b3300cc12bda139fcd428bc06990e3f0d61166b6309faba7defcc5d2), uint256(0x03c00a2045967837c6b7d69eee987430930d6073670d9ab5f5eebd689ef104c1));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x1b3ec362742f7e78cc94cb3c8543d1a88ba22f831bf994507e6491bb7de72f2e), uint256(0x0624e234c1e2fed45f17cb48a9c5949aa4307b78607c6b73fe524e31ed36549f));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x214aaccccd2af2052f735857479d8313133bf5c689077ce96fb6b58e2ee449f0), uint256(0x00365859db2e42cb323187d9340ae47c575531fb4dc6457e1c92904b8ba2686d));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x131d5582e03b38fd4e420fe1be964deadccaadcd7d0308466940e3e8a6f3da6e), uint256(0x1fa0728b0d65d703608655258f0afb3f2f07ae21ad5687b1cfbcdbf836c61f3e));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x1e5a02a47bf53f259739717b7c3d4c9e0ab79cb5f40a0041098e5619502156c3), uint256(0x26ba32a0cd1c9a555d41041109247cf61e5fa6e87bd56034861795b74e6a2215));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x2a038154ce9ffd7c88b23159a9aef212980554ace0d515c118d482894b7ce4e1), uint256(0x1cd6f8730568b85d6de577cd943e3714871777d6d5e5b33f90e99f4fe2c5fae2));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x0ebcf3b644e96cc1ea110b2a895c7e0228b3208a31d306ad061ebb840d41202f), uint256(0x2aa4557cc38b2f7f91576d9b9dbec80ce7d89188a1ee796e63c2a961632efb12));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x1c0091278056b0dbfd14cd109c9a0711f41bf5c2aea221d496df4315c208704a), uint256(0x2c294630d0417f8fc49ed46428a6da3eb1f6fb87f80f59cfa035f66dc6daff1f));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x07866282a0fcf2230614c14e55fd640e7edfc32937cd5cf692589c7f59c78ce5), uint256(0x2cd99bb364b2c1733ddbdc0622ebdebe6e7121053521be8717ccd03b0dafea21));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x2ccf2448a2af39f235d073cc2615ed26770ba5485b7f5814166776b9966adca7), uint256(0x1e06e57b0d926156b80c3050d2fab78bd5dedde9831a7f239f627a9d3e2f4c04));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x02bc7042196d168f4047039e6db2b6d28adb1d798375f61d6ef5066bbe929614), uint256(0x1eb9ff121304223765c597ff800042547834689938c793d3e756a60518c4cb6c));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x03561a4dbbb1dd8847fc43a38065e9016e55ce4406d706b6d872fc316cd9682b), uint256(0x0c7187933989cda89b3610e3e3a95f2aa88a5f59bb160e03a17ac228f120c63f));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x03076c4e407df409c617186ec53241be17c7cbfa31e69ea730eb3b5b564871d9), uint256(0x17b4e5fe73a94d2378799ed6c50fd2bdf35fd7ba57f824c01f2c6af0806660dd));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x2a324fefdbf7b36759e4d7980fb2be0b4bcc7d3d5d735ebb5f4d850c8af85fed), uint256(0x04f80b01ffb68ea6fdff6052659317a05fde0446f743747de590ec1716f43490));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x0b8c3790cc7eb247416304bf6be7b03341240175ce9e552e57eb8c115bdba835), uint256(0x18d4eff650ecbc3d988fe3caf5a68aeeb61bacaa4ae244fb132219667983be06));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x1f3af1f4fc34941e834fb637aaded485ea8fe7db6fade572b73a6d0357f78ffa), uint256(0x123ce296df71eee039fdc57f14a3e475e0d452d88d018c1cd8db1253b5ecba8e));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x0a276c41495053f621308f86b5742c2bfbc4221285330299df3849b7c6d5c2f8), uint256(0x135537f05efd1cf6fb0c60e53ad09da7410483188ef400a1f0c335f9f64e4ebd));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x236c53015ed8b7b9696993751d1368d595ca4e7ad1e25dd2784c15f96f79baeb), uint256(0x0dd434b59175d68b0997563865709c4870e37f62205a34ecaaefcfe18b17c204));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x22b9916cb75264ca8c0caa24a9552e42f9ef7cc4c9c92bd2d684e6adf5866d9a), uint256(0x11c64f7d247938f58fa86c9ed3f4b9d2d666b24a4054612c6b2f19ada8ec09be));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x0932b68cd2de9f2f29bea68112d9b86c240bbe0342a285f5b223eba15d1720d0), uint256(0x2a18fe0af7d9d501ef6f07e7f99fc9345ca85e5f07598448fd95a313de05e1b5));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x0b5ede382a2badc4d32e4e54a2fd7cd71e76459f1283940ba96af820869bc70c), uint256(0x235754428c06443c1fb2c72e6023a388a21c9faf6576c73338ebc63d309ac1ff));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x1b1bf7b238457a5f241ea715997b53a714b9cc97fbad698d5348364e905fcc2e), uint256(0x1fbacf398cd033dd0cf273e54b8114cf3fc959545f73a6aaa529961b52049c21));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x0b7b5610897530f73e9a98c77c1673bf918f450fa9943e45a310654d2f42e4cd), uint256(0x27c41ce67373257f6747c7c83be1fb32ff9fb500a93db9c027a280c43e294faf));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x083d08a2aa95b02d4bcf8d31047e43a532198d980f2ed120675afd65f8366cc3), uint256(0x2e83034a1af1d3c0984d7c6f4467e9488c1905c18a82b1b67a65df289dc8c572));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x05c881e5581593527899c5e167371ac93b9b9b9485ba42df54ef1ce7bf4bef24), uint256(0x13537f384df32b081e7b637226780d792de54e5afe85d637dd7ae6e60c52577b));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x06c17d28297f76498dc1fcb8f80a783af15a18a0e9b5db0ad42118c434f1a63c), uint256(0x0b20b9bbbb1d30631bc104b96f6de703be7f2c3559293b52f40c4fef47078ab8));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x17021efac8d100c3b597aed468f9593259439e17ac29ae3ac8c3d0dd3effd543), uint256(0x2f67e4d37c00452cf10764513f1a547aea2ebb90119538123c27ebc490b132b7));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x232553a219638c7fd83a439266db0945e588ae3274db26e9f8205ea7e270b3de), uint256(0x05dc5c78741057be435706b03bfd6ed433dd4aa8eb2419de37cb56419bb9d93d));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x2f38f0ac616a90ebb1e14691bc1108ab2740af1fe088d0db91cb83c6fad1f7fe), uint256(0x224e7e9f5ff0b058942f1d5615974058ade477089a5a3f33a1883e81ac8ea817));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x166b81dda566bd531b10b21ed4af433009a06192e6371e6e3f3da9119d04fae4), uint256(0x0aeb98e34371b4ae53700a9be538553c4c671918ca8df839f66670607025489e));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x14f8978f554d4f7d5e90dfa8a453cffb0393c8aae2b9c53212ef60cff2f78c22), uint256(0x196d39f51f53bf97e276feecf134f7d30f7fa1f1d684a9b8181de0fe5e61d37d));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x2046f94e8e9e6b5e461c5565e52305afd1d98f1508f4ddbe06fa4527a6c0bf5c), uint256(0x194539c5ec3b0c00895b59a16f3a93d098ef0ab86ea5ff4bc2167655c0cdcde7));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x2b0ddf7131a8dba68dfd6490cda78d5c74095aa6cea9a4f33ea1c32037cf4931), uint256(0x240056c6ccf66f6b56ed12a42957676f6836e5831e836d1fc63a31fd27f04f28));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x06f2e96ce2ab1537f5d242af8cd0009e0435df3013da7e1ee6da440851372680), uint256(0x0627acef4909758218c63d0da9fdf85a9387a500c5df34873e99de7c8be6b8c2));
        vk.gamma_abc[103] = Pairing.G1Point(uint256(0x29aa05cd9a330f3a9364149d21a5f37fcd0681460b95ee08bd8d8f60e18e5912), uint256(0x2b454a34c62aaa3ad221dc6121d46557d7eca2f5f2e94e07465581580225e7bd));
        vk.gamma_abc[104] = Pairing.G1Point(uint256(0x11364b4a9ed8f9882f6bdca63f4e609be2376d7f6be68bd0895b35013df188ac), uint256(0x2febf1f9f32a067f2b90e1b50e7aca7125719a28dcf988297f94f4589b3cba92));
        vk.gamma_abc[105] = Pairing.G1Point(uint256(0x2bf7dfbad45fb21bd0685c6ff3f253e991d22ab4b1443b6ae8b0612e622ceda9), uint256(0x2b6a46a0430f4f780539b95630e26bce3a00f3791b248d66c703b30dbd7db670));
        vk.gamma_abc[106] = Pairing.G1Point(uint256(0x0b0ac23349c08d100b54f76961acb5317517b3be78c24b865366dd3fa46dfd6b), uint256(0x06982e560e07d8ff104353847e28e7144b915eab7b46193b9577993d79d80a62));
        vk.gamma_abc[107] = Pairing.G1Point(uint256(0x1c8c3922a93800f34e426abdda608c2bdedd512e13a48b442daabca839b9982f), uint256(0x0160df90272a5776669587a0fe88d2720353c9980186a10a8d837d1b825f363c));
        vk.gamma_abc[108] = Pairing.G1Point(uint256(0x08ed1e42295e9c2e00403f1e8e5fa1b3b451742d33d7ffe6590f83652e9380db), uint256(0x12d209ecc94561a14c4b449756fd96980759b07be043b5ca702cff5e9f59ead1));
        vk.gamma_abc[109] = Pairing.G1Point(uint256(0x199d77f11c33f41ebc4f1d15118fe3634f986bb9413612b8a128216230f14572), uint256(0x2de94e7dc58c0207e17b6b8123082c546dd3cc79b437f4ecf5d33a5f51f11713));
        vk.gamma_abc[110] = Pairing.G1Point(uint256(0x09899b52a10e98c3a8af5380fbd3c53c0d83a945ab1379ed15c7f479572fe40b), uint256(0x228430d2aa2820968e4758d71472ae3cc0375ec08522b161bb5ac8f5c6f690cb));
        vk.gamma_abc[111] = Pairing.G1Point(uint256(0x1533fb0e3e29b5a11f76b8f495708138a04ea60b53d63fd79adc1f5d466ac1f1), uint256(0x23adce7eab7206018454135e2cf2416da65c46004f406f1808d7db33940215fb));
        vk.gamma_abc[112] = Pairing.G1Point(uint256(0x051791f5f182301b55840c8b94426e83579186b1df88d8026c693f548682ec46), uint256(0x0001bfe5ab97777d8366fa4fc26e59df5ce569aeb636e5b66a219ad5ab4c2c51));
        vk.gamma_abc[113] = Pairing.G1Point(uint256(0x1a498b3d1919b22b5ada39192049090a8aecdf69579e9a4f84d80b953481c586), uint256(0x054cc69a7ab14c4e7518cfdee09e615d163f9c2d97822248698f9776132dcdd3));
        vk.gamma_abc[114] = Pairing.G1Point(uint256(0x2438bd2c5013dec965805e4776410dc59ea60483631ea3ca89978272048b3564), uint256(0x1f9d579ec052618487cb99b44f994535de168efeb7913729f2f373e7b81ae01f));
        vk.gamma_abc[115] = Pairing.G1Point(uint256(0x0e8f49838d04a0c8d70374b593c15726b9877e865b21ece6cb495e9654e8ba2f), uint256(0x2da6e8320f3615b6f6a20cb5bf27ff059a50b0d509ee814901d915dc42d2a69d));
        vk.gamma_abc[116] = Pairing.G1Point(uint256(0x10356e7599db2a45843747fad8af1c2fd1f282613f0366ebcee62b681ca967a0), uint256(0x069ea3da00cc75fc607f3d28c11c837a2ee97f1f1789368959f755758fea703e));
        vk.gamma_abc[117] = Pairing.G1Point(uint256(0x1ed6393fd3fa49105d3f56ae72e7c3522155bba8a7e58b18a25e26fccda717c7), uint256(0x0212ba9e35aea302a74178561f5759b8a0f5b73f15b54ee23b4772eef541300d));
        vk.gamma_abc[118] = Pairing.G1Point(uint256(0x18625c723579e0c927f4917993aa2d2b809e6b33b59102decec9150951262593), uint256(0x26d42b09abf1385eb66a9e685fb58ac6500a33050271aa0d8cc3479c3260759c));
        vk.gamma_abc[119] = Pairing.G1Point(uint256(0x051bb578c07e7377362ab5a76641cbe6f23602a9d96d32d4f7ae4496a0e147ec), uint256(0x1f633c695aa3191201e3ea6ed88b54716d2147e2e09e87f5ef15b613b5f811dc));
        vk.gamma_abc[120] = Pairing.G1Point(uint256(0x2b76d0b568bf48c0cd626be1abe88d8afd38a92b9c020e38778d18e24f986107), uint256(0x06dcda279877b67043a3a8624c77b5404b5d65b5db455b24c1ad1fe1d6cf87d9));
        vk.gamma_abc[121] = Pairing.G1Point(uint256(0x019017b687ea23a45a0264af76620ff46b83684f6b9cb0f9b77cbedd47706ded), uint256(0x1fabdf539ec64eeb3aac0ca63c0bacfc9bd28389a912aae3d61c8e7e922ec782));
        vk.gamma_abc[122] = Pairing.G1Point(uint256(0x2284dcb97e4f09a19c17f13d1f181c094dd2fdc5654e7c520fa07631e0f0918a), uint256(0x029e84d118f8de37d9d8f05ba43a4035282c81b60603c76b6f92b44adcdf1b37));
        vk.gamma_abc[123] = Pairing.G1Point(uint256(0x17a17355e995f86101e4c4f3fd580e8570662a0a8dad1068ca672ea83be196bf), uint256(0x03e13797f3e7bc73f381f230e82b7844531be43e1a6bb006762f89e5acdd9143));
        vk.gamma_abc[124] = Pairing.G1Point(uint256(0x1258fca5dbf3e6e6c0e5e7c10da138f21eb5eaef1f0bb45078572e27f9388695), uint256(0x0a87d70812f587454d056406e6ffe8eaaf73907f9cb40a82edc28a7de8216399));
        vk.gamma_abc[125] = Pairing.G1Point(uint256(0x0f8ebc91a34666afea7952a64de26def2393a25b8b54f97addf01d6466dcf32a), uint256(0x0943aab759a6c348ebadd62c194a5ef2dee091861777e376150f0483c01bba7e));
        vk.gamma_abc[126] = Pairing.G1Point(uint256(0x0582949317fc0a0593c67614d3fe15614f118e6a60d6e64d72482b719656bd46), uint256(0x2f2f285ee10e15eb761ff5e7e093b61b1bf6ea24f628676dccbe65fe67da5796));
        vk.gamma_abc[127] = Pairing.G1Point(uint256(0x2577169c056bb563a93f7e08519c38ad29c2208bc0158760020fba478831e24f), uint256(0x16691bab2c3774ced2c1cff8b128887c9cef955659ea6120cb3b6e9d76a2018f));
        vk.gamma_abc[128] = Pairing.G1Point(uint256(0x237415e7a11d1ca0c775e1ce8f044fd0fe0492677ed12549bace2f8c849ad78d), uint256(0x119b133c7062cd066710ea913078b1047e2e396a25b94120d6c45635703be339));
        vk.gamma_abc[129] = Pairing.G1Point(uint256(0x2b5f75885d03d463aa91facc8ac34b1b134170247631170cb962c5028a6b78b4), uint256(0x211bdb50495bb1668066460396ca92f9343e805e8595c03f9e2811d248fff61d));
        vk.gamma_abc[130] = Pairing.G1Point(uint256(0x0ff91fd105859ce1540501b3e9d7897fba35485bffd15b1cc3a5b92783943419), uint256(0x02e29163a8fcfc1d77cde7eee3100e09175b3a5138800d6dfd81d05735fe85dd));
        vk.gamma_abc[131] = Pairing.G1Point(uint256(0x156deddcc4a81143bba9bdc3856d860a5bb2ab46584dd5390972ee58db6b15e6), uint256(0x1ad6ccb7a1d0bbb6d473e78e10eccb191ba90f525bc8b7b61662e380ad8ea755));
        vk.gamma_abc[132] = Pairing.G1Point(uint256(0x23442a1fa613dd1cb58d8e39f80fef341be75302bb83d12422da4168e16c6f00), uint256(0x03fe6edf3f1705d2fa8d8fb6eec6b7c4baa9bdf914cf8187b6e726a357ebe560));
        vk.gamma_abc[133] = Pairing.G1Point(uint256(0x0cb84849d805b41335ebb90b99d49894f82caf2401395fa3a01177e5de1309a4), uint256(0x0e969c5f69a2961eb00bef3a50bf589be0b3114fbc9bbdea83b2b8a26b20c9e4));
        vk.gamma_abc[134] = Pairing.G1Point(uint256(0x100b0b93fd51316fe5d74bc90367ff10c052af7a3d5d7d2ed4b7f9472616480e), uint256(0x1342f28af4223e9d1f501597efcc4edb76ac61677ea4c02e28f6cbd931d24bdf));
        vk.gamma_abc[135] = Pairing.G1Point(uint256(0x06b01b43a6716af959c7123fb31c3d13cf49d898f05227446d2785b847ea6af3), uint256(0x1bcd70a2fbddd25d9f469d31f3270edd43546be81030fc63c09c749651b06321));
        vk.gamma_abc[136] = Pairing.G1Point(uint256(0x104a5945cc8bb4c81c6b702d9c2750eaa3c728e9ba9c9ab9332fb9e18f1a6742), uint256(0x2b2e839ebf65f65da2dfc03720420b6443299966a04b07e877a30886fb3b3482));
        vk.gamma_abc[137] = Pairing.G1Point(uint256(0x199fd69bdb75a3564ab6fb1f8b7a2ff1d3659d66534c43a368c936cf4a862adf), uint256(0x27cd983dd1a509e984fed7d79b364d7e0a781aeac8759358591927af941176cf));
        vk.gamma_abc[138] = Pairing.G1Point(uint256(0x21be70d0d3d3ad96644ab4061c59404b92b252f4f009955547a832eed13d4582), uint256(0x1fa6f3aecf806ea080e843deeccd8e920224ce8f97fedc21755f1e9b1616712d));
        vk.gamma_abc[139] = Pairing.G1Point(uint256(0x0ae5b55fcae9e1e474ed4ba21ebea973d2bd59552582aa265eac82eb8950d10a), uint256(0x1cefeab44648c75142c4581a97df8e2b678bb017f0c0647d99053525a9dcc95c));
        vk.gamma_abc[140] = Pairing.G1Point(uint256(0x170d14c0b110ba12de5d1774f8685b0e7cdc1c4cfdf4c8045890955431f2c003), uint256(0x2430478ab5ca68dae603de3e977324a3526c2ca60b6e8c7c7d39211a30f8e97f));
        vk.gamma_abc[141] = Pairing.G1Point(uint256(0x031c52ad0d02e5719d59190c630c73bc5bd891795cae4904211e8d59b12c38b4), uint256(0x2bb4ef49ec4758892c608a422f146fe65de8c4abc7d88b1997f5d80896f6e886));
        vk.gamma_abc[142] = Pairing.G1Point(uint256(0x1c83ea41aa806b08297624868edfb8526c8507635a245963dbc5fc066dfb52f9), uint256(0x2ca8496ad80923ab9977d89323455381025a098e63ff0b1a213d6d4fe5441d57));
        vk.gamma_abc[143] = Pairing.G1Point(uint256(0x28f6a66f8b0790bf05b5be3312c631d09a7f3c4085581f9813fba77b084fd7bd), uint256(0x18a28ecb21dbea1392ab35a120e3b44e8ed67fd24ca7a996ca80a4a66f9f5899));
        vk.gamma_abc[144] = Pairing.G1Point(uint256(0x26a73c8211d087c9e75709b18e5fe260089549263bf5422bd3b22280c8fe9c12), uint256(0x0ebe15ee1f57371365fbd884516afd7fd99af4241261b8d8d4f9b04576db753b));
        vk.gamma_abc[145] = Pairing.G1Point(uint256(0x1b97d6a7bc5fc9d32051778aec272ed18108258419db104abe93584b18d3577e), uint256(0x025b81e3e1844ec8f96929145e5fcf43ca6efed3907961d840f00b912d32c5c8));
        vk.gamma_abc[146] = Pairing.G1Point(uint256(0x14d977fb69ebd34ee962377d480400a37205fece0dba6be440502ed7710a9c6e), uint256(0x279b141e59481f03505c148a9909a0a6feaf1a6f5efcbd3f8385a8ade9c1c557));
        vk.gamma_abc[147] = Pairing.G1Point(uint256(0x278d65f3fc749a14829a4bc4d897398686bc9cdfbc92c1054ee7685b2fe1ca66), uint256(0x289272134da2b59dfc51fd6f25e39c653b3b4fae59d73ad18fa9b8d0391a3a48));
        vk.gamma_abc[148] = Pairing.G1Point(uint256(0x2a6b0d43f28878a1216456442fc9cabfc2a2f7175994997708338187de1e1a12), uint256(0x078cb6721b531cbb1b71dd7984061df03ac40f6ed9ed1f5de6c85a9c3c020430));
        vk.gamma_abc[149] = Pairing.G1Point(uint256(0x22ec6f77bb59adb38893dc712052a074533b4b58ae79eb3dff9e482ba20221de), uint256(0x0534ac53f3e5da232b5535345e5eaa711a91fdcf8d85ebe9da29806fd7315a21));
        vk.gamma_abc[150] = Pairing.G1Point(uint256(0x18e144d11757d4e46eab239d0107f46deaf0df7e34e7212aa61285a27aa0cdeb), uint256(0x21b2abf589667ef05211a8d8d20ae2a7efd658866d70b5a406051e59637dd04b));
        vk.gamma_abc[151] = Pairing.G1Point(uint256(0x24ee4700994b5e3956807d40b7416bc2ac9b6985a88a0c1cc4727121808911b5), uint256(0x1468e9a11f0ce32303f2b7dd1300a1ea5995a2b3908317a32a53e4e0fa86c68e));
        vk.gamma_abc[152] = Pairing.G1Point(uint256(0x0739131799e61033c4ddd2a344a31c8897ca4f324c7b31750e85f286cb4de97c), uint256(0x0c1dc9729de9f336212f6a1d67912e20924d8b9e1b9af431e52e5c3ae4c973c5));
        vk.gamma_abc[153] = Pairing.G1Point(uint256(0x24613d240276b1cae73444ddf30d3e9def7be2b03cd43f0452c6b06501956091), uint256(0x0fa0091684dbdbdd22392d9b930f9f3f9424945dc072db16dade5d5c15ff8233));
        vk.gamma_abc[154] = Pairing.G1Point(uint256(0x16144c3dcfbff0e5376a383d61b97ca56afefd45795e111e08dedc334c72f811), uint256(0x26b0cf3cc3e060263cbc9128e5f7eea80c3147ae1a3f661e27c237c19bb004b1));
        vk.gamma_abc[155] = Pairing.G1Point(uint256(0x184002f00f5890e276c8abfcef5312aa01a26105e51e7dfde552275ba5cce146), uint256(0x1afc29a9b7b21503bb0cfd5a7b483e8528d6388af06ef45a6f3b7cf2bed796fa));
        vk.gamma_abc[156] = Pairing.G1Point(uint256(0x25096aafc7f7b4ddab4cf9ee645043351ee2ea98032b27b3823cb54091ef189e), uint256(0x2b5f80bad9d90f2fa203b1f2e01ceeea992a72bf66bdc8c9da1352807bc0caa9));
        vk.gamma_abc[157] = Pairing.G1Point(uint256(0x179f9794bd4dc8b6aede103938f2e2ae6e4b163bcc4f840b34245dde6e43b8a6), uint256(0x2bd6eec562341801bd56aa7ba4708098ec8ea433d7a658d4cc11227db6aa7f35));
        vk.gamma_abc[158] = Pairing.G1Point(uint256(0x026a71cb3caac07b27a85c7cc0922fedd0c4e47052e578339c0266d773c2b5c6), uint256(0x20377a8cb2b8b11142329f8b97fbaf4d8edd00e434eff73ba623abef47c9bcce));
        vk.gamma_abc[159] = Pairing.G1Point(uint256(0x0753f94774ad6084ffeed757c8b7ee852a51731c72ad3dddec632816a1744342), uint256(0x261faea27f18fd85abde9bff4655b92eb452bb542303c90fc52b4150e5f58b7b));
        vk.gamma_abc[160] = Pairing.G1Point(uint256(0x2595164bf22ad823fa01c26ff8ac40785f1a15befbdcd1186b0e274ea0a14484), uint256(0x0f04c3402e0719c1e7acbbcacf3e961dbf4ca4e316fb2829fb7d02db5c8bc376));
        vk.gamma_abc[161] = Pairing.G1Point(uint256(0x22107de4e27885835a9d334efd98cfebb2ca602e1b66db839aee1a9279eaf992), uint256(0x2d04161412760fe2a362be544b60b8deaadda9abfa3450bf4d540faf2be30986));
        vk.gamma_abc[162] = Pairing.G1Point(uint256(0x2b90fc2caaaba1be6e692a48c0e28318506c2c6f8f13a4ae3c5815897f8075f3), uint256(0x2b857817d1765133f413271f49b9618f4a96a39704d6730746d3b821c4058995));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[162] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](162);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
