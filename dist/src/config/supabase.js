"use strict";
/**
 * Supabase配置模块
 * 负责管理Supabase客户端连接和环境变量验证
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SupabaseConfigManager = exports.ConfigErrorType = exports.ENV_KEYS = void 0;
const supabase_js_1 = require("@supabase/supabase-js");
const dotenv_1 = require("dotenv");
// 加载环境变量
(0, dotenv_1.config)();
/**
 * 环境变量键名常量
 */
exports.ENV_KEYS = {
    SUPABASE_URL: 'SUPABASE_URL',
    SUPABASE_ANON_KEY: 'SUPABASE_ANON_KEY',
    SUPABASE_SERVICE_ROLE_KEY: 'SUPABASE_SERVICE_ROLE_KEY',
    SUPABASE_PROJECT_ID: 'SUPABASE_PROJECT_ID'
};
/**
 * 错误类型枚举
 */
var ConfigErrorType;
(function (ConfigErrorType) {
    ConfigErrorType["MISSING_URL"] = "SUPABASE_URL environment variable is required";
    ConfigErrorType["MISSING_ANON_KEY"] = "SUPABASE_ANON_KEY environment variable is required";
    ConfigErrorType["MISSING_PROJECT_ID"] = "SUPABASE_PROJECT_ID environment variable is required";
    ConfigErrorType["INVALID_URL_FORMAT"] = "Invalid SUPABASE_URL format. Expected: https://project-id.supabase.co";
    ConfigErrorType["MISSING_SERVICE_ROLE"] = "Service Role Key is required for admin operations";
})(ConfigErrorType || (exports.ConfigErrorType = ConfigErrorType = {}));
/**
 * 网络错误检测关键词
 */
const NETWORK_ERROR_INDICATORS = [
    'network',
    'connection',
    'fetch',
    'Failed to fetch',
    'NetworkError',
    'timeout'
];
class SupabaseConfigManager {
    static instance;
    client = null;
    config = null;
    constructor() { }
    static getInstance() {
        if (!SupabaseConfigManager.instance) {
            SupabaseConfigManager.instance = new SupabaseConfigManager();
        }
        return SupabaseConfigManager.instance;
    }
    /**
     * 验证环境变量配置
     * @throws Error 当配置不完整时抛出错误
     */
    validateConfig() {
        const url = process.env[exports.ENV_KEYS.SUPABASE_URL];
        const anonKey = process.env[exports.ENV_KEYS.SUPABASE_ANON_KEY];
        const serviceRoleKey = process.env[exports.ENV_KEYS.SUPABASE_SERVICE_ROLE_KEY];
        const projectId = process.env[exports.ENV_KEYS.SUPABASE_PROJECT_ID];
        // 验证必需的环境变量
        this.validateRequiredEnvVars({ url, anonKey, projectId });
        // 验证URL格式
        this.validateUrlFormat(url);
        this.config = {
            url: url,
            anonKey: anonKey,
            serviceRoleKey,
            projectId: projectId
        };
        return this.config;
    }
    /**
     * 验证必需的环境变量
     * @private
     */
    validateRequiredEnvVars(vars) {
        if (!vars.url) {
            throw new Error(ConfigErrorType.MISSING_URL);
        }
        if (!vars.anonKey) {
            throw new Error(ConfigErrorType.MISSING_ANON_KEY);
        }
        if (!vars.projectId) {
            throw new Error(ConfigErrorType.MISSING_PROJECT_ID);
        }
    }
    /**
     * 验证Supabase URL格式
     * @private
     */
    validateUrlFormat(url) {
        const supabaseUrlPattern = /^https:\/\/[a-zA-Z0-9-]+\.supabase\.co$/;
        if (!url.match(supabaseUrlPattern)) {
            throw new Error(ConfigErrorType.INVALID_URL_FORMAT);
        }
    }
    /**
     * 创建Supabase客户端
     * @param useServiceRole 是否使用Service Role Key（默认false）
     */
    createClient(useServiceRole = false) {
        if (!this.config) {
            this.validateConfig();
        }
        const key = this.selectApiKey(useServiceRole);
        this.client = (0, supabase_js_1.createClient)(this.config.url, key);
        return this.client;
    }
    /**
     * 选择合适的API密钥
     * @private
     */
    selectApiKey(useServiceRole) {
        const key = useServiceRole ? this.config.serviceRoleKey : this.config.anonKey;
        if (useServiceRole && !key) {
            throw new Error(ConfigErrorType.MISSING_SERVICE_ROLE);
        }
        return key;
    }
    /**
     * 测试数据库连接
     */
    async testConnection() {
        try {
            this.ensureClientExists();
            const { data, error } = await this.performTestQuery();
            return this.evaluateConnectionResult(error);
        }
        catch (error) {
            console.error('Supabase连接测试失败:', error);
            return this.isNetworkError(error) ? false : false;
        }
    }
    /**
     * 确保客户端存在
     * @private
     */
    ensureClientExists() {
        if (!this.client) {
            this.createClient();
        }
    }
    /**
     * 执行测试查询
     * @private
     */
    async performTestQuery() {
        return this.client
            .from('_dummy_connection_test')
            .select('*')
            .limit(1);
    }
    /**
     * 评估连接结果
     * @private
     */
    evaluateConnectionResult(error) {
        if (!error)
            return true;
        // 检查是否是网络连接错误或其他关键错误
        const isNetworkError = NETWORK_ERROR_INDICATORS.some(indicator => error.message?.includes(indicator));
        return !isNetworkError && error.code !== 'PGRST301';
    }
    /**
     * 验证Auth服务可用性
     */
    async testAuthService() {
        try {
            this.ensureClientExists();
            const { data, error } = await this.client.auth.getUser();
            // 检查是否是网络连接错误
            if (error && this.isNetworkError(error)) {
                return false;
            }
            // 对于匿名连接，用户应该是null，但不应该有严重错误
            return true;
        }
        catch (error) {
            console.error('Supabase Auth服务测试失败:', error);
            return this.isNetworkError(error) ? false : false;
        }
    }
    /**
     * 检查是否为网络错误
     * @private
     */
    isNetworkError(error) {
        if (!error?.message)
            return false;
        return NETWORK_ERROR_INDICATORS.some(indicator => error.message.includes(indicator));
    }
    /**
     * 获取当前配置信息
     */
    getConfig() {
        return this.config;
    }
    /**
     * 重置配置（主要用于测试）
     */
    reset() {
        this.client = null;
        this.config = null;
    }
}
exports.SupabaseConfigManager = SupabaseConfigManager;
//# sourceMappingURL=supabase.js.map