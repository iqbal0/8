import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import solc from 'solc';

const sourceCode = readFileSync('contracts/HotPotato.sol', 'utf8');

const input = {
  language: 'Solidity',
  sources: {
    'HotPotato.sol': {
      content: sourceCode,
    },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode.object'],
      },
    },
  },
};

console.log('Compiling contract...');
const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  output.errors.forEach((err) => console.error(err.formattedMessage));
  const hasErrors = output.errors.some((err) => err.severity === 'error');
  if (hasErrors) process.exit(1);
}

const contract = output.contracts['HotPotato.sol']['HotPotato'];

if (!existsSync('build')) {
  mkdirSync('build');
}

writeFileSync('build/HotPotato.abi.json', JSON.stringify(contract.abi, null, 2));
writeFileSync('build/HotPotato.bytecode.json', JSON.stringify(contract.evm.bytecode.object));

console.log('Compilation successful! ABI and bytecode saved to build/ directory.');
