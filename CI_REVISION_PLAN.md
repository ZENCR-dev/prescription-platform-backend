# 📋 CI自检修订计划

**生成日期**: 2025-09-01
**执行状态**: M1.1基本功能已完成，CI质量检查存在问题需修复

## 一、测试结果概览

### ✅ 通过项目 (5/8)
- ✅ 数据库迁移: 9个迁移文件全部成功应用
- ✅ JWT Claims测试: 6/6测试用例通过
- ✅ PRP边界验证: 0违规，完全符合PROJECT_PLAYBOOK.md
- ✅ 数据库权限: anon角色权限正确配置
- ✅ psql配置: PostgreSQL客户端工具已正确安装配置

### ❌ 失败项目 (3/8)
- ❌ API文档中心化: 2个违规，33个文件包含分散API定义
- ❌ ESLint检查: 285个错误，14个警告
- ❌ TypeScript编译: Deno运行时类型定义缺失

## 二、问题详细分析

### 1. API文档中心化违规
**问题描述**: 
- 33个文件包含分散的API定义（POST/GET/PUT/DELETE）
- 前端项目包含独立的API文档副本
- 违反黄金法则2：API文档中心化管理

**影响范围**: 
- 架构合规性风险
- API版本不一致风险
- 前后端协作困难

**根本原因**:
- 历史文档未清理
- 示例文件包含API示例
- 文档模板包含API引用

### 2. Edge Functions类型错误
**问题描述**:
- TypeScript无法识别Deno运行时导入
- 285个ESLint错误（主要是格式问题）
- any类型使用过多

**影响范围**:
- Edge Functions无法通过类型检查
- 代码质量不达标
- CI/CD pipeline阻塞

**根本原因**:
- tsconfig.json配置为Node环境而非Deno
- ESLint规则未适配Deno环境
- 缺少Deno类型定义文件

## 三、修订计划

### Phase 1: 紧急修复（1天内完成）

#### 1.1 修复TypeScript配置
```bash
# 创建Edge Functions专用tsconfig
cat > supabase/functions/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022", "DOM"],
    "types": [],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "allowJs": true,
    "noEmit": true
  },
  "include": ["./**/*.ts"],
  "exclude": ["**/*.test.ts"]
}
EOF
```

#### 1.2 修复Edge Functions导入
- 所有Edge Functions添加Deno类型声明注释
- 修复import语句格式符合Deno标准
- 清理不必要的any类型使用

#### 1.3 运行自动修复
```bash
npm run lint:fix  # 修复254个Prettier格式问题
```

### Phase 2: API文档清理（2天内完成）

#### 2.1 清理分散API定义
需要清理的文件类别：
- `/drafts/*` - 草稿文件，可安全清理API定义
- `/recycle/*` - 回收站文件，可安全清理
- `/examples/*` - 示例文件，保留但添加注释说明
- `/prd-reverse-engineering/*` - 历史文档，归档处理

#### 2.2 更新引用规范
- 所有新PRP必须引用 `APIdocs/APIv1.md`
- 添加pre-commit hook检查API定义分散

### Phase 3: 质量保障体系（3天内完成）

#### 3.1 Edge Functions测试环境
```bash
# 安装Deno
curl -fsSL https://deno.land/x/install/install.sh | sh

# 配置Deno测试脚本
npm run test:functions
```

#### 3.2 CI/CD Pipeline配置
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: supabase/setup-cli@v1
      - run: npm ci
      - run: npm run ci:check
      - run: npm run lint
      - run: npm run type-check
      - run: npm run test
```

#### 3.3 Pre-commit Hooks
```bash
# 安装husky
npm install --save-dev husky
npx husky install

# 添加pre-commit hook
npx husky add .husky/pre-commit "npm run ci:check"
```

## 四、执行时间表

| 阶段 | 任务 | 优先级 | 预计时间 | 责任人 |
|------|------|--------|----------|--------|
| Phase 1.1 | 修复TypeScript配置 | P0-紧急 | 2小时 | Backend Lead |
| Phase 1.2 | 修复Edge Functions | P0-紧急 | 4小时 | Backend Lead |
| Phase 1.3 | 运行自动修复 | P0-紧急 | 1小时 | Backend Lead |
| Phase 2.1 | 清理分散API | P1-高 | 1天 | Backend Lead |
| Phase 2.2 | 更新引用规范 | P1-高 | 2小时 | Backend Lead |
| Phase 3.1 | Deno测试环境 | P2-中 | 4小时 | Backend Lead |
| Phase 3.2 | CI/CD配置 | P2-中 | 1天 | DevOps |
| Phase 3.3 | Pre-commit | P2-中 | 2小时 | Backend Lead |

## 五、成功标准

### 短期目标（1周内）
- [ ] 所有CI检查通过（0错误，<10警告）
- [ ] API文档100%中心化
- [ ] Edge Functions类型安全
- [ ] 自动化测试覆盖率>80%

### 长期目标（1月内）
- [ ] CI/CD全自动化
- [ ] 0技术债务积累
- [ ] 代码质量评级A级
- [ ] 性能基准<200ms

## 六、风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Deno环境配置复杂 | 中 | 高 | 使用Docker容器化 |
| API清理影响现有功能 | 低 | 高 | 增量清理，保留备份 |
| CI时间过长 | 中 | 中 | 并行执行，缓存优化 |
| 团队学习成本 | 高 | 中 | 编写详细文档，培训 |

## 七、监控指标

### 质量指标
- ESLint错误数: 目标<10
- TypeScript错误数: 目标0
- 测试覆盖率: 目标>80%
- API文档分散度: 目标0

### 性能指标
- CI执行时间: <5分钟
- 本地测试时间: <2分钟
- Type-check时间: <30秒

## 八、下一步行动

### 立即执行（今天）
1. 修复 `database.types.ts` 文件语法错误 ✅
2. 运行 `npm run lint:fix` 自动修复格式问题
3. 创建Edge Functions专用tsconfig配置
4. 更新package.json脚本适配Deno

### 明天执行
1. 清理 `/drafts` 和 `/recycle` 目录的API定义
2. 安装配置Deno运行时
3. 修复剩余的TypeScript类型错误

### 本周完成
1. 完成所有API文档清理
2. 配置CI/CD pipeline
3. 达到质量门槛标准

## 九、参考文档

- [Supabase Edge Functions文档](https://supabase.com/docs/guides/functions)
- [Deno TypeScript配置](https://deno.land/manual/typescript)
- [PROJECT_PLAYBOOK.md](./PROJECT_PLAYBOOK.md) - 协作规范
- [CLAUDE.md](./CLAUDE.md) - 执行规则

---

**修订状态**: 📝 待执行
**最后更新**: 2025-09-01
**下次复查**: 2025-09-03