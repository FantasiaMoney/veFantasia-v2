pragma solidity ^0.6.2;

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISale.sol";
import "./interfaces/IConvert.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/IDepositsDB.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Fetch is Ownable {
  using SafeMath for uint256;

  address public WETH;

  address public dexRouter;

  address public token;

  address public vToken;

  address public sale;

  address public reserve;

  uint256 public percentToDex = 50;

  uint256 public percentToSale = 50;

  uint256 public percentToReserve = 0;

  address public tokenToVToken;

  IDepositsDB public depositsDB;

  /**
  * @dev constructor
  *
  * @param _WETH                  address of Wrapped Ethereum token
  * @param _dexRouter             address of UNI v2 DEX
  * @param _token                 address of token
  * @param _sale                  sale
  * @param _reserve               reserve
  * @param _tokenToVToken         token to vToken converter
  * @param _vToken                not transferable vote token
  * @param _depositsDB            depositsDB contract
  */
  constructor(
    address _WETH,
    address _dexRouter,
    address _token,
    address _sale,
    address _reserve,
    address _tokenToVToken,
    address _vToken,
    address _depositsDB
    )
    public
  {
    WETH = _WETH;
    dexRouter = _dexRouter;
    token = _token;
    sale = _sale;
    reserve = _reserve;
    tokenToVToken = _tokenToVToken;
    vToken = _vToken;
    depositsDB = IDepositsDB(_depositsDB);
  }

  // convert for msg.sender
  function convert() external payable {
    _convertFor(msg.sender);
  }

  // convert for receiver
  function convertFor(address receiver) external payable {
    _convertFor(receiver);
  }

  /**
  * @dev spit ETH input with DEX and Sale
  */
  function _convertFor(address receiver) internal {
    require(msg.value > 0, "zerro eth");
    uint256 balanceBefore = IERC20(vToken).balanceOf(receiver);

    // swap ETH
    swapETHInput(receiver, msg.value);

    // convert remains
    uint256 remains = IERC20(token).balanceOf(address(this));
    IERC20(token).approve(tokenToVToken, remains);
    IConvert(tokenToVToken).convert(receiver, remains);

    uint256 balanceAfter = IERC20(vToken).balanceOf(receiver);

    // update data
    depositsDB.deposit(receiver, balanceBefore, balanceAfter);
  }


 /**
 * @dev swap ETH to token via DEX and Sale
 */
 function swapETHInput(address receiver, uint256 input) internal {
  // get slit %
  (uint256 ethToDex,
   uint256 ethToSale,
   uint256 ethToReserve) = calculateToSplit(input);

  // get tokens from DEX
  if(ethToDex > 0)
    swapETHViaDEX(dexRouter, token, ethToDex);

  // get V tokens from sale
  if(ethToSale > 0)
    swapETHViaSale(receiver, ethToSale);

  // get tokens from reserve
  if(ethToReserve > 0)
    swapETHViaReserve(ethToReserve);
 }

 // helper for swap ETH to vtoken
 function swapETHViaDEX(address routerDEX, address toToken, uint256 amount) internal {
   // SWAP split % of ETH input to token
   address[] memory path = new address[](2);
   path[0] = WETH;
   path[1] = toToken;

   IUniswapV2Router02(routerDEX).swapExactETHForTokens{value:amount}(
     1,
     path,
     address(this),
     block.timestamp + 1800
   );
 }

 // helper for get V tokens from Sale
 function swapETHViaSale(address receiver, uint256 amount) internal {
    ISale(sale).buyFor.value(amount)(receiver);
 }

 // helper for get tokens from Reserve
 function swapETHViaReserve(uint256 amount) internal {
    uint256 tokensAmount = IReserve(reserve).currentRate(WETH, token, amount);
    require(IERC20(token).balanceOf(reserve) >= tokensAmount, "Not enough tokens in reserve");
    IReserve(reserve).buy.value(amount);
 }


 /**
 * @dev return eth amount for dex, sale and platform
 */
 function calculateToSplitETH(uint256 ethInput)
   private
   view
   returns (
     uint256 ethToDex,
     uint256 ethToSale,
     uint256 ethToReserve
   )
 {
   ethToDex = ethInput.div(100).mul(percentToDex);
   ethToSale = ethInput.div(100).mul(percentToSale);
   ethToReserve = ethInput.div(100).mul(percentToReserve);
 }

 /**
 * @dev return split % amount of input
 */
 function calculateToSplit(uint256 ethInput)
   public
   view
   returns(uint256 ethToDex, uint256 ethToSale, uint256 ethToReserve)
 {
   (ethToDex, ethToSale, ethToReserve) = calculateToSplitETH(ethInput);
 }

 /**
 * @dev allow owner update split % with dex, sale and reserve
 */
 function updateSplitPercent(
   uint256 _percentToDex,
   uint256 _percentToSale,
   uint256 _percentToReserve
 )
   external
   onlyOwner
 {
   uint256 total = _percentToDex + _percentToSale + _percentToReserve;
   require(total == 100, "Wrong total");

   percentToDex = _percentToDex;
   percentToSale = _percentToSale;
   percentToReserve = _percentToReserve;
 }

 /**
 * @dev allow owner withdraw eth for case if some eth stuck or was sent accidentally
 */
 function withdraw()
   external
   onlyOwner
 {
   payable(owner()).transfer(address(this).balance);
 }

 fallback() external payable {}
}
