/**
 * Supabase配置模块
 * 负责管理Supabase客户端连接和环境变量验证
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { config } from 'dotenv'

// 加载环境变量
config()

export interface SupabaseConfig {
  url: string
  anonKey: string
  serviceRoleKey?: string
  projectId: string
}

/**
 * 环境变量键名常量
 */
export const ENV_KEYS = {
  SUPABASE_URL: 'SUPABASE_URL',
  SUPABASE_ANON_KEY: 'SUPABASE_ANON_KEY',
  SUPABASE_SERVICE_ROLE_KEY: 'SUPABASE_SERVICE_ROLE_KEY',
  SUPABASE_PROJECT_ID: 'SUPABASE_PROJECT_ID'
} as const

/**
 * 错误类型枚举
 */
export enum ConfigErrorType {
  MISSING_URL = 'SUPABASE_URL environment variable is required',
  MISSING_ANON_KEY = 'SUPABASE_ANON_KEY environment variable is required',
  MISSING_PROJECT_ID = 'SUPABASE_PROJECT_ID environment variable is required',
  INVALID_URL_FORMAT = 'Invalid SUPABASE_URL format. Expected: https://project-id.supabase.co',
  MISSING_SERVICE_ROLE = 'Service Role Key is required for admin operations'
}

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
] as const

export class SupabaseConfigManager {
  private static instance: SupabaseConfigManager
  private client: SupabaseClient | null = null
  private config: SupabaseConfig | null = null

  private constructor() {}

  public static getInstance(): SupabaseConfigManager {
    if (!SupabaseConfigManager.instance) {
      SupabaseConfigManager.instance = new SupabaseConfigManager()
    }
    return SupabaseConfigManager.instance
  }

  /**
   * 验证环境变量配置
   * @throws Error 当配置不完整时抛出错误
   */
  public validateConfig(): SupabaseConfig {
    const url = process.env[ENV_KEYS.SUPABASE_URL]
    const anonKey = process.env[ENV_KEYS.SUPABASE_ANON_KEY]
    const serviceRoleKey = process.env[ENV_KEYS.SUPABASE_SERVICE_ROLE_KEY]
    const projectId = process.env[ENV_KEYS.SUPABASE_PROJECT_ID]

    // 验证必需的环境变量
    this.validateRequiredEnvVars({ url, anonKey, projectId })
    
    // 验证URL格式
    this.validateUrlFormat(url!)

    this.config = {
      url: url!,
      anonKey: anonKey!,
      serviceRoleKey,
      projectId: projectId!
    }

    return this.config
  }

  /**
   * 验证必需的环境变量
   * @private
   */
  private validateRequiredEnvVars(vars: { url?: string, anonKey?: string, projectId?: string }): void {
    if (!vars.url) {
      throw new Error(ConfigErrorType.MISSING_URL)
    }

    if (!vars.anonKey) {
      throw new Error(ConfigErrorType.MISSING_ANON_KEY)
    }

    if (!vars.projectId) {
      throw new Error(ConfigErrorType.MISSING_PROJECT_ID)
    }
  }

  /**
   * 验证Supabase URL格式
   * @private
   */
  private validateUrlFormat(url: string): void {
    const supabaseUrlPattern = /^https:\/\/[a-zA-Z0-9-]+\.supabase\.co$/
    if (!url.match(supabaseUrlPattern)) {
      throw new Error(ConfigErrorType.INVALID_URL_FORMAT)
    }
  }

  /**
   * 创建Supabase客户端
   * @param useServiceRole 是否使用Service Role Key（默认false）
   */
  public createClient(useServiceRole: boolean = false): SupabaseClient {
    if (!this.config) {
      this.validateConfig()
    }

    const key = this.selectApiKey(useServiceRole)
    this.client = createClient(this.config!.url, key)
    return this.client
  }

  /**
   * 选择合适的API密钥
   * @private
   */
  private selectApiKey(useServiceRole: boolean): string {
    const key = useServiceRole ? this.config!.serviceRoleKey : this.config!.anonKey
    
    if (useServiceRole && !key) {
      throw new Error(ConfigErrorType.MISSING_SERVICE_ROLE)
    }

    return key!
  }

  /**
   * 测试数据库连接
   */
  public async testConnection(): Promise<boolean> {
    try {
      this.ensureClientExists()

      const { data, error } = await this.performTestQuery()
      return this.evaluateConnectionResult(error)
    } catch (error: any) {
      console.error('Supabase连接测试失败:', error)
      return this.isNetworkError(error) ? false : false
    }
  }

  /**
   * 确保客户端存在
   * @private
   */
  private ensureClientExists(): void {
    if (!this.client) {
      this.createClient()
    }
  }

  /**
   * 执行测试查询
   * @private
   */
  private async performTestQuery() {
    return this.client!
      .from('_dummy_connection_test')
      .select('*')
      .limit(1)
  }

  /**
   * 评估连接结果
   * @private
   */
  private evaluateConnectionResult(error: any): boolean {
    if (!error) return true

    // 检查是否是网络连接错误或其他关键错误
    const isNetworkError = NETWORK_ERROR_INDICATORS.some(indicator => 
      error.message?.includes(indicator)
    )

    return !isNetworkError && error.code !== 'PGRST301'
  }

  /**
   * 验证Auth服务可用性
   */
  public async testAuthService(): Promise<boolean> {
    try {
      this.ensureClientExists()

      const { data, error } = await this.client!.auth.getUser()
      
      // 检查是否是网络连接错误
      if (error && this.isNetworkError(error)) {
        return false
      }
      
      // 对于匿名连接，用户应该是null，但不应该有严重错误
      return true
    } catch (error: any) {
      console.error('Supabase Auth服务测试失败:', error)
      return this.isNetworkError(error) ? false : false
    }
  }

  /**
   * 检查是否为网络错误
   * @private
   */
  private isNetworkError(error: any): boolean {
    if (!error?.message) return false
    
    return NETWORK_ERROR_INDICATORS.some(indicator => 
      error.message.includes(indicator)
    )
  }

  /**
   * 获取当前配置信息
   */
  public getConfig(): SupabaseConfig | null {
    return this.config
  }

  /**
   * 重置配置（主要用于测试）
   */
  public reset(): void {
    this.client = null
    this.config = null
  }
}