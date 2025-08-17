/**
 * Supabase配置TDD测试
 * TDD红灯阶段：编写应该失败的测试用例
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { SupabaseConfigManager } from '../../src/config/supabase'

// Mock Supabase客户端
const mockSupabaseClient = {
  from: vi.fn(),
  auth: {
    getUser: vi.fn()
  }
}

vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn(() => mockSupabaseClient)
}))

vi.mock('dotenv', () => ({
  config: vi.fn()
}))

describe('SupabaseConfigManager - TDD红灯测试', () => {
  let configManager: SupabaseConfigManager

  beforeEach(() => {
    // 清除所有环境变量
    vi.unstubAllEnvs()
    
    // 重置mock
    vi.clearAllMocks()
    
    configManager = SupabaseConfigManager.getInstance()
    configManager.reset()
  })

  describe('环境变量验证测试 - 应该失败', () => {
    it('应该在缺少SUPABASE_URL时抛出错误', () => {
      // 设置无效环境变量 - 不设置SUPABASE_URL
      vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project')
      
      expect(() => {
        configManager.validateConfig()
      }).toThrow('SUPABASE_URL environment variable is required')
    })

    it('应该在缺少SUPABASE_ANON_KEY时抛出错误', () => {
      vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project')
      // 不设置SUPABASE_ANON_KEY
      
      expect(() => {
        configManager.validateConfig()
      }).toThrow('SUPABASE_ANON_KEY environment variable is required')
    })

    it('应该在缺少SUPABASE_PROJECT_ID时抛出错误', () => {
      vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co')
      vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key')
      // 不设置SUPABASE_PROJECT_ID
      
      expect(() => {
        configManager.validateConfig()
      }).toThrow('SUPABASE_PROJECT_ID environment variable is required')
    })

    it('应该在SUPABASE_URL格式无效时抛出错误', () => {
      vi.stubEnv('SUPABASE_URL', 'invalid-url')
      vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project')
      
      expect(() => {
        configManager.validateConfig()
      }).toThrow('Invalid SUPABASE_URL format')
    })
  })

  describe('Supabase客户端创建测试 - 应该失败', () => {
    it('应该在配置无效时无法创建客户端', () => {
      // 未设置任何环境变量的情况下尝试创建客户端
      expect(() => {
        configManager.createClient()
      }).toThrow()
    })

    it('应该在请求Service Role但未提供密钥时抛出错误', () => {
      // 设置基本配置但不设置Service Role Key
      vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co')
      vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project')
      // 不设置SUPABASE_SERVICE_ROLE_KEY
      
      // 先验证配置以设置基本配置
      configManager.validateConfig()
      
      expect(() => {
        configManager.createClient(true) // 请求Service Role
      }).toThrow('Service Role Key is required for admin operations')
    })
  })

  describe('连接测试 - 应该失败（因为尚未配置真实项目）', () => {
    it('应该在没有有效Supabase项目时连接失败', async () => {
      // 使用虚假的配置
      vi.stubEnv('SUPABASE_URL', 'https://fake-project.supabase.co')
      vi.stubEnv('SUPABASE_ANON_KEY', 'fake-anon-key')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'fake-project')
      
      // 模拟网络错误
      mockSupabaseClient.from.mockReturnValue({
        select: vi.fn().mockReturnValue({
          limit: vi.fn().mockResolvedValue({
            data: null,
            error: { message: 'Failed to fetch', code: 'NETWORK_ERROR' }
          })
        })
      })
      
      configManager.validateConfig()
      configManager.createClient()
      
      const isConnected = await configManager.testConnection()
      expect(isConnected).toBe(false)
    })

    it('应该在Auth服务配置错误时验证失败', async () => {
      // 使用虚假的配置
      vi.stubEnv('SUPABASE_URL', 'https://fake-project.supabase.co')
      vi.stubEnv('SUPABASE_ANON_KEY', 'fake-anon-key')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'fake-project')
      
      // 模拟Auth服务网络错误
      mockSupabaseClient.auth.getUser.mockResolvedValue({
        data: null,
        error: { message: 'NetworkError: Failed to fetch' }
      })
      
      configManager.validateConfig()
      configManager.createClient()
      
      const isAuthWorking = await configManager.testAuthService()
      expect(isAuthWorking).toBe(false)
    })
  })

  describe('单例模式测试', () => {
    it('应该返回相同的实例', () => {
      const instance1 = SupabaseConfigManager.getInstance()
      const instance2 = SupabaseConfigManager.getInstance()
      
      expect(instance1).toBe(instance2)
    })
  })

  describe('配置获取测试', () => {
    it('应该在未验证配置时返回null', () => {
      const config = configManager.getConfig()
      expect(config).toBeNull()
    })
    
    it('应该在验证配置后返回正确的配置对象', () => {
      vi.stubEnv('SUPABASE_URL', 'https://test-project.supabase.co')
      vi.stubEnv('SUPABASE_ANON_KEY', 'test-anon-key')
      vi.stubEnv('SUPABASE_PROJECT_ID', 'test-project')
      vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
      
      const validatedConfig = configManager.validateConfig()
      const retrievedConfig = configManager.getConfig()
      
      expect(retrievedConfig).toEqual(validatedConfig)
      expect(retrievedConfig).toEqual({
        url: 'https://test-project.supabase.co',
        anonKey: 'test-anon-key',
        serviceRoleKey: 'test-service-key',
        projectId: 'test-project'
      })
    })
  })
})