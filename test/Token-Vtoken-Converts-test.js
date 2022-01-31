import { BN, fromWei, toWei } from 'web3-utils'
import ether from './helpers/ether'
import EVMRevert from './helpers/EVMRevert'
import { duration } from './helpers/duration'
import { PairHash } from '../config'


const BigNumber = BN
const timeMachine = require('ganache-time-traveler')

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const ETH_TOKEN_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'

const url = "https://gateway.pinata.cloud/ipfs/QmNVZdcfwaadBzKkDFfGXtqNdKwEbMsQY5xZJxfSxNcK2i/1/"

// real contracts
const UniswapV2Factory = artifacts.require('./UniswapV2Factory.sol')
const UniswapV2Router = artifacts.require('./UniswapV2Router02.sol')
const UniswapV2Pair = artifacts.require('./UniswapV2Pair.sol')
const WETH = artifacts.require('./WETH9.sol')
const TOKEN = artifacts.require('./Token.sol')
const VTOKEN = artifacts.require('./VToken.sol')
const Minter = artifacts.require('./Minter.sol')
const VTokenToToken = artifacts.require('./VTokenToToken.sol')
const TokenToVToken = artifacts.require('./TokenToVToken.sol')
const LDManager = artifacts.require('./LDManager.sol')
const VTokenSale = artifacts.require('./VTokenSale.sol')


let uniFactory,
    uniRouter,
    weth,
    token,
    vToken,
    pair,
    tokenMinter,
    vTokenMinter,
    vTokenToToken,
    tokenToVToken,
    ldManager,
    vTokenSale


contract('Token-Vtoken-Converts-test', function([userOne, userTwo, userThree]) {

  async function deployContracts(){
    // deploy contracts
    weth = await WETH.new()

    uniFactory = await UniswapV2Factory.new(userOne)
    uniRouter = await UniswapV2Router.new(uniFactory.address, weth.address)

    token = await TOKEN.new("DAO", "DAO",toWei(String(1000)))

    // add token liquidity
    await token.approve(uniRouter.address, toWei(String(500)))
    await uniRouter.addLiquidityETH(
      token.address,
      toWei(String(500)),
      1,
      1,
      userOne,
      "1111111111111111111111"
    , { from:userOne, value:toWei(String(500)) })

    pair = await UniswapV2Pair.at(await uniFactory.allPairs(0))

    // depoy vToken
    vToken = await VTOKEN.new("vDAO", "vDAO")

    // deploy minters
    vTokenMinter = await Minter.new(vToken.address)
    tokenMinter = await Minter.new(token.address)

    // transfer tokens ownership to minters
    token.transferOwnership(tokenMinter.address)
    vToken.transferOwnership(vTokenMinter.address)

    // deploy vToken to token converter
    vTokenToToken = await VTokenToToken.new(token.address, vToken.address)

    // deploy token to vToken converter
    tokenToVToken = await TokenToVToken.new(token.address, vToken.address)

    // deploy LD manager
    ldManager = await LDManager.new(uniRouter.address, token.address)

    // deploy V sale
    vTokenSale = await VTokenSale.new(
      token.address,
      vToken.address,
      userOne, // BENEFICIARY
      uniRouter.address
    )

    // update permitions for vTokenMinter
    await vTokenMinter.updatePermittion(vTokenSale.address, true)
    await vTokenMinter.updatePermittion(tokenToVToken.address, true)

    // update permitions for tokenMinter
    await tokenMinter.updatePermittion(ldManager.address, true)
    await tokenMinter.updatePermittion(vTokenToToken.address, true)
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('INIT', function() {
    it('token should be added in LD DEX', async function() {
      assert.equal(await pair.totalSupply(), toWei(String(500)))
    })
  })


  //END
})
