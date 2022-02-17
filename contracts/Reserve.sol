pragma solidity ^0.6.2;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Reserve {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public token;
  IUniswapV2Router02 public Router;
  address public weth;

  mapping (address => uint256) public depositOf;

  constructor(
    address _token,
    address _router,
    address _weth
    )
    public
  {
    token = IERC20(_token);
    Router = IUniswapV2Router02(_router);
    weth = _weth;
  }

  // return ETH amount
  function currentRate(uint256 _amount) public view returns(uint256 ethAmount){
    address[] memory path = new address[](2);
    path[0] = address(token);
    path[1] = Router.WETH();
    uint256[] memory res = Router.getAmountsOut(_amount, path);
    ethAmount = res[1];
  }

  function deposit(uint256 _amount) external {
    token.safeTransferFrom(msg.sender, address(this), _amount);
    depositOf[msg.sender] = depositOf[msg.sender].add(_amount);
  }

  function convert(uint256 _amount) external {
    require(depositOf[msg.sender] >= _amount, "Not enough deposit");
    depositOf[msg.sender] = depositOf[msg.sender].sub(_amount);
    uint256 ethAmount = currentRate(_amount);
    require(address(this).balance >= ethAmount, "Not enough eth");
    payable(msg.sender).transfer(ethAmount);
  }

  function withdraw(uint256 _amount) external {
    require(depositOf[msg.sender] >= _amount, "Not enough deposit");
    token.safeTransfer(msg.sender, _amount);
    depositOf[msg.sender] = depositOf[msg.sender].sub(_amount);
  }

  fallback() external payable {}
}
