pragma solidity ^0.5.8;

interface ISunswapFactory {
    event NewExchange(address indexed token, address indexed exchange);

    function initializeFactory(address template) external;
    function createExchange(address token) external returns (address payable);
    function getExchange(address token) external view returns (address payable);
    function getToken(address token) external view returns (address);
    function getTokenWihId(uint256 token_id) external view returns (address);

    function feeTo() external view returns (address);

    function feeToRate() external view returns (uint256);
}

/**
 * @title TRC20 interface
 */
interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma experimental ABIEncoderV2;







/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    function sqrt(uint256 a) internal pure returns (uint256 b) {
        if (a > 3) {
            b = a;
            uint256 x = a / 2 + 1;
            while (x < b) {
                b = x;
                x = (a / x + x) / 2;
            }
        } else if (a != 0) {
            b = 1;
        }

    }
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }


}



contract ValuesAggregator  {
    using SafeMath for uint256;
    address public factory;
    constructor(address _factory) public{
        factory = _factory;
    }

    struct userInfos{
        address exchange;
        uint256 token_amount;
        uint256 trx_amount;
        uint256 uni_amount;
        uint256 totalSupply;
    }

    struct tokenBalance{
        address token_addr;
        uint256 token_amount;
    }

    function getToken(address _exchangeAddr) public view returns (address) {
        return ISunswapFactory(factory).getToken(_exchangeAddr);
    }
    function getExchange(address token) public  view returns (address){
        return ISunswapFactory(factory).getExchange(token);
    }

    function getPool(address _user ,address[] memory  _exchange) public view
    returns(uint256[] memory _token,uint256[] memory _trx,uint256[] memory _uniToken,uint256[] memory _totalsupply){
        uint256 _exchangeCount = _exchange.length;
        _token =  new uint256[](_exchangeCount);
        _trx = new uint256[](_exchangeCount);
        _uniToken = new uint256[](_exchangeCount);
        _totalsupply = new uint256[](_exchangeCount);

        for(uint256 i = 0; i< _exchangeCount; i++){
            address token = getToken(_exchange[i]);
            uint256 uni_amount = ITRC20(_exchange[i]).balanceOf(_user);
            uint256 token_reserve = ITRC20(token).balanceOf(_exchange[i]);
            uint256 total_liquidity =  ITRC20(_exchange[i]).totalSupply();
            uint256 trx_amount = 0;
            uint256 token_amount = 0;
            if(total_liquidity > 0){
                trx_amount = uni_amount.mul(_exchange[i].balance) / total_liquidity;
                token_amount = uni_amount.mul(token_reserve) / total_liquidity;
            }
            _token[i] = token_amount;
            _trx[i] = trx_amount;
            _uniToken[i] = uni_amount;
            _totalsupply[i] = total_liquidity;
        }
    }

    function getPool2(address _user ,address[] memory  _exchange) public view returns(userInfos[] memory info){
        uint256 _exchangeCount = _exchange.length;
        info = new userInfos[](_exchangeCount);
        for(uint256 i = 0; i< _exchangeCount; i++){
            address token = getToken(_exchange[i]);
            // _exchange.balanceOf(user)
            uint256 uni_amount = ITRC20(_exchange[i]).balanceOf(_user);
            // token.balanceOf(_exchange)
            uint256 token_reserve = ITRC20(token).balanceOf(_exchange[i]);
            // _exchange.totalSupply
            uint256 total_liquidity =  ITRC20(_exchange[i]).totalSupply();
            uint256 trx_amount = 0;
            uint256 token_amount = 0;
            if(total_liquidity > 0){
                trx_amount = uni_amount.mul(_exchange[i].balance) / total_liquidity;
                token_amount = uni_amount.mul(token_reserve) / total_liquidity;
            }
            info[i] = userInfos(address(_exchange[i]),token_amount,trx_amount,uni_amount, total_liquidity);
        }

    }

    function getBalance2(address _user , address[] memory _tokens) public view returns(tokenBalance[] memory info){
        uint256 _tokenCount = _tokens.length;
        info = new tokenBalance[](_tokenCount);
        for(uint256 i = 0; i< _tokenCount; i++){
            uint256 token_amount = ITRC20(_tokens[i]).balanceOf(_user);
            info[i] = tokenBalance(_tokens[i],token_amount);
        }
    }

    function getBalance(address _user , address[] memory _tokens) public view returns(uint256[] memory info){
        uint256 _tokenCount = _tokens.length;
        info = new uint256[](_tokenCount);
        for(uint256 i = 0; i< _tokenCount; i++){
            uint256 token_amount = 0;
            if(address(0) == _tokens[i]){
                token_amount = address(_user).balance;
            }else{
                ( bool success, bytes memory data) = _tokens[i].staticcall(abi.encodeWithSelector(0x70a08231, _user));
                token_amount = 0;
                if(data.length != 0){
                    token_amount = abi.decode(data,(uint256));
                }
            }
            info[i] = uint256(token_amount);
        }
    }

    function getSingleInfo(address _user, address _token) public view returns(
        address _exchangeAddr,
        uint256 _allowance,
        uint256 _exTokenBalace,
        uint256 _exTrxBalance,
        uint256 _totalLiquidity,
        uint256 _userUniAmount,
        uint256 _userTrxAmount,
        uint256 _userTokenAmount) {
        _exchangeAddr = getExchange(_token);
        if(_exchangeAddr != address(0)){
            _allowance = ITRC20(_token).allowance( _user , _exchangeAddr);
            _totalLiquidity = ITRC20(_exchangeAddr).totalSupply();
            _exTokenBalace = ITRC20(_token).balanceOf(_exchangeAddr);
            _exTrxBalance = _exchangeAddr.balance;
            _userUniAmount = ITRC20(_exchangeAddr).balanceOf(_user);
            
            if(_totalLiquidity > 0){
                _userTrxAmount = _userUniAmount.mul(_exTrxBalance) / _totalLiquidity;
                _userTokenAmount = _userUniAmount.mul(_exTokenBalace) / _totalLiquidity;
            }
        }      
    }
}



