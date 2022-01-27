pragma solidity ~0.8.9;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IERC20.sol';

contract SwapSpreadProcessor is IUniswapV2Callee {
  IUniswapV2Router02 immutable uRouter;
  IUniswapV2Router02 immutable sRouter;

  constructor(address _uRouter, address _sRouter) {
    uRouter = IUniswapV2Router02(_uRouter);
    sRouter = IUniswapV2Router02(_sRouter);
  }

  function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
      address[] memory path = new address[](2);
      // uni2sushi == true: borrow (using flash swap) from uniswap and swap it in sushiswap
      // uni2sushi == false: borrow (using flash swap) from sushiswap and swap it in uniswap
      (bool uni2sushi, uint amountRequired, uint deadline) = abi.decode(_data, (bool, uint, uint));
      // unidirectional strategy
      assert(_amount0 == 0 || _amount1 == 0);
      if (_amount0 == 0) {
        uint amountEntryToken =_amount1;
        address profitWallet = _sender;
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        IERC20 entryToken = IERC20(token1);
        IERC20 exitToken = IERC20(token0);
        path[0] = token1; 
        path[1] = token0;
        if (uni2sushi) {
           entryToken.approve(address(sRouter), amountEntryToken);  
           uint amountReceived = sRouter.swapExactTokensForTokens(amountEntryToken, 0, path, address(this), deadline)[1];
           assert(amountReceived > amountRequired);
           exitToken.transfer(msg.sender, amountRequired);      
           exitToken.transfer(profitWallet, amountReceived-amountRequired);   
        }
        else {
           entryToken.approve(address(uRouter), amountEntryToken);  
           uint amountReceived = uRouter.swapExactTokensForTokens(amountEntryToken, 0, path, address(this), deadline)[1];
           assert(amountReceived > amountRequired);
           exitToken.transfer(msg.sender, amountRequired);      
           exitToken.transfer(profitWallet, amountReceived-amountRequired);   
        }
      } else {
        uint amountEntryToken = _amount0;
        address profitWallet = _sender;
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        IERC20 entryToken = IERC20(token0);
        IERC20 exitToken = IERC20(token1);
        path[0] = token0;
        path[1] = token1;
        if (uni2sushi) {
           entryToken.approve(address(sRouter), amountEntryToken);  
           uint amountReceived = sRouter.swapExactTokensForTokens(amountEntryToken, 0, path, address(this), deadline)[1];
           assert(amountReceived > amountRequired);
           exitToken.transfer(msg.sender, amountRequired);
           exitToken.transfer(profitWallet, amountReceived-amountRequired);   
        }
        else {
           entryToken.approve(address(uRouter), amountEntryToken);  
           uint amountReceived = uRouter.swapExactTokensForTokens(amountEntryToken, 0, path, address(this), deadline)[1];
           assert(amountReceived > amountRequired);
           exitToken.transfer(msg.sender, amountRequired);
           exitToken.transfer(profitWallet, amountReceived-amountRequired);   
        }
      }
  }
}
