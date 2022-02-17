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

  // helper for get rate
  function currentRate(address _from, address _to, uint256 _amount)
    public
    view
    returns(uint256)
  {
    address[] memory path = new address[](2);
    path[0] = _from;
    path[1] = _to;

    uint256[] memory res = Router.getAmountsOut(_amount, path);
    return res[1];
  }

  // deposit to reserve
  function deposit(uint256 _amount) external {
    token.safeTransferFrom(msg.sender, address(this), _amount);
    depositOf[msg.sender] = depositOf[msg.sender].add(_amount);
  }

  // convert deposit to eth
  function convert(uint256 _amount) external {
    require(depositOf[msg.sender] >= _amount, "Not enough deposit");
    depositOf[msg.sender] = depositOf[msg.sender].sub(_amount);
    uint256 ethAmount = currentRate(address(token), weth, _amount);
    require(address(this).balance >= ethAmount, "Not enough eth");
    payable(msg.sender).transfer(ethAmount);
  }

  // withdraw deposit
  function withdraw(uint256 _amount) external {
    require(depositOf[msg.sender] >= _amount, "Not enough deposit");
    token.safeTransfer(msg.sender, _amount);
    depositOf[msg.sender] = depositOf[msg.sender].sub(_amount);
  }

  // buy tokens via eth
  function buy() external payable {
    require(msg.value > 0, "Zero eth");
    uint256 tokenAmount = currentRate(weth, address(token), msg.value);
    token.safeTransfer(msg.sender, tokenAmount);
  }
}
