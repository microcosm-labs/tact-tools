# Sandbox Mermaid

Sandbox Mermaid generates Mermaid Diagrams from TON Sandbox Transactions.

## Usage Example

In `*.spec.ts`, declare:

```
export let addrDict: Record<string, string> = {};
export let addrContract: Record<string, SandboxContract<any>> = {};
```

Then each time you initiate a new user or contract, add it:

```
addrDict[`${deployer.address}`] = 'Deployer_EOA';
addrDict[`${user0.address}`] = 'User0_EOA';
addrContract[`${deployer.address}`] = deployer;
addrContract[`${user0.address}`] = user0;

addrDict[`${jetton1.address}`] = 'Jetton1';
addrContract[`${jetton1.address}`] = jetton1;
```

To use it to display a transaction:

```
const result = await MyContract.send(...);
console.log(generateMermaidDiagram(result, addrDict, addrContract));
```

## Output Examples

```
    sequenceDiagram
      autonumber
      participant User1_EOA as User1_EOA<br/>CGet..tGGy
      participant User1_Jetton1Wallet as User1_Jetton1Wallet<br/>C1AR..faER
      participant ContractA_Jetton1Wallet as ContractA_Jetton1Wallet<br/>AcDf..Zew4
      participant ContractA as ContractA<br/>BRHZ..3rJd
      User1_EOA ->> User1_Jetton1Wallet:[TokenTransfer(0f8a7ea5)]<br/>10.6 TON<br/>{"query_id":"1234","amount":"100000000000","destination":"EQBRHZma6gHwoCvH3PC72NcHoOwWOSbBZaL0w0m583rJdifX","response_destination":"EQCGetaGEWP4PhqPSV71o4NaU3rcw5yAG7kh7s1VdtGGynTA","custom_payload":"null","forward_ton_amount":"500000000","forward_payload":"remainder 117 bits 1 refs"}
      User1_Jetton1Wallet ->> ContractA_Jetton1Wallet:[TokenTransferInternal(178d4519)]<br/>10.5822656 TON<br/>{"query_id":"1234","amount":"100000000000","from":"EQCGetaGEWP4PhqPSV71o4NaU3rcw5yAG7kh7s1VdtGGynTA","response_destination":"EQCGetaGEWP4PhqPSV71o4NaU3rcw5yAG7kh7s1VdtGGynTA","forward_ton_amount":"500000000","forward_payload":"remainder 117 bits 1 refs"}
      ContractA_Jetton1Wallet ->> ContractA:[JettonTransferNotification(7362d09c)]<br/>0.5 TON<br/>{"query_id":"1234","amount":"100000000000","sender":"EQCGetaGEWP4PhqPSV71o4NaU3rcw5yAG7kh7s1VdtGGynTA","forward_payload":"remainder 117 bits 1 refs"}
      ContractA_Jetton1Wallet ->> User1_EOA:[d53276db]<br/>10.062190727 TON<br/>Calldata

```

```
    sequenceDiagram
      autonumber
      participant User1_EOA as User1_EOA<br/>EQCGetaGEWP4PhqPSV71o4NaU3rcw5yAG7kh7s1VdtGGynTA
      participant ContractA as ContractA<br/>EQBRHZma6gHwoCvH3PC72NcHoOwWOSbBZaL0w0m583rJdifX
      User1_EOA ->> ContractA:[WithdrawDustFromExec(defc4f69)]<br/>0.1 TON<br/>{"query_id":"10"}
      Note over ContractA: ERR: Unauthenticated
      ContractA ->> User1_EOA:[ffffffff:x:]<br/>0.096208 TON<br/>Calldata
```
