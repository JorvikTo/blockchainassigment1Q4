import { ethers } from "hardhat";

/**
 * Script to deploy and run the Solidity test suite for ThreePartyEscrow
 * This deploys ThreePartyEscrowTestRunner contract and executes all tests
 */
async function main() {
    console.log("=".repeat(60));
    console.log("ThreePartyEscrow Solidity Test Suite");
    console.log("=".repeat(60));
    console.log();

    // Get deployer account
    const [deployer] = await ethers.getSigners();
    console.log("Running tests with account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
    console.log();

    // Deploy the test runner contract with sufficient ETH
    console.log("Deploying ThreePartyEscrowTestRunner contract...");
    const TestRunner = await ethers.getContractFactory("ThreePartyEscrowTestRunner");
    const testRunner = await TestRunner.deploy({ value: ethers.parseEther("10") });
    await testRunner.waitForDeployment();
    
    const testRunnerAddress = await testRunner.getAddress();
    console.log("✓ ThreePartyEscrowTestRunner deployed at:", testRunnerAddress);
    console.log("  Contract balance:", ethers.formatEther(await ethers.provider.getBalance(testRunnerAddress)), "ETH");
    console.log();

    // Run all tests
    console.log("Running all tests...");
    console.log("-".repeat(60));
    
    const tx = await testRunner.runAllTests({ value: ethers.parseEther("5") });
    const receipt = await tx.wait();
    
    console.log("✓ Tests executed in transaction:", receipt.hash);
    console.log();

    // Parse test results from events
    const testResults = [];
    let passedCount = 0;
    let failedCount = 0;

    // Get the event signature for TestResult
    const iface = testRunner.interface;
    
    for (const log of receipt.logs) {
        try {
            const parsedLog = iface.parseLog({
                topics: [...log.topics],
                data: log.data
            });
            
            if (parsedLog && parsedLog.name === "TestResult") {
                const testName = parsedLog.args.testName;
                const passed = parsedLog.args.passed;
                const message = parsedLog.args.message;
                
                testResults.push({ testName, passed, message });
                
                if (passed) {
                    passedCount++;
                    console.log(`✓ PASS: ${testName}`);
                    if (message && message !== "") {
                        console.log(`       ${message}`);
                    }
                } else {
                    failedCount++;
                    console.log(`✗ FAIL: ${testName}`);
                    console.log(`       ${message}`);
                }
            } else if (parsedLog && parsedLog.name === "TestSuiteComplete") {
                console.log();
                console.log("=".repeat(60));
                console.log("Test Suite Complete");
                console.log("=".repeat(60));
                console.log("Total Tests:", parsedLog.args.total.toString());
                console.log("Passed:", parsedLog.args.passed.toString());
                console.log("Failed:", parsedLog.args.failed.toString());
            }
        } catch (e) {
            // Skip logs that don't match our events
        }
    }
    
    console.log();

    // Get final summary
    const summary = await testRunner.getTestSummary();
    console.log("Final Test Summary:");
    console.log("-".repeat(60));
    console.log("Total Tests:  ", summary.total.toString());
    console.log("Tests Passed: ", summary.passed.toString());
    console.log("Tests Failed: ", summary.failed.toString());
    console.log("Pass Rate:    ", summary.passRate.toString() + "%");
    console.log();

    // Color-coded result
    if (summary.failed === 0n) {
        console.log("🎉 All tests passed! 🎉");
    } else if (summary.passRate >= 80n) {
        console.log("⚠️  Most tests passed, but some failures need attention");
    } else {
        console.log("❌ Multiple test failures - review required");
    }
    
    console.log();
    console.log("=".repeat(60));

    // Return exit code based on test results
    if (summary.failed > 0n) {
        console.log("⚠️  Exiting with code 1 due to test failures");
        process.exitCode = 1;
    } else {
        console.log("✓ All tests passed successfully");
        process.exitCode = 0;
    }
}

// Execute the main function
main().catch((error) => {
    console.error("Error running test suite:");
    console.error(error);
    process.exitCode = 1;
});
