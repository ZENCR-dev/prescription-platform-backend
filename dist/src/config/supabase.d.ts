/**
 * Supabase配置模块
 * 负责管理Supabase客户端连接和环境变量验证
 */
import { SupabaseClient } from '@supabase/supabase-js';
export interface SupabaseConfig {
    url: string;
    anonKey: string;
    serviceRoleKey?: string;
    projectId: string;
}
/**
 * 环境变量键名常量
 */
export declare const ENV_KEYS: {
    readonly SUPABASE_URL: "SUPABASE_URL";
    readonly SUPABASE_ANON_KEY: "SUPABASE_ANON_KEY";
    readonly SUPABASE_SERVICE_ROLE_KEY: "SUPABASE_SERVICE_ROLE_KEY";
    readonly SUPABASE_PROJECT_ID: "SUPABASE_PROJECT_ID";
};
/**
 * 错误类型枚举
 */
export declare enum ConfigErrorType {
    MISSING_URL = "SUPABASE_URL environment variable is required",
    MISSING_ANON_KEY = "SUPABASE_ANON_KEY environment variable is required",
    MISSING_PROJECT_ID = "SUPABASE_PROJECT_ID environment variable is required",
    INVALID_URL_FORMAT = "Invalid SUPABASE_URL format. Expected: https://project-id.supabase.co",
    MISSING_SERVICE_ROLE = "Service Role Key is required for admin operations"
}
export declare class SupabaseConfigManager {
    private static instance;
    private client;
    private config;
    private constructor();
    static getInstance(): SupabaseConfigManager;
    /**
     * 验证环境变量配置
     * @throws Error 当配置不完整时抛出错误
     */
    validateConfig(): SupabaseConfig;
    /**
     * 验证必需的环境变量
     * @private
     */
    private validateRequiredEnvVars;
    /**
     * 验证Supabase URL格式
     * @private
     */
    private validateUrlFormat;
    /**
     * 创建Supabase客户端
     * @param useServiceRole 是否使用Service Role Key（默认false）
     */
    createClient(useServiceRole?: boolean): SupabaseClient;
    /**
     * 选择合适的API密钥
     * @private
     */
    private selectApiKey;
    /**
     * 测试数据库连接
     */
    testConnection(): Promise<boolean>;
    /**
     * 确保客户端存在
     * @private
     */
    private ensureClientExists;
    /**
     * 执行测试查询
     * @private
     */
    private performTestQuery;
    /**
     * 评估连接结果
     * @private
     */
    private evaluateConnectionResult;
    /**
     * 验证Auth服务可用性
     */
    testAuthService(): Promise<boolean>;
    /**
     * 检查是否为网络错误
     * @private
     */
    private isNetworkError;
    /**
     * 获取当前配置信息
     */
    getConfig(): SupabaseConfig | null;
    /**
     * 重置配置（主要用于测试）
     */
    reset(): void;
}
//# sourceMappingURL=supabase.d.ts.map