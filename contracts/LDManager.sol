import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IMint.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LDManager {
  IUniswapV2Router02 public Router;
  address public token;
  address public tokenMinter;
  address public treasury;

  constructor(
    address _Router,
    address _token,
    address _tokenMinter,
    address _treasury
  )
   public
  {
     Router = IUniswapV2Router02(_Router);
     token = _token;
     tokenMinter = _tokenMinter;
     treasury = _treasury;
  }

  function addLiquidity() external payable {
     //get price
     uint256 tokenAmount = getTokenPrice(msg.value);
     // mint tokens
     IMint(tokenMinter).mint(address(this), tokenAmount);
     // approve token transfer to cover all possible scenarios
     IERC20(token).approve(address(Router), tokenAmount);
     // add the liquidity
     Router.addLiquidityETH{value: msg.value}(
       token,
       tokenAmount,
       0, // slippage is unavoidable
       0, // slippage is unavoidable
       treasury,
       block.timestamp + 15 minutes
     );
  }


  function getTokenPrice(uint256 _ethAmount) public view returns(uint256) {
      address[] memory path = new address[](2);
      path[0] = Router.WETH();
      path[1] = address(token);
      uint256[] memory res = Router.getAmountsOut(_ethAmount, path);
      return res[1];
  }

  receive() external payable {}
}
