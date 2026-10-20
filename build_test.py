import json, solcx
from web3 import Web3, EthereumTesterProvider
src=open('contracts/StreamVest.sol').read()
out=solcx.compile_standard({"language":"Solidity","sources":{"StreamVest.sol":{"content":src}},
 "settings":{"optimizer":{"enabled":True,"runs":200},"evmVersion":"paris","outputSelection":{"*":{"*":["abi","evm.bytecode.object"]}}}},solc_version='0.8.24')
c=out['contracts']['StreamVest.sol']['StreamVest']
json.dump({"abi":c['abi'],"bytecode":c['evm']['bytecode']['object']},open('StreamVest.json','w'))
w3=Web3(EthereumTesterProvider()); a=w3.eth.accounts; T=w3.provider.ethereum_tester
C=w3.eth.contract(abi=c['abi'],bytecode=c['evm']['bytecode']['object'])
addr=w3.eth.get_transaction_receipt(C.constructor().transact({'from':a[0]})).contractAddress
v=w3.eth.contract(address=addr,abi=c['abi'])
now=w3.eth.get_block('latest').timestamp
E=10**18
v.functions.create(a[1],now,100,1000,True,"salary").transact({'from':a[0],'value':E})
def fails(f,frm):
    try: f.transact({'from':frm}); return False
    except Exception: return True
assert fails(v.functions.claim(0),a[1])  # cliff
T.time_travel(now+500); T.mine_blocks(1)
assert fails(v.functions.claim(0),a[2])  # not beneficiary
b=w3.eth.get_balance(a[1]); g=v.functions.claim(0).transact({'from':a[1]}); r=w3.eth.get_transaction_receipt(g)
got=w3.eth.get_balance(a[1])-b+r.gasUsed*r.effectiveGasPrice; assert abs(got-E//2)<E//100, got
assert fails(v.functions.revoke(0),a[1])
p=w3.eth.get_balance(a[0]); g=v.functions.revoke(0).transact({'from':a[0]}); r=w3.eth.get_transaction_receipt(g)
ref=w3.eth.get_balance(a[0])-p+r.gasUsed*r.effectiveGasPrice; assert abs(ref-E//2)<E//100
T.time_travel(now+2000); T.mine_blocks(1)
rest=v.functions.claimable(0).call(); assert rest+got+ref==E
if rest: v.functions.claim(0).transact({'from':a[1]})
assert w3.eth.get_balance(addr)==0
v.functions.create(a[1],0,0,10,False,"x").transact({'from':a[0],'value':5})
assert fails(v.functions.revoke(1),a[0])
print("all tests passed")
