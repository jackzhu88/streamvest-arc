# StreamVest on Arc

USDC vesting and scheduled payouts on Arc mainnet, where USDC is the native gas token.

A payer locks USDC for a beneficiary. It vests linearly from `start + cliff` to `start + duration`. The beneficiary can claim whatever has vested at any time. If the schedule is revocable, the payer can revoke it and get back the unvested part, while the part already vested stays claimable. Uses: payroll streams, contributor grants, token-free team vesting, milestone-style allowances.

- Live app: https://jackzhu88.github.io/streamvest-arc/
- Contract (Arc mainnet, chain 5042): [`0x02e584e60a67435E9495508cF1c033F921b581F8`](https://explorer.arc.io/address/0x02e584e60a67435E9495508cF1c033F921b581F8)

## Mainnet transactions
| Step | Tx |
|---|---|
| Deploy | [0x5307dd46…](https://explorer.arc.io/tx/0x5307dd46c40b0d3a5a276c06bd3685e9a695aa6476173819f7a97c1ebe9f7598) |
| Create schedule (lock 0.01 USDC, 20 s linear) | [0x8824b1eb…](https://explorer.arc.io/tx/0x8824b1eb024fab97c83d966e8d30cb79a39160f3fd7d81acdbd4c2671ac0e064) |
| Claim (USDC paid out to beneficiary) | [0xc7303428…](https://explorer.arc.io/tx/0xc73034282b722e6471879b8e0de92e8547f9a0334f2d532ba18b98f0a389ac05) |

## Contract API
- `create(beneficiary, start, cliff, duration, revocable, memo)` payable: locks `msg.value` USDC (`start = 0` means now)
- `claim(id)`: beneficiary withdraws vested USDC
- `revoke(id)`: payer stops vesting and gets the unvested remainder back
- `claimable(id)`, `vestedAt(id, t)`, `getSchedule(id)`, `count()`

## Develop
`pip install web3 py-solc-x "web3[tester]"` then `python build_test.py`, which compiles the contract and runs the local tests.

Built by jackzhu88.
