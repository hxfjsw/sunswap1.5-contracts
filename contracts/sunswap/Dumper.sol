pragma solidity ^0.5.8;

import "../interfaces/ISunswapFactory.sol";
import "../interfaces/ISunswapExchange.sol";
import "../interfaces/ITRC20.sol";
import "../utils/Ownable.sol";

pragma experimental ABIEncoderV2;


contract Dumper is Ownable {
    address public factory;
    address public sunTkn;
    address public blackHole = address(0x01);

    uint256 public totalBurnedSun;

    event SunToBurn(uint256 added, uint256 total);
    event SunBurned(uint256 added, uint256 total);
    event LpDump(uint256 lpAmount, uint256 lptrxAmount, uint256 lptokenAmont, uint256 totalTrxAmount);

    event Rescue(address indexed dst, uint sad);
    event RescueToken(address indexed dst, address indexed token, uint sad);

    constructor(address _factory, address _sunTkn) public{
        factory = _factory;
        sunTkn = _sunTkn;
    }

    function dumpTrxToSun() public {
        address payable sunExchange = ISunswapFactory(factory).getExchange(sunTkn);
        //uint256 addedSun = ISunswapExchange(sunExchange).trxToTokenSwapInput.value(address(this).balance)(1, block.timestamp + 10);
        uint256 addedSun;
        (bool isSuccess,bytes memory data) = executeTransaction(sunExchange, address(this).balance, "trxToTokenSwapInput(uint256,uint256)", abi.encode(1, block.timestamp + 10));
        if (isSuccess) {
            addedSun = abi.decode(data, (uint256));
            emit SunToBurn(addedSun, ITRC20(sunTkn).balanceOf(address(this)));
        }
    }


    function burnSun() public onlyOwner {
        uint256 sunBal = ITRC20(sunTkn).balanceOf(address(this));
        totalBurnedSun = totalBurnedSun + sunBal;

        ITRC20(sunTkn).transfer(blackHole, sunBal);

        emit SunBurned(sunBal, totalBurnedSun);
    }


    function dumpLpsToTrx(address payable exchange) public {
        address token = getToken(exchange);
        if (token == address(0)) {
            return;
        }
        ISunswapExchange(exchange).updateKLast();
        uint256 lpBalance = ITRC20(exchange).balanceOf(address(this));
        if (lpBalance > 0) {
            //(uint256 lpTrxAmount,uint256 lpTokenAmount) = ISunswapExchange(exchange).removeLiquidity(lpBalance, 1, 1, block.timestamp + 10);
            (bool isSuccess, bytes memory data) = executeTransaction(exchange, 0, "removeLiquidity(uint256,uint256,uint256,uint256)", abi.encode(lpBalance, 1, 1, block.timestamp + 10));
            if (isSuccess) {
                (uint256 lpTrxAmount,uint256 lpTokenAmount) = abi.decode(data, (uint256, uint256));
                //balanceOf
                (isSuccess, data) = token.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
                uint tokenCnt = 0;
                if (data.length != 0) {
                    tokenCnt = abi.decode(data, (uint256));
                }
                if (tokenCnt > 0 && token != sunTkn) {
                    (isSuccess, data) = executeTransaction(token, 0, "approve(address,uint256)", abi.encode(exchange, tokenCnt));
                    if (isSuccess) {
                        (isSuccess, data) = executeTransaction(exchange, 0, "tokenToTrxSwapInput(uint256,uint256,uint256)", abi.encode(tokenCnt, 1, block.timestamp + 10));
                        if (isSuccess) {
                            uint256 trxBought = abi.decode(data, (uint256));
                            emit LpDump(lpBalance, lpTrxAmount, lpTokenAmount, lpTrxAmount + trxBought);
                        }
                    }
                } else {
                    emit LpDump(lpBalance, lpTrxAmount, lpTokenAmount, lpTrxAmount);
                }
            }

        }

    }


    function dumpLpsToTrx(address[] memory _exchange) public {
        uint256 _exchangeCount = _exchange.length;
        for (uint256 i = 0; i < _exchangeCount; i++) {
            dumpLpsToTrx(toPayable(_exchange[i]));
        }
    }


    function getToken(address _exchangeAddr) public view returns (address) {
        return ISunswapFactory(factory).getToken(_exchangeAddr);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function() external payable {

    }


    function executeTransaction(address target, uint value, string memory signature, bytes memory data) internal returns (bool success, bytes memory returnData) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        (success, returnData) = target.call.value(value)(callData);
    }


    /**
* @dev rescue simple transfered TRX.
*/
    function rescue(address payable to_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");


        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }
    /**
     * @dev rescue simple transfered unrelated token.
     */
    function rescue(address to_, ITRC20 token_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }


}

