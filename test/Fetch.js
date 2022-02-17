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
const Fetch = artifacts.require('./Fetch.sol')
const Treasury = artifacts.require('./Treasury.sol')
const WalletDistributor = artifacts.require('./WalletDistributor.sol')
const Reserve = artifacts.require('./Reserve.sol')


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
    vTokenSale,
    fetch,
    treasury,
    walletDistributor,
    reserve


contract('Fetch', function([userOne, userTwo, userThree]) {

  async function deployContracts(){
    // deploy contracts
    weth = await WETH.new()

    treasury = await Treasury.new()

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
    vTokenToToken = await VTokenToToken.new(tokenMinter.address, vToken.address)

    // deploy token to vToken converter
    tokenToVToken = await TokenToVToken.new(token.address, vTokenMinter.address)

    // deploy LD manager
    ldManager = await LDManager.new(
      uniRouter.address,
      token.address,
      tokenMinter.address,
      treasury.address
    )

    // deploy wallet destributor
    walletDistributor = await WalletDistributor.new(vToken.address)

    // deploy V sale
    vTokenSale = await VTokenSale.new(
      token.address,
      vTokenMinter.address,
      walletDistributor.address,
      ldManager.address,
      uniRouter.address
    )

    // update permitions for vTokenMinter
    await vTokenMinter.updatePermittion(vTokenSale.address, true)
    await vTokenMinter.updatePermittion(tokenToVToken.address, true)

    // update permitions for tokenMinter
    await tokenMinter.updatePermittion(ldManager.address, true)
    await tokenMinter.updatePermittion(vTokenToToken.address, true)

    // deploy reserve
    reserve = await Reserve.new(token.address, uniRouter.address, weth.address)

    // deploy fetch
    fetch = await Fetch.new(
      weth.address,
      uniRouter.address,
      token.address,
      vTokenSale.address,
      reserve.address,
      tokenToVToken.address,
      vToken.address
    )

    // set fetch
    await vTokenToToken.setFetch(fetch.address)
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('Fetch', function() {
    it('Convert input to vToken', async function() {
      console.log(
        "Deposit length before ",
        Number(await fetch.totalUserDeposits(userTwo))
      )

      // user two not hold any vtoken before deposit
      assert.equal(Number(await vToken.balanceOf(userTwo)), 0)
      // deposit
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      // user two get vtoken
      assert.notEqual(Number(await vToken.balanceOf(userTwo)), 0)
      // fetch send all pool
      assert.equal(Number(await pair.balanceOf(fetch.address)), 0)
      // fetch send all vTokens
      assert.equal(Number(await vToken.balanceOf(fetch.address)), 0)
      // fetch send all ETH remains
      assert.equal(Number(await web3.eth.getBalance(fetch.address)), 0)
      // fetch send all WETH remains
      assert.equal(Number(await weth.balanceOf(fetch.address)), 0)
      // fetch send all tokens
      assert.equal(Number(await token.balanceOf(fetch.address)), 0)
      // LD manager send pool to treasury
      assert.notEqual(Number(await pair.balanceOf(treasury.address)), 0)

      console.log(
        "Deposit length after ",
        Number(await fetch.totalUserDeposits(userTwo))
      )
    })


    it('convert vToken to token after fetch', async function() {
      console.log(
        "Token before ",
        Number(fromWei(await token.balanceOf(userTwo)))
      )

      // deposit in fetch
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      // increase time
      await timeMachine.advanceTimeAndBlock(duration.days(365))
      // reedem
      await vToken.approveBurn(vTokenToToken.address, toWei(String(1)), { from:userTwo })
      await vTokenToToken.convert(userTwo, 0, toWei(String(1)), { from:userTwo })

      console.log(
        "Token after ",
        Number(fromWei(await token.balanceOf(userTwo)))
      )
    })


    it('to reedem should be calculated correct', async function() {
      // deposit in fetch
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      const depositData = await fetch.depositsPerUser(userTwo, 0)
      const userBalance = depositData[1] - depositData[0]

      console.log(
        "To reedem",
        Number(fromWei(String(userBalance))),
        "Real balance",
        Number(fromWei(await vToken.balanceOf(userTwo)))
      )

      assert.equal(
        Number(fromWei(String(userBalance))),
        Number(fromWei(await vToken.balanceOf(userTwo)))
      )
    })


    it('can not reedem same deposit twice', async function() {
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      await vToken.approveBurn(vTokenToToken.address, toWei(String(2)), { from:userTwo })
      await vTokenToToken.convert(userTwo, 0, toWei(String(1)), { from:userTwo })
      await vTokenToToken.convert(userTwo, 0, toWei(String(1)), { from:userTwo })
      .should.be.rejectedWith(EVMRevert)
    })

    it('can not reedem not existing index', async function() {
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      await vToken.approveBurn(vTokenToToken.address, toWei(String(1)), { from:userTwo })
      await vTokenToToken.convert(userTwo, 1, toWei(String(1)), { from:userTwo })
      .should.be.rejectedWith(EVMRevert)
    })

    it('after ahead of time can not reedem more than 1 to 1', async function() {
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })

      console.log(
        "Vtoken before reedem ",
        Number(fromWei(await vToken.balanceOf(userTwo)))
      )

      await vToken.approveBurn(vTokenToToken.address, toWei(String(1)), { from:userTwo })
      await timeMachine.advanceTimeAndBlock(duration.days(900))
      await vTokenToToken.convert(userTwo, 0, toWei(String(1)), { from:userTwo })

      const reedemed = Number(fromWei(await token.balanceOf(userTwo)))

      console.log(
        "Vtoken after reedem ",
        Number(fromWei(await vToken.balanceOf(userTwo)))
      )

      console.log(
        "Reedemed amount after 900 days ",
         reedemed
      )

      assert.isTrue(
        reedemed <= 1
      )
    })


    it('Calculate reedem', async function() {
      // deposit in fetch
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      const depositData = await fetch.depositsPerUser(userTwo, 0)
      const userBalance = depositData[1] - depositData[0]

      let totalDays = 0
      for(let i = 0; i<12; i++){
        // increase time
        await timeMachine.advanceTimeAndBlock(duration.days(30))
        totalDays += 30
        console.log(
          `Token receive on day ${totalDays} - `,
          Number(
            fromWei(await vTokenToToken.calculateReturn(depositData[2], String(userBalance)))
          ).toFixed(2)
        )
      }
    })
  })
  //END
})
