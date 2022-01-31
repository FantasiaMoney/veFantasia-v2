pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IBurn.sol";
import "./interfaces/IMint.sol";

contract TokenToVToken {
  using SafeERC20 for IERC20

  IERC20 public token;
  address public vToken;

  constructor(address _token, address _vToken) public {
    token = IERC20(_token);
    vToken = _vToken;
  }

  function convert(address _to, uint256 _amount) external {
    token.safeTransferFrom(msg.sender, address(this), _amount);
    IBurn(token).burn(_amount);
    IMint(vToken).mint(_to, _amount);
  }
}
