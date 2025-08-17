"use strict";
/**
 * Supabase配置TDD测试
 * TDD红灯阶段：编写应该失败的测试用例
 */
Object.defineProperty(exports, "__esModule", { value: true });
const vitest_1 = require("vitest");
const supabase_1 = require("../../src/config/supabase");
// Mock Supabase客户端
const mockSupabaseClient = {
    from: vitest_1.vi.fn(),
    auth: {
        getUser: vitest_1.vi.fn()
    }
};
vitest_1.vi.mock('@supabase/supabase-js', () => ({
    createClient: vitest_1.vi.fn(() => mockSupabaseClient)
}));
vitest_1.vi.mock('dotenv', () => ({
    config: vitest_1.vi.fn()
}));
(0, vitest_1.describe)('SupabaseConfigManager - TDD红灯测试', () => {
    let configManager;
    (0, vitest_1.beforeEach)(() => {
        // 清除所有环境变量
        vitest_1.vi.unstubAllEnvs();
        // 重置mock
        vitest_1.vi.clearAllMocks();
        configManager = supabase_1.SupabaseConfigManager.getInstance();
        configManager.reset();
    });
    (0, vitest_1.describe)('环境变量验证测试 - 应该失败', () => {
        (0, vitest_1.it)('应该在缺少SUPABASE_URL时抛出错误', () => {
            // 设置无效环境变量 - 不设置SUPABASE_URL
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project');
            (0, vitest_1.expect)(() => {
                configManager.validateConfig();
            }).toThrow('SUPABASE_URL environment variable is required');
        });
        (0, vitest_1.it)('应该在缺少SUPABASE_ANON_KEY时抛出错误', () => {
            vitest_1.vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project');
            // 不设置SUPABASE_ANON_KEY
            (0, vitest_1.expect)(() => {
                configManager.validateConfig();
            }).toThrow('SUPABASE_ANON_KEY environment variable is required');
        });
        (0, vitest_1.it)('应该在缺少SUPABASE_PROJECT_ID时抛出错误', () => {
            vitest_1.vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co');
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
            // 不设置SUPABASE_PROJECT_ID
            (0, vitest_1.expect)(() => {
                configManager.validateConfig();
            }).toThrow('SUPABASE_PROJECT_ID environment variable is required');
        });
        (0, vitest_1.it)('应该在SUPABASE_URL格式无效时抛出错误', () => {
            vitest_1.vi.stubEnv('SUPABASE_URL', 'invalid-url');
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project');
            (0, vitest_1.expect)(() => {
                configManager.validateConfig();
            }).toThrow('Invalid SUPABASE_URL format');
        });
    });
    (0, vitest_1.describe)('Supabase客户端创建测试 - 应该失败', () => {
        (0, vitest_1.it)('应该在配置无效时无法创建客户端', () => {
            // 未设置任何环境变量的情况下尝试创建客户端
            (0, vitest_1.expect)(() => {
                configManager.createClient();
            }).toThrow();
        });
        (0, vitest_1.it)('应该在请求Service Role但未提供密钥时抛出错误', () => {
            // 设置基本配置但不设置Service Role Key
            vitest_1.vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co');
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project');
            // 不设置SUPABASE_SERVICE_ROLE_KEY
            // 先验证配置以设置基本配置
            configManager.validateConfig();
            (0, vitest_1.expect)(() => {
                configManager.createClient(true); // 请求Service Role
            }).toThrow('Service Role Key is required for admin operations');
        });
    });
    (0, vitest_1.describe)('连接测试 - 应该失败（因为尚未配置真实项目）', () => {
        (0, vitest_1.it)('应该在没有有效Supabase项目时连接失败', async () => {
            // 使用虚假的配置
            vitest_1.vi.stubEnv('SUPABASE_URL', 'https://fake-project.supabase.co');
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'fake-anon-key');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'fake-project');
            // 模拟网络错误
            mockSupabaseClient.from.mockReturnValue({
                select: vitest_1.vi.fn().mockReturnValue({
                    limit: vitest_1.vi.fn().mockResolvedValue({
                        data: null,
                        error: { message: 'Failed to fetch', code: 'NETWORK_ERROR' }
                    })
                })
            });
            configManager.validateConfig();
            configManager.createClient();
            const isConnected = await configManager.testConnection();
            (0, vitest_1.expect)(isConnected).toBe(false);
        });
        (0, vitest_1.it)('应该在Auth服务配置错误时验证失败', async () => {
            // 使用虚假的配置
            vitest_1.vi.stubEnv('SUPABASE_URL', 'https://fake-project.supabase.co');
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'fake-anon-key');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'fake-project');
            // 模拟Auth服务网络错误
            mockSupabaseClient.auth.getUser.mockResolvedValue({
                data: null,
                error: { message: 'NetworkError: Failed to fetch' }
            });
            configManager.validateConfig();
            configManager.createClient();
            const isAuthWorking = await configManager.testAuthService();
            (0, vitest_1.expect)(isAuthWorking).toBe(false);
        });
    });
    (0, vitest_1.describe)('单例模式测试', () => {
        (0, vitest_1.it)('应该返回相同的实例', () => {
            const instance1 = supabase_1.SupabaseConfigManager.getInstance();
            const instance2 = supabase_1.SupabaseConfigManager.getInstance();
            (0, vitest_1.expect)(instance1).toBe(instance2);
        });
    });
    (0, vitest_1.describe)('配置获取测试', () => {
        (0, vitest_1.it)('应该在未验证配置时返回null', () => {
            const config = configManager.getConfig();
            (0, vitest_1.expect)(config).toBeNull();
        });
        (0, vitest_1.it)('应该在验证配置后返回正确的配置对象', () => {
            vitest_1.vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co');
            vitest_1.vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key');
            vitest_1.vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project');
            vitest_1.vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key');
            const validatedConfig = configManager.validateConfig();
            const retrievedConfig = configManager.getConfig();
            (0, vitest_1.expect)(retrievedConfig).toEqual(validatedConfig);
            (0, vitest_1.expect)(retrievedConfig).toEqual({
                url: 'https://test-project.supabase.co',
                anonKey: 'test-anon-key',
                serviceRoleKey: 'test-service-key',
                projectId: 'test-project'
            });
        });
    });
});
//# sourceMappingURL=supabase.test.js.map