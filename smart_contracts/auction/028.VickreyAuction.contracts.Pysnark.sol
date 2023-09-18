pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "../contracts/Pairing.sol";

contract Pysnark {
	event Verified(string);
	function verify(uint[] proof, uint[] io) public returns (bool r) {
	    Pairing.G1Point memory p_rvx;
	    Pairing.G1Point memory p_ryx;
	    Pairing.G1Point memory versum;
	    Pairing.G2Point memory p_rwx;

        // [function] main
        p_rvx = Pairing.G1Point(proof[0],proof[1]);
        if (!Pairing.pairingProd2(Pairing.P1(), Pairing.G2Point([proof[9],proof[8]],[proof[11],proof[10]]), Pairing.negate(p_rvx), Pairing.G2Point([21440173107593148482816683042123880676180780996229737904399176241517645721350,5246835310509257254858642984295810516584817371592992387764061488788476496032],[2639225043932804836026170716721875591615899493131072898408613463598634158790,20410128128429030092444565389491254378650848811039843094043832338265343251897]))) return false;
        p_rwx = Pairing.G2Point([proof[3],proof[2]],[proof[5],proof[4]]);
        if (!Pairing.pairingProd2(Pairing.G1Point(proof[12],proof[13]), Pairing.P2(), Pairing.negate(Pairing.G1Point(20609064990151434522281801391828495775884267027875835350196764558529993842309,17128247148991618105637909745872438177550197803720369707251464582859336158719)), p_rwx)) return false;
        p_ryx = Pairing.G1Point(proof[6],proof[7]);
        if (!Pairing.pairingProd2(Pairing.P1(), Pairing.G2Point([proof[15],proof[14]],[proof[17],proof[16]]), Pairing.negate(p_ryx), Pairing.G2Point([8337633023016044085509959705441909358958116215884397914468273783432815402831,7164439564583697432404385023690826784748600024743609207871936861299495768034],[19470282791470678223105295907300604807631667771612004655159681825193329486355,1806676251539113564926825622044026404903633911554708520609911577363248407403]))) return false;
        versum = Pairing.doadd(p_rvx, p_ryx);
        if (!Pairing.pairingProd3(versum, Pairing.G2Point([265997895764596010286977390654803195652864459494349959677643442751082762244,828157263472895008652515769125120900337032787056198181561135770937510333668],[13742452053963840384347720803385820847527609777928526673352811240950319206353,9901395572930556189435976225056932557250673715919574106904439078899413447591]), Pairing.G1Point(16768920473987968002135890402294884879514412197119564701828919859998199919106,8363459255946919212211044714384973780569591782411571763242313939700991589854), Pairing.G2Point([proof[3],proof[2]],[proof[5],proof[4]]), Pairing.negate(Pairing.G1Point(proof[18],proof[19])), Pairing.P2())) return false;
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(10458610476322893784956501230700407420053886625258616184711914339917298575905,17874454966023733582299872397378742232617626046543979752183490730091807278325), io[0]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(8606350022649042621562660536074014812466774671799694981231586476726584696198,4844085583750298452812839303220388021605040506415778058361990617689228577411), io[1]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(10082065064799202535219125553245359067937773719377503926986441753848054526671,10500486150881142002199911897666778476442017863187507938441369903359883958043), io[2]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(10196306204272577805384779256671525472748825758432052505886871807936876815579,15414242796307096582222579733486679172167461425464346166144103513338659225985), io[3]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(11827522657863871909907945277342299371799372068997567529908668726251775138177,9827453859650443753087146923314965188208964159556454454683237568049036682582), io[4]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(7035886129850812926288160294298100300566848722887976669208108152755822792440,15321482406653948852404980973408085464545572127015430373010743656633077384994), io[5]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(16610555077302466920323065941157987260996476679377316382011569280495711874492,3998344732855608150985110903633301407951139025255120677768684175911737512019), io[6]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(19867151573452546645296625598835001008567639156256109203302221239425818653939,13670093691893365742481459433478097774412989902181799295988870912181518007623), io[7]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(14414337181641203669457268034393167706383166379987066350329183054817866832249,3231594730706068339190415800983683032856241474733785798317060154703697147903), io[8]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(9166586356018832486733028021719373224647529692959376420519155629494013033981,598482612030561347382819857283989387772271655119679126449364144524287917376), io[9]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(4099180010741264212538786155715986275276496587769014482832696325158282304453,7519586615345966660687282563918255133908311042672531423727368932530912414956), io[10]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.domul(Pairing.G1Point(10910521097009763242620062423172149063775184457170040078513738071971960746919,21847871939983876953582062181047911231578076715212906918393248260220493442060), io[11]));
        p_ryx = Pairing.doadd(p_ryx, Pairing.G1Point(16455285951373010292726845688246949232644942738064087384651673016641389749084,78704162005271353967180711859494212493216335496031829755794024370708213100));
        if (!Pairing.pairingProd3(Pairing.G1Point(proof[20],proof[21]), Pairing.G2Point([4363528002623066123977346689056498338470562977428608729514534366837762767448,12116051385560481998675201877072850391571398553484652572360932370698827153046],[16024064698268561066053767248798348888159593232164882052366305497339852590771,16605130899727754949063227229986901507027777260877163035937707559595113683102]), p_ryx, Pairing.P2(), Pairing.negate(p_rvx), p_rwx)) return false;
        return true;
    }
}       
    
