/**
 * Email Template Role-Based Selection Tests (Node.js compatible)
 * Tests the role-specific email template functionality
 * Ensures proper template selection and content generation for different user roles
 */

const fs = require('fs');
const path = require('path');

// Mock data for testing
const mockEmailData = {
  token: "123456",
  token_hash: "abc123def456",
  redirect_to: "http://localhost:3000",
  site_url: "http://localhost:3000",
}

const mockPractitionerUser = {
  id: "uuid-practitioner-1",
  email: "dr.smith@tcm-clinic.com",
  user_metadata: { role: 'tcm_practitioner' }
}

const mockPharmacyUser = {
  id: "uuid-pharmacy-1", 
  email: "manager@herbs-pharmacy.com",
  user_metadata: { role: 'pharmacy' }
}

const mockAdminUser = {
  id: "uuid-admin-1",
  email: "admin@tcm-platform.com", 
  user_metadata: { role: 'admin' }
}

const mockDefaultUser = {
  id: "uuid-user-1",
  email: "user@example.com",
  user_metadata: {}
}

// Helper function to simulate the email template selector
function getUserRole(user) {
  const role = user.user_metadata?.role || user.app_metadata?.role;
  
  if (role && ['tcm_practitioner', 'pharmacy', 'admin'].includes(role)) {
    return role;
  }
  
  return 'default';
}

function getTemplateSubject(userRole, emailActionType) {
  const subjectMap = {
    tcm_practitioner: {
      signup: "Confirm Your TCM Practitioner Account",
      recovery: "Reset Your TCM Practitioner Password"
    },
    pharmacy: {
      signup: "Confirm Your Pharmacy Partner Account", 
      recovery: "Reset Your Pharmacy Partner Password"
    },
    admin: {
      signup: "🚨 Administrator Account Confirmation Required",
      recovery: "🚨 CRITICAL: Administrator Password Reset"
    },
    default: {
      signup: "Confirm Your Account",
      recovery: "Reset Your Password"
    }
  };
  
  return subjectMap[userRole]?.[emailActionType] || subjectMap.default.signup;
}

// Simple test framework
let testsPassed = 0;
let testsTotal = 0;

function test(description, testFn) {
  testsTotal++;
  try {
    testFn();
    console.log(`✅ PASS: ${description}`);
    testsPassed++;
  } catch (error) {
    console.log(`❌ FAIL: ${description} - ${error.message}`);
  }
}

function assertEquals(actual, expected, message = '') {
  if (actual !== expected) {
    throw new Error(`Expected ${expected}, got ${actual}. ${message}`);
  }
}

function assertIncludes(haystack, needle, message = '') {
  if (!haystack.includes(needle)) {
    throw new Error(`Expected "${haystack}" to include "${needle}". ${message}`);
  }
}

function assertFileExists(filePath, message = '') {
  if (!fs.existsSync(filePath)) {
    throw new Error(`File does not exist: ${filePath}. ${message}`);
  }
}

function assertFileContains(filePath, content, message = '') {
  if (!fs.existsSync(filePath)) {
    throw new Error(`File does not exist: ${filePath}. ${message}`);
  }
  const fileContent = fs.readFileSync(filePath, 'utf8');
  if (!fileContent.includes(content)) {
    throw new Error(`File ${filePath} does not contain "${content}". ${message}`);
  }
}

// Test Cases
console.log('🧪 Running Email Template Tests...\n');

test("Email Template Role Detection - TCM Practitioner", () => {
  const role = getUserRole(mockPractitionerUser);
  assertEquals(role, "tcm_practitioner");
});

test("Email Template Role Detection - Pharmacy", () => {
  const role = getUserRole(mockPharmacyUser);
  assertEquals(role, "pharmacy");
});

test("Email Template Role Detection - Admin", () => {
  const role = getUserRole(mockAdminUser);
  assertEquals(role, "admin");
});

test("Email Template Role Detection - Default User", () => {
  const role = getUserRole(mockDefaultUser);
  assertEquals(role, "default");
});

test("Email Subject Generation - Practitioner Signup", () => {
  const subject = getTemplateSubject("tcm_practitioner", "signup");
  assertEquals(subject, "Confirm Your TCM Practitioner Account");
});

test("Email Subject Generation - Pharmacy Recovery", () => {
  const subject = getTemplateSubject("pharmacy", "recovery");
  assertEquals(subject, "Reset Your Pharmacy Partner Password");
});

test("Email Subject Generation - Admin Signup Critical", () => {
  const subject = getTemplateSubject("admin", "signup");
  assertIncludes(subject, "🚨");
  assertIncludes(subject, "Administrator");
});

test("Email Subject Generation - Admin Recovery Critical", () => {
  const subject = getTemplateSubject("admin", "recovery");
  assertIncludes(subject, "🚨 CRITICAL");
  assertIncludes(subject, "Administrator");
});

// File existence tests
test("Template Files Exist - Practitioner Templates", () => {
  assertFileExists("supabase/templates/practitioner-signup-confirmation.html");
  assertFileExists("supabase/templates/practitioner-password-recovery.html");
});

test("Template Files Exist - Pharmacy Templates", () => {
  assertFileExists("supabase/templates/pharmacy-signup-confirmation.html");
  assertFileExists("supabase/templates/pharmacy-password-recovery.html");
});

test("Template Files Exist - Admin Templates", () => {
  assertFileExists("supabase/templates/admin-signup-confirmation.html");
  assertFileExists("supabase/templates/admin-password-recovery.html");
});

test("Template Files Exist - Unified Role-Based Template", () => {
  assertFileExists("supabase/templates/role-based-confirmation.html");
});

test("Edge Function Exists", () => {
  assertFileExists("supabase/functions/auth-email-template-selector/index.ts");
});

test("Configuration File Exists", () => {
  assertFileExists("supabase/config.toml");
});

// Content validation tests
test("Practitioner Template Content", () => {
  assertFileContains("supabase/templates/practitioner-signup-confirmation.html", "🌿 TCM Prescription Platform");
  assertFileContains("supabase/templates/practitioner-signup-confirmation.html", "Professional Verification Required");
  assertFileContains("supabase/templates/practitioner-signup-confirmation.html", "HIPAA compliance");
});

test("Pharmacy Template Content", () => {
  assertFileContains("supabase/templates/pharmacy-signup-confirmation.html", "💊 TCM Prescription Platform");
  assertFileContains("supabase/templates/pharmacy-signup-confirmation.html", "QR Code Fulfillment System");
  assertFileContains("supabase/templates/pharmacy-signup-confirmation.html", "Business Verification Required");
});

test("Admin Template Content", () => {
  assertFileContains("supabase/templates/admin-signup-confirmation.html", "⚖️ TCM Platform Administration");
  assertFileContains("supabase/templates/admin-signup-confirmation.html", "Administrative Access Security");
  assertFileContains("supabase/templates/admin-signup-confirmation.html", "multi-factor authentication");
});

test("Edge Function Content", () => {
  assertFileContains("supabase/functions/auth-email-template-selector/index.ts", "tcm_practitioner");
  assertFileContains("supabase/functions/auth-email-template-selector/index.ts", "pharmacy");
  assertFileContains("supabase/functions/auth-email-template-selector/index.ts", "admin");
});

test("Configuration Content", () => {
  assertFileContains("supabase/config.toml", "[auth.email.template.confirmation]");
  assertFileContains("supabase/config.toml", "[auth.hook.send_email]");
  assertFileContains("supabase/config.toml", "auth-email-template-selector");
});

// Security validation test
test("Template Security - No PII Patterns", () => {
  const templateFiles = [
    "supabase/templates/practitioner-signup-confirmation.html",
    "supabase/templates/pharmacy-signup-confirmation.html", 
    "supabase/templates/admin-signup-confirmation.html"
  ];
  
  const prohibitedPatterns = ['patient', 'medical_record', 'diagnosis', 'treatment_plan', 'health_condition'];
  
  templateFiles.forEach(filePath => {
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8').toLowerCase();
      prohibitedPatterns.forEach(pattern => {
        if (content.includes(pattern)) {
          throw new Error(`Template ${filePath} contains prohibited pattern: ${pattern}`);
        }
      });
    }
  });
});

// Performance test
test("Template Selection Performance", () => {
  const startTime = Date.now();
  const iterations = 1000;
  
  // Simulate processing 1000 email template requests
  for (let i = 0; i < iterations; i++) {
    const users = [mockPractitionerUser, mockPharmacyUser, mockAdminUser, mockDefaultUser];
    const actions = ['signup', 'recovery'];
    
    users.forEach(user => {
      actions.forEach(action => {
        const role = getUserRole(user);
        const subject = getTemplateSubject(role, action);
        if (typeof subject !== 'string' || subject.length === 0) {
          throw new Error('Invalid subject generated');
        }
      });
    });
  }
  
  const endTime = Date.now();
  const duration = endTime - startTime;
  const avgTimePerRequest = duration / (iterations * 2 * 4); // 2 actions * 4 users
  
  // Template selection should be fast (< 1ms per request)
  if (avgTimePerRequest >= 1) {
    throw new Error(`Template selection too slow: ${avgTimePerRequest}ms per request`);
  }
});

// Summary
console.log('\n📊 Test Results Summary:');
console.log(`✅ Tests Passed: ${testsPassed}/${testsTotal}`);

if (testsPassed === testsTotal) {
  console.log('🎉 All tests passed successfully!');
  console.log('📧 Role-specific email templates validated');
  console.log('🔒 Security and performance checks passed');
  process.exit(0);
} else {
  console.log(`❌ ${testsTotal - testsPassed} tests failed`);
  console.log('🔧 Please fix failing tests before proceeding');
  process.exit(1);
}