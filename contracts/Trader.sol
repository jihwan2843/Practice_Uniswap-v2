// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router01.sol";

contract Trader {
    address ROUTER;
    address FACTORY;
    address constant WETH;

    constructor() {}

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) external payable {
        // 먼저 유저로부터 두 토큰을 받는다
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // ROUTER 컨트랙트에 유동성을 공급하기 위해 두 토큰을 전송하기 전에
        // approve를 실행을 해주어야 두 토큰을 전송 할 수 있다
        IERC20(tokenA).approve(ROUTER, amountA);
        IERC20(tokenB).approve(ROUTER, amountB);

        // UniswapV2Router01 컨트랙트에 있는 addLiquidity() 함수를 사용하여 유동성을 추가한다
        // 이 예제에서는 amountMin을 0으로 설정한다
        IUniswapV2Router01(ROUTER).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            0,
            0,
            msg.sender,
            block.timestamp + 10
        );
    }

    function addLiquidityETH(
        address token,
        uint amountDesired
    ) external payable {
        // 유저로부터 토큰 받기
        IERC20(token).transferFrom(msg.sender, address(this), amountDesired);

        // approve 실행하기
        IERC20(token).approve(ROUTER, amountDesired);

        // 유동성 공급하기
        IUniswapV2Router01(ROUTER).addLiquidityETH{value: msg.value}(
            token,
            amountDesired,
            0,
            0,
            msg.sender,
            block.timestamp + 10
        );
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity
    ) external {
        address lp = IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);

        // LP토큰을 가지고 오기
        IERC20(lp).transferFrom(msg.sender, address(this), liquidity);

        // approve 실행하기
        IERC20(lp).approve(ROUTER, liquidity);

        // 유동성 제거하기
        IUniswapV2Router01(ROUTER).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            0,
            0,
            block.timestamp + 10
        );
    }

    function removeLiquidityETH(address token, uint liquidity) external {
        address lp = IUniswapV2Factory(FACTORY).getPair(token, WETH);

        // lp토큰 가지고 오기
        IERC20(lp).transferFrom(msg.sender, address(this), liquidity);

        // approve 실행하기
        IERC20(lp).approve(ROUTER, liquidity);

        // 유동성 제거하기
        IUniswapV2Router01(ROUTER).removeLiquidityETH{value: msg.value}(
            token,
            liquidity,
            0,
            0,
            block.timestamp + 10
        );
    }

    function swapExactTokenToToken(
        uint amountIn,
        address[] calldata path
    ) external {
        // 유저로부터 input 토큰을 받기
        address inputToken = path[0];
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);

        // approve 하기
        IERC20(inputToken).approve(ROUTER, amountIn);

        // swap 하기
        IUniswapV2Router01(ROUTER).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            msg.sender,
            block.timestamp + 10
        );
    }

    function swapTokenToExactToken(
        uint amountOut,
        uint amountInMax,
        address[] calldata path
    ) external {
        // 예상 input 토큰 수량 얻기
        uint[] memory amountsIn = IUniswapV2Router01(ROUTER).getAmountsIn(
            amountOut,
            path
        );
        uint amountIn = amountsIn[0];

        // check
        require(amountIn < amountInMax, "exceed amountInMax");

        // 유저로부터 input 토큰을 받기
        address inputToken = path[0];
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);

        // approve 하기
        IERC20(inputToken).approve(ROUTER, amountIn);

        // swap 하기
        IUniswapV2Router01(ROUTER).swapTokensForExactTokens(
            amountOut,
            amountIn,
            path,
            msg.sender,
            block.timestamp + 10
        );
    }

    function swapExactETHToToken(address[] calldata path) external payable {
        // path 경로 체크
        require(path[0] == WETH, "invalid path");
        require(msg.value > 0, "zero msg.value");

        // swap 하기
        IUniswapV2Router01(ROUTER).swapExactETHForTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp + 10
        );
    }

    function swapETHToExactToken() external payable {
        // path 경로 체크
        require(path[0] == WETH, "invalid path");
        require(msg.value > 0, "zero msg.value");

        // 필요한 예상 ETH 수량
        // amountIn[0]은 필요한 ETH 수량
        uint[] memory amountsIn = IUniswapV2Router01(ROUTER).getAmountsIn(
            amountOut,
            path
        );

        // swap 하기
        IUniswapV2Router01(ROUTER).swapETHForExactTokens{value: amountsIn[0]}(
            amountOut,
            path,
            msg.sender,
            block.timestamp + 10
        );

        // 이 함수가 실행하기 전에 이미 ETH는 전송 되었기 때문에
        // 함수 실행 도중 msg.value와 예상 ETH수량이 다를 수도 있다
        // msg.value - amountsIn[0] 만큼 환불하기
        if (msg.value > amountsIn[0]) {
            (bool success, ) = (msg.sender).call{
                value: msg.value > amountsIn[0]
            }(new bytes(0));
            require(success, "fail to transfer ETH");
        }
    }

    // Token -> ETH
    // Router.swapTokensForExactETH
    // Router.swapExactTokensForExactETH

    function swapExactTokenToETH(
        uint amountIn,
        address[] calldata path
    ) external {
        address inputToken = path[0];
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(inputToken).approve(ROUTER, amountIn);
        IUniswapV2Router01(ROUTER).swapExactTokensForETH(
            amountIn,
            0,
            path,
            msg.sender,
            block.timestamp + 10
        );
    }

    function swapTokenToExactETH(
        uint amountOut,
        address[] calldata path
    ) external {
        uint[] amounts = UniswapV2Router01(ROUTER).getAmountsIn(
            amountOut,
            path
        );
        uint amountIn = amounts[0];
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(inputToken).approve(ROUTER, amountIn);
        IUniswapV2Router01(ROUTER).swapTokensForExactETH(
            amountOut,
            0,
            path,
            msg.sender,
            block.timestamp + 10
        );
    }
}
