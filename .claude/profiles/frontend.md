# Frontend Development Profile

## 前端开发环境配置
专用于Next.js + Supabase + Tailwind CSS前端开发的Claude Code配置。

### 技术栈焦点
- **框架**: Next.js 14 App Router, TypeScript
- **样式**: Tailwind CSS, Shadcn/ui组件
- **状态管理**: Zustand, React Query
- **认证**: Supabase Auth, JWT验证
- **表单**: React Hook Form, Zod验证

### 开发优先级
1. **用户体验**: 响应式设计，移动端优先
2. **性能优化**: Core Web Vitals, 代码分割
3. **可访问性**: WCAG 2.1 AA标准
4. **类型安全**: TypeScript严格模式

### 常用命令
```bash
# 开发服务器
npm run dev

# 类型检查
npm run type-check

# 组件测试
npm run test:components

# 构建优化
npm run build && npm run analyze

# Supabase类型同步
supabase gen types typescript > types/database.types.ts
```

### 组件架构规范
```
components/
├── ui/          # 基础UI组件 (shadcn/ui)
├── forms/       # 表单组件
├── layouts/     # 布局组件
├── features/    # 业务功能组件
│   ├── prescriptions/
│   ├── pharmacy/
│   └── auth/
└── providers/   # Context Providers
```

### 性能优化清单
- [ ] 使用dynamic import进行代码分割
- [ ] 实施图片优化和lazy loading
- [ ] 配置Service Worker缓存策略
- [ ] 监控Core Web Vitals指标
- [ ] 实施客户端数据缓存

### 可访问性检查
- [ ] 语义化HTML标签使用
- [ ] 键盘导航支持完整
- [ ] 屏幕阅读器兼容性
- [ ] 色彩对比度符合标准
- [ ] 焦点管理和指示器

### 测试策略
- **单元测试**: Jest + Testing Library
- **组件测试**: Storybook交互测试
- **集成测试**: Playwright端到端
- **性能测试**: Lighthouse CI集成