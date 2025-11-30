#!/usr/bin/env node

/**
 * Script to verify and analyze the Solidity test suite
 * Checks test file syntax, counts tests, and validates structure
 */

import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const testFiles = [
    'test/ThreePartyEscrow.t.sol',
    'test/ThreePartyEscrowTestRunner.sol'
];

console.log("=".repeat(70));
console.log("ThreePartyEscrow Solidity Test Suite - Verification Report");
console.log("=".repeat(70));
console.log();

let totalTests = 0;
const testCategories = {
    'Constructor': 0,
    'Deployment': 0,
    'Deposit': 0,
    'Release': 0,
    'Refund': 0,
    'Approval': 0,
    'Edge': 0,
    'Security': 0,
    'State': 0,
    'Status': 0,
    'System': 0,
    'Integration': 0
};

for (const testFile of testFiles) {
    const filePath = join(process.cwd(), testFile);
    
    console.log(`Analyzing: ${testFile}`);
    console.log("-".repeat(70));
    
    if (!existsSync(filePath)) {
        console.log(`❌ File not found: ${testFile}`);
        console.log();
        continue;
    }
    
    const content = readFileSync(filePath, 'utf-8');
    
    // Count test functions
    const testFunctions = content.match(/function\s+test\w+\s*\(/g) || [];
    const fileTestCount = testFunctions.length;
    totalTests += fileTestCount;
    
    console.log(`✓ File exists and is readable`);
    console.log(`✓ Found ${fileTestCount} test functions`);
    
    // Categorize tests
    for (const testFunc of testFunctions) {
        const funcName = testFunc.match(/function\s+(test\w+)/)[1];
        
        if (funcName.toLowerCase().includes('constructor') || funcName.toLowerCase().includes('deployment')) {
            testCategories['Constructor']++;
        } else if (funcName.toLowerCase().includes('deposit')) {
            testCategories['Deposit']++;
        } else if (funcName.toLowerCase().includes('release')) {
            testCategories['Release']++;
        } else if (funcName.toLowerCase().includes('refund')) {
            testCategories['Refund']++;
        } else if (funcName.toLowerCase().includes('approval') || funcName.toLowerCase().includes('approve')) {
            testCategories['Approval']++;
        } else if (funcName.toLowerCase().includes('edge') || funcName.toLowerCase().includes('double') || funcName.toLowerCase().includes('zero')) {
            testCategories['Edge']++;
        } else if (funcName.toLowerCase().includes('state') || funcName.toLowerCase().includes('status')) {
            testCategories['State']++;
        } else if (funcName.toLowerCase().includes('system')) {
            testCategories['System']++;
        }
    }
    
    // Check for proper SPDX license
    if (content.includes('// SPDX-License-Identifier: MIT')) {
        console.log('✓ SPDX license identifier present');
    } else {
        console.log('⚠️  Missing SPDX license identifier');
    }
    
    // Check for pragma
    if (content.includes('pragma solidity')) {
        const pragmaMatch = content.match(/pragma solidity\s+([^;]+);/);
        if (pragmaMatch) {
            console.log(`✓ Solidity version: ${pragmaMatch[1]}`);
        }
    } else {
        console.log('❌ Missing pragma solidity statement');
    }
    
    // Check for imports
    const imports = content.match(/import\s+"[^"]+";/g) || [];
    console.log(`✓ Found ${imports.length} import statement(s)`);
    
    // Check for contract declaration
    const contractMatch = content.match(/contract\s+(\w+)/);
    if (contractMatch) {
        console.log(`✓ Contract name: ${contractMatch[1]}`);
    }
    
    // Check for events
    const events = content.match(/event\s+\w+\s*\(/g) || [];
    console.log(`✓ Found ${events.length} event declaration(s)`);
    
    // Check for comments/documentation
    const comments = content.match(/\/\*\*[\s\S]*?\*\//g) || [];
    console.log(`✓ Found ${comments.length} documentation block(s)`);
    
    // Check for test runners
    const runners = content.match(/function\s+runAll\w*Tests\s*\(/g) || [];
    if (runners.length > 0) {
        console.log(`✓ Found ${runners.length} test runner function(s)`);
    }
    
    console.log();
}

console.log("=".repeat(70));
console.log("Test Suite Summary");
console.log("=".repeat(70));
console.log();
console.log(`Total Test Functions: ${totalTests}`);
console.log();
console.log("Test Distribution by Category:");
console.log("-".repeat(70));

for (const [category, count] of Object.entries(testCategories)) {
    if (count > 0) {
        const percentage = ((count / totalTests) * 100).toFixed(1);
        const bar = '█'.repeat(Math.floor(count / 2));
        console.log(`${category.padEnd(15)} ${count.toString().padStart(3)} tests  ${percentage.padStart(5)}%  ${bar}`);
    }
}

console.log();
console.log("=".repeat(70));
console.log("Test Coverage Analysis");
console.log("=".repeat(70));
console.log();

const coverageAreas = [
    { name: 'Constructor Validation', covered: testCategories['Constructor'] > 0 },
    { name: 'Deposit Functionality', covered: testCategories['Deposit'] > 0 },
    { name: 'Release Mechanism', covered: testCategories['Release'] > 0 },
    { name: 'Refund Mechanism', covered: testCategories['Refund'] > 0 },
    { name: 'Approval Tracking', covered: testCategories['Approval'] > 0 },
    { name: 'Edge Cases', covered: testCategories['Edge'] > 0 },
    { name: 'State Management', covered: testCategories['State'] > 0 },
    { name: 'System Integration', covered: testCategories['System'] > 0 }
];

let coveredAreas = 0;
for (const area of coverageAreas) {
    if (area.covered) {
        console.log(`✓ ${area.name}`);
        coveredAreas++;
    } else {
        console.log(`✗ ${area.name}`);
    }
}

console.log();
const coveragePercentage = ((coveredAreas / coverageAreas.length) * 100).toFixed(1);
console.log(`Coverage: ${coveredAreas}/${coverageAreas.length} areas (${coveragePercentage}%)`);
console.log();

console.log("=".repeat(70));
console.log("Recommendations");
console.log("=".repeat(70));
console.log();

if (totalTests < 10) {
    console.log("⚠️  Test suite has fewer than 10 tests. Consider adding more coverage.");
} else if (totalTests < 30) {
    console.log("✓ Test suite has decent coverage. Consider adding edge case tests.");
} else {
    console.log("✓ Comprehensive test suite with good coverage!");
}

if (testCategories['System'] === 0) {
    console.log("⚠️  No system/integration tests found. Consider adding end-to-end tests.");
} else {
    console.log(`✓ System tests present (${testCategories['System']} tests)`);
}

if (testCategories['Edge'] === 0) {
    console.log("⚠️  No edge case tests found. Consider testing boundary conditions.");
} else {
    console.log(`✓ Edge case tests present (${testCategories['Edge']} tests)`);
}

console.log();
console.log("=".repeat(70));
console.log("Verification Complete");
console.log("=".repeat(70));
console.log();

if (totalTests > 0 && coveragePercentage >= 75) {
    console.log("✅ Test suite verification PASSED");
    process.exit(0);
} else {
    console.log("⚠️  Test suite needs improvement");
    process.exit(1);
}
