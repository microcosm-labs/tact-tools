// SPDX-License-Identifier: MIT
// Copyright (C) Microcosm Labs 2024
// Author: @0kenx
// Version: 0.4.0
// GitHub: https://github.com/microcosm-labs

// Library to generate Mermaid Diagrams from TON Sandbox Transactions.

import { SendMessageResult, SandboxContract } from '@ton/sandbox';
import {
    Address,
    CommonMessageInfoInternal,
    ABIType,
    Slice,
    Cell,
    ABIField,
    ABITypeRef,
    TransactionDescription,
    TransactionDescriptionGeneric,
} from '@ton/core';

function shortenAddress(addr: string): string {
    if (addr.length < 10) return addr;
    if (!addr.startsWith('EQ') && !addr.startsWith('UQ')) return addr;
    return addr.slice(2, 6) + '..' + addr.slice(-7, -3);
}

function toCoinsString(value: any): string {
    if (typeof value === 'bigint') {
        const stringValue = value.toString(10);
        const decimalPlaces = 9;

        const decimalPart =
            stringValue.length > decimalPlaces
                ? stringValue.slice(-decimalPlaces)
                : stringValue.padStart(decimalPlaces, '0');
        const integerPart = stringValue.length > decimalPlaces ? stringValue.slice(0, -decimalPlaces) : '0';
        // Add a decimal point and return the formatted string
        const decimalString = integerPart + '.' + decimalPart;
        return decimalString.replace(/(\.?0+)$/, '');
    }

    // If the value is not a BigInt, return it as is
    return value.toString();
}

/// Function to generate Mermaid Diagram
/// Usage:
/// 1. In globai scope, define the following variables:
/// ```
/// let addrDict: Record<string, string> = {};
/// let addrContract: Record<string, SandboxContract<any>> = {};
/// ```
/// 2. When a new contract is deployed, add it to the `all_contracts` set and add the contract address to the `addrDict` dictionary:
/// ```
/// addrDict[`${jettonContract.address}`] = 'MyJetton';
/// addrContract[`${jettonContract.address}`] = jettonContract;
/// ```
/// Known bugs:
/// - When multiple contracts have methods with the same signature, the diagram will not be able to differentiate between them.
/// - The validity of values in `node_map` is not checked. (i.e. a space in the address will cause the diagram to fail)
export function generateMermaidDiagram(
    txResult: SendMessageResult,
    node_name_map: Record<string, string>,
    node_contract_map: Record<string, SandboxContract<any>>,
    use_short_address: boolean = true,
) {
    const nodeSet = new Set<string>();
    const edges: string[] = [];

    txResult.transactions.forEach((transaction) => {
        // console.log(transaction);
        const {
            address,
            inMessage,
            outMessages,
            outMessagesCount,
            totalFees,
            stateUpdate,
            description,
            raw,
            hash,
            events,
        } = transaction;

        // if (inMessage) {
        //   const { info: { src, dest } } = inMessage;

        //   edges.push(`${src} --> ${dest}`);
        // }
        if (description.type == 'generic') {
            let d: TransactionDescriptionGeneric = description as TransactionDescriptionGeneric;
            // console.log(d.computePhase, d.actionPhase?.totalMessageSize);
            if (d.computePhase.type == 'vm' && d.computePhase.exitCode != 0) {
                if (outMessagesCount > 0) {
                    const { info, body } = outMessages.get(0)!;
                    if ('value' in info && (info as CommonMessageInfoInternal).value !== undefined) {
                        const { src, dest, value } = info as CommonMessageInfoInternal;
                        const updatedSrc = node_name_map[`${src}`] || `${src}`;
                        const srcNode = use_short_address ? shortenAddress(updatedSrc) : updatedSrc;
                        if (node_contract_map[`${src}`] != null && node_contract_map[`${src}`].abi != null) {
                            const err = node_contract_map[`${src}`].abi.errors[`${d.computePhase.exitCode}`];
                            edges.push(`Note over ${srcNode}: ERR: ${err.message} `);
                        }
                    }
                }
            }
        }
        let d: TransactionDescription;
        if (outMessagesCount > 0) {
            for (const { info, body } of outMessages.values()) {
                if ('value' in info && (info as CommonMessageInfoInternal).value !== undefined) {
                    const { src, dest, value } = info as CommonMessageInfoInternal;
                    const updatedSrc = node_name_map[`${src}`] || `${src}`;
                    const updatedDest = node_name_map[`${dest}`] || `${dest}`;
                    const shortSrc = use_short_address ? shortenAddress(`${src}`) : `${src}`;
                    const shortDest = use_short_address ? shortenAddress(`${dest}`) : `${dest}`;
                    const srcNode = use_short_address ? shortenAddress(updatedSrc) : updatedSrc;
                    const destNode = use_short_address ? shortenAddress(updatedDest) : updatedDest;
                    const srcNodeAlias =
                        updatedSrc == `${src}` ? `${updatedSrc}` : `${updatedSrc} as ${updatedSrc}<br/>${shortSrc}`;
                    const destNodeAlias =
                        updatedDest == `${dest}`
                            ? `${updatedDest}`
                            : `${updatedDest} as ${updatedDest}<br/>${shortDest}`;
                    const bounced = (info as CommonMessageInfoInternal).bounced ? '❌' : '';
                    let opcode = body.toString().substring(2, 10).toLowerCase();
                    let opnum = Number(`0x${opcode}`);
                    let abi;
                    if (node_contract_map[`${dest}`] != null && node_contract_map[`${dest}`].abi != null) {
                        // console.log(node_contract_map[`${dest}`]);
                        abi = node_contract_map[`${dest}`].abi.types.find(
                            (x: { header: number }) => x.header === opnum,
                        );
                    }
                    if (abi != undefined) {
                        opcode = `${abi.name}(${opcode})`;
                    }

                    nodeSet.add(srcNodeAlias);
                    nodeSet.add(destNodeAlias);

                    edges.push(
                        `${srcNode} ->> ${destNode}:[${opcode}${bounced}]<br/>${toCoinsString(
                            value.coins,
                        )} TON<br/>${parseCell(body, abi)}`,
                    );
                }
            }
        }
    });

    const nodes = [...nodeSet!];
    const graph = `
sequenceDiagram
  autonumber
  ${nodes.map((node, index) => `participant ${node}`).join('\n  ')}
  ${edges.map((edge, index) => `${edge}`).join('\n  ')}
  `;

    return graph;
}

export type DecodedField = {
    name: string;
    value: string;
};

// Function to parse one cell
export function parseCell(cell: Cell, abi: any) {
    if (abi == undefined || abi.fields == undefined || abi.fields.length == 0) {
        return `Calldata`;
        // return `${cell.toBoc().toString('hex')}`;
    }
    let s: Slice = cell.beginParse();
    s.skip(32); // op code
    let res: DecodedField[] = [];

    // console.log(abi, s.remainingBits, s.remainingRefs);
    let abi_fields: ABIField[] = abi.fields;
    abi_fields.forEach((abi_field) => {
        let abi_field_type: ABITypeRef = abi_field.type;
        // console.log(abi_field.name, abi_field_type);
        if (abi_field_type.kind == 'simple') {
            let opt = true;
            if (abi_field_type.optional == true) {
                opt = s.loadBit();
            }
            if (opt) {
                if (abi_field_type.type == 'uint' && abi_field_type.format == 'coins') {
                    res.push({ name: abi_field.name, value: `${s.loadCoins()}` });
                } else if (abi_field_type.type == 'uint') {
                    res.push({ name: abi_field.name, value: `${s.loadUint(parseInt(`${abi_field_type.format}`))}` });
                } else if (abi_field_type.type == 'int') {
                    res.push({ name: abi_field.name, value: `${s.loadInt(parseInt(`${abi_field_type.format}`))}` });
                } else if (abi_field_type.type == 'address') {
                    res.push({ name: abi_field.name, value: `${s.loadAddress()}` });
                } else if (abi_field_type.type == 'bool') {
                    res.push({ name: abi_field.name, value: `${s.loadBit()}` });
                } else if (abi_field_type.type == 'cell') {
                    res.push({ name: abi_field.name, value: `${s.loadRef().toBoc().toString('hex')}` });
                } else if (abi_field_type.type == 'slice' && abi_field_type.format == 'remainder') {
                    res.push({
                        name: abi_field.name,
                        value: `remainder ${s.remainingBits} bits ${s.remainingRefs} refs`,
                    });
                } else {
                    res.push({ name: abi_field.name, value: `UNKNOWN TYPE ${abi_field_type.format}` });
                }
            } else {
                res.push({ name: abi_field.name, value: 'null' });
            }
        }
    });

    const resultObject: { [key: string]: string } = res.reduce(
        (acc, field) => {
            acc[field.name] = field.value;
            return acc;
        },
        {} as { [key: string]: string },
    );
    // return `Calldata`;
    return `${JSON.stringify(resultObject)}`;
}
