import solc from 'solc';
import fs from 'fs';
import path from 'path';

// Read the source code
const contractPath = path.join(process.cwd(), 'contracts', 'ThreePartyEscrow.sol');
const source = fs.readFileSync(contractPath, 'utf8');

// Prepare the input for the compiler
const input = {
  language: 'Solidity',
  sources: {
    'ThreePartyEscrow.sol': {
      content: source,
    },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode'],
      },
    },
  },
};

// Compile the contract
const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Check for errors
if (output.errors) {
  let hasError = false;
  output.errors.forEach((error) => {
    console.error(error.formattedMessage);
    if (error.severity === 'error') {
      hasError = true;
    }
  });
  if (hasError) {
    process.exit(1);
  }
}

// Write the output to artifacts
const artifactsDir = path.join(process.cwd(), 'artifacts', 'contracts');
fs.mkdirSync(artifactsDir, { recursive: true });

const contract = output.contracts['ThreePartyEscrow.sol']['ThreePartyEscrow'];
const artifact = {
  abi: contract.abi,
  bytecode: contract.evm.bytecode.object,
};

fs.writeFileSync(
  path.join(artifactsDir, 'ThreePartyEscrow.json'),
  JSON.stringify(artifact, null, 2)
);

console.log('✓ Compiled successfully');
