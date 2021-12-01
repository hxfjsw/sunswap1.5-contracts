pragma solidity ^0.5.8;

import "./SunswapExchange.sol";
import "../interfaces/ISunswapExchange.sol";
import "../utils/Ownable.sol";


contract SunswapFactory is Ownable {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  event NewExchange(address indexed token, address indexed exchange);
    event NewFeeTo(address feeTo);
    event NewFeeRate(uint256 feeTo);

  address public exchangeTemplate;
  uint256 public tokenCount;
  mapping (address => address) internal token_to_exchange;
  mapping (address => address) internal exchange_to_token;
  mapping (uint256 => address) internal id_to_token;
  address public feeTo;
  uint256 public feeToRate;
  //5 maybe

  /***********************************|
  |         Factory Functions         |
  |__________________________________*/

  function initializeFactory(address template) public {
    require(exchangeTemplate == address(0), "exchangeTemplate already set");
    require(template != address(0), "illegal template");
    exchangeTemplate = template;
  }
  
  function createExchange(address token) public returns (address) {
    require(token != address(0), "illegal token");
    require(exchangeTemplate != address(0), "exchangeTemplate not set");
    require(token_to_exchange[token] == address(0), "exchange already created");
    SunswapExchange exchange = new SunswapExchange();
    exchange.setup(token);
    token_to_exchange[token] = address(exchange);
    exchange_to_token[address(exchange)] = token;
    uint256 token_id = tokenCount + 1;
    tokenCount = token_id;
    id_to_token[token_id] = token;
    emit NewExchange(token, address(exchange));
    return address(exchange);
  }

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  function getExchange(address token) public view returns (address) {
    return token_to_exchange[token];
  }

  function getToken(address exchange) public view returns (address) {
    return exchange_to_token[exchange];
  }

  function getTokenWithId(uint256 token_id) public view returns (address) {
    return id_to_token[token_id];
  }

  function setFeeTo(address _feeTo) public onlyOwner {
    require(_feeTo != address(0), "already started fee burn");
    feeTo = _feeTo;
    emit NewFeeTo(_feeTo);
  }

  function setFeeToRate(uint256 _feeToRate) public onlyOwner {
    feeToRate = _feeToRate;
    emit NewFeeRate(_feeToRate);
  }

}

