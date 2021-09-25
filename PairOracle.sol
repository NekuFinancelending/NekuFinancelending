pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./UniswapOracle.sol";

contract PairOracle is PriceOracle, Operator {
    using SafeMath for uint256;
    struct OracleInfo {
        bool enable;
        uint256 stable;
        address pair;
        address tokenA;
        address tokenB;
        uint256 decimalA;
        uint256 price;
    }
	struct RouterInfo {
        bool enable;
        uint256 underlyingDecimals;
		address pair;
		address pair2;
	}
    address public baseToken;
    uint256 public baseUnderlyingDecimals;
	bool public baseEnable;
    mapping(address => uint256) public oraclemap;
	mapping(address => uint256) public routermap;
    OracleInfo[] public oracles;
	RouterInfo[] public routers;
	uint256 public interval = 60;
	uint256 public updateTime;
	
	constructor() public {
	    setBaseToken(0x8153303F72aB12f13180c946723BCACAe05A4C4a, 6, true);
	    
	    updateOracle(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, 1000000, address(0), address(0), 18, true);
	    updateOracle(0x384704557F73fBFAE6e9297FD1E6075FC340dbe5, 0, 0x5D9ab5522c64E1F6ef5e3627ECCc093f56167818, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 18, true);
	    updateOracle(0x2a44696DDc050f14429bd8a4A05c750C6582bF3b, 0, 0xB44a9B6905aF7c801311e8F4E76932ee959c663C, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 6, true);
	    updateOracle(0xFE1b71BDAEE495dCA331D28F5779E87bd32FbE53, 0, 0x80A16016cC4A2E6a2CACA8a4a498b1699fF0f844, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 18, true);
	    updateOracle(0xA0D8DFB2CC9dFe6905eDd5B71c56BA92AD09A3dC, 0, 0x639A647fbe20b6c8ac19E48E2de44ea792c62c5C, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 18, true);
	    updateOracle(0xdb66BE1005f5Fe1d2f486E75cE3C50B52535F886, 0, 0x6bD193Ee6D2104F14F94E2cA6efefae561A4334B, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 18, true);
	    updateOracle(0xe537f70a8b62204832B8Ba91940B77d3f79AEb81, 0, 0x98878B06940aE243284CA214f92Bb71a2b032B8A, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 18, true);
	    updateOracle(0x5964a6C85a2F88e01F28F066eA36Dc158864c638, 0, 0xB497c3E9D27Ba6b1fea9F1b941d8C79E66cfC9d6, 0xE3F5a90F9cb311505cd691a46596599aA1A0AD7D, 18, true);
	    updateOracle(0xfb1d0D6141Fc3305C63f189E39Cc2f2F7E58f4c2, 0, 0x2bF9b864cdc97b08B6D79ad4663e71B8aB65c45c, 0x5D9ab5522c64E1F6ef5e3627ECCc093f56167818, 18, true);
	    
	    updateRouter(0xBC4a19345c598D73939b62371cF9891128ecCB8B, 18, true, 0xe537f70a8b62204832B8Ba91940B77d3f79AEb81, address(0));
	    updateRouter(0xDF19d746b5Ab2B7b040dAf0eC3341000cFE17bae, 18, true, 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, address(0));
	    updateRouter(0x3631dE81f1098dF530015a97b092bdFfF7e93Ea8, 18, true, 0x384704557F73fBFAE6e9297FD1E6075FC340dbe5, address(0));
	    updateRouter(0x1eA64325E194E0520a8E219c4d1227681CdBb2fe, 6, true, 0x2a44696DDc050f14429bd8a4A05c750C6582bF3b, address(0));
	    updateRouter(0x70Faf3509dC8320FAFfb40666D717224B26Af0Db, 18, true, 0xFE1b71BDAEE495dCA331D28F5779E87bd32FbE53, address(0));
	    updateRouter(0xB5Dc005D89D0b4D0bC4a9459C7f77A403e9bFEea, 18, true, 0xA0D8DFB2CC9dFe6905eDd5B71c56BA92AD09A3dC, address(0));
	    updateRouter(0xC7dEC270bFfC808458DCF687A378958aFe7494Ea, 18, true, 0xfb1d0D6141Fc3305C63f189E39Cc2f2F7E58f4c2, 0x384704557F73fBFAE6e9297FD1E6075FC340dbe5);
	    updateRouter(0xBd1Bf670692AacBBC96F0CBdD2F868F20E8f3296, 18, true, 0xdb66BE1005f5Fe1d2f486E75cE3C50B52535F886, address(0));
	    updateRouter(0xFd4224A5358162d5d4F97C3C51966383642F0553, 18, true, 0x5964a6C85a2F88e01F28F066eA36Dc158864c638, address(0));
	}
    
	function checkOracle(address _oracle) public view returns(bool){
		uint256 index = oraclemap[_oracle];
		if (index == 0) {
			return false;
		}
		return oracles[index - 1].enable;
	}
	
	function updateOracle(address _pair, uint256 _stable, address _tokenA, address _tokenB, uint256 _decimalA, bool _enable) public onlyOperator {
		if (oraclemap[_pair] == 0) {
            oraclemap[_pair] = oracles.length + 1;
            oracles.push(OracleInfo(_enable, _stable, _pair, _tokenA, _tokenB, _decimalA, 0));
        } else {
            uint256 index = oraclemap[_pair] - 1;
            oracles[index].enable = _enable;
            oracles[index].pair = _pair;
            oracles[index].tokenA = _tokenA;
            oracles[index].tokenB = _tokenB;
            oracles[index].stable = _stable;
            oracles[index].decimalA = _decimalA;
        }
	}
    
    function updateRouter(address _cToken, uint256 _underlyingDecimals, bool _enable, address _pair, address _pair2) public onlyOperator {
        if (routermap[_cToken] == 0) {
			routermap[_cToken] = routers.length + 1;
			routers.push(RouterInfo(_enable, _underlyingDecimals, _pair, _pair2));
		} else {
			uint256 index = routermap[_cToken] - 1;
			routers[index].enable = _enable;
			routers[index].underlyingDecimals = _underlyingDecimals;
			routers[index].pair = _pair;
			routers[index].pair2 = _pair2;
		}
    }
    
    function setBaseToken(address _baseToken, uint256 _baseUnderlyingDecimals, bool _enable) public onlyOperator {
        baseToken = _baseToken;
        baseUnderlyingDecimals = _baseUnderlyingDecimals;
		baseEnable = _enable;
    }
    
    function setInterval(uint256 _interval) external onlyOperator {
        interval = _interval;
    }
    
    function getBalance(address token, address account) view public returns(uint256) {
        if (token == address(0)) {
            return account.balance;
        }
        return IUniswapV2Pair(token).balanceOf(account);
    }
    
    function getPriceFromPair(address pair, address tokenA, address tokenB, uint256 amountA) view public returns(uint256) {
        uint256 balanceA = getBalance(tokenA, pair);
        uint256 balanceB = getBalance(tokenB, pair);
        if (balanceA == 0) {
            return 0;
        }
        return amountA.mul(balanceB).div(balanceA);
    }
    
    function update() external onlyOperator {
        require(updateTime + interval <= block.timestamp, "update too fast");
        for(uint256 i = 0; i < oracles.length; i++){
            OracleInfo storage info = oracles[i];
            if(info.enable && info.stable == 0){
                info.price = getPriceFromPair(info.pair, info.tokenA, info.tokenB, 10**info.decimalA);
            }
        }
        updateTime = block.timestamp;
    }
    
    function _getOraclePrice(OracleInfo memory oracle, uint256 amount) pure internal returns (uint256) {
        if (!oracle.enable) {
            return 0;
        }
        uint256 price = oracle.stable > 0 ? oracle.stable : oracle.price;
        return price.mul(amount).div(10**oracle.decimalA);
    }
    
    function getUnderlyingPrice(CToken _cToken) external view returns (uint256) {
        if(address(_cToken) == baseToken){
            if(!baseEnable){
                return 0;
            }
            return 10 ** (36 - baseUnderlyingDecimals);
        }
        uint256 i = routermap[address(_cToken)];
        if(i == 0){
            return 0;
        }
        RouterInfo memory router = routers[i-1];
        if(!router.enable){
            return 0;
        }
		uint256 price = 10 ** router.underlyingDecimals;
		if (!checkOracle(router.pair)) {
			return 0;
		}
		OracleInfo memory oracle = oracles[oraclemap[router.pair] - 1]; 
		price = _getOraclePrice(oracle, 10**router.underlyingDecimals);
		if (router.pair2 != address(0)) {
		    if (!checkOracle(router.pair2)) {
		    	return 0;
		    }
		    oracle = oracles[oraclemap[router.pair2] - 1];
		    price = _getOraclePrice(oracle, price);
		}
		return price * 10 ** (36 - baseUnderlyingDecimals - router.underlyingDecimals);
    }
}