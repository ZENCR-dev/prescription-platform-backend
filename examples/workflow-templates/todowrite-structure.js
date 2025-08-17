// TodoWrite Structure Template - v6.0 3+1 Steps Mode
// Source: CLAUDE.md Lines 209-237 (TodoWrite数据结构示例)

/**
 * Agent生成的临时TodoWrite示例 (3+1步骤模式)
 * 核心原则：实时更新、单一活跃、验证驱动、上下文链接、日志记录
 */

const todoWriteTemplate = [
  {
    id: "task0x-step1",
    content: "【backend persona】需求分析与设计 - 分析组件需求，设计技术方案", 
    status: "completed",
    priority: "high"
  },
  {
    id: "task0x-step2",
    content: "【backend persona】实现与自测 - 完成组件开发和基础单元测试", 
    status: "in_progress",
    priority: "high"
  },
  {
    id: "task0x-step3", 
    content: "【backend persona】集成准备 - 验证接口兼容性，准备集成文档",
    status: "pending",
    priority: "medium"
  },
  {
    id: "task0x-step4",
    content: "【qa persona】质量验证与提交 - 运行测试，代码审查，提交代码",  
    status: "pending",
    priority: "high"
  }
];

/**
 * TodoWrite Core Principles
 */
const coreProniciples = {
  realTimeUpdate: "每完成一个步骤立即更新todo状态",
  singleActive: "同时只有一个todo处于in_progress状态",
  validationDriven: "每个todo完成必须有明确的验证标准",
  contextLinking: "每个todo包含对Layer 2 atomic task的引用",
  logRecording: "每个todo执行时必须记录到对应的TASK0X_LOG.md"
};

/**
 * Status Management
 */
const statusDefinitions = {
  pending: "Ready for execution",
  in_progress: "Currently active (ONE per session)",
  completed: "Successfully finished",
  blocked: "Waiting on dependency"
};

/**
 * Priority Guidelines
 */
const priorityGuidelines = {
  high: "Critical path items, step 1, step 2, step 4",
  medium: "Integration preparation, step 3",
  low: "Documentation updates, cleanup tasks"
};

/**
 * Persona Assignment Examples
 */
const personaExamples = {
  frontend: {
    step1: "【frontend persona】需求分析与设计 - 分析UI组件需求，设计交互方案",
    step2: "【frontend persona】实现与自测 - 完成组件开发和基础测试",
    step3: "【frontend persona】集成准备 - 验证API接口，准备集成测试",
    step4: "【qa persona】质量验证与提交 - 运行E2E测试，代码审查"
  },
  
  backend: {
    step1: "【backend persona】需求分析与设计 - 分析API需求，设计数据模型",
    step2: "【backend persona】实现与自测 - 完成API开发和单元测试",
    step3: "【backend persona】集成准备 - 验证数据库集成，准备部署",
    step4: "【qa persona】质量验证与提交 - 运行集成测试，安全检查"
  },
  
  architect: {
    step1: "【architect persona】需求分析与设计 - 分析系统需求，设计架构方案",
    step2: "【architect persona】实现与自测 - 完成架构实现和验证",
    step3: "【architect persona】集成准备 - 验证系统集成，准备迁移",
    step4: "【qa persona】质量验证与提交 - 运行系统测试，架构审查"
  }
};

/**
 * Medical Platform Special Considerations
 */
const medicalPlatformTodos = {
  securitySensitive: {
    step1: "【backend persona】需求分析与设计 - 分析安全需求，设计HIPAA合规方案",
    step2: "【backend persona】实现与自测 - 完成安全实现和合规验证",
    step3: "【backend persona】集成准备 - 验证安全集成，准备合规审计",
    step4: "【qa persona】质量验证与提交 - 运行安全测试，合规检查"
  }
};

/**
 * Usage Examples
 */
const usageExamples = {
  createTodos: `
// Create todos for atomic task
TodoWrite([
  {
    id: "task05-01-step1",
    content: "【backend persona】需求分析与设计 - 分析处方API需求，设计数据模型",
    status: "pending",
    priority: "high"
  },
  // ... other steps
]);
  `,
  
  updateStatus: `
// Update status after completing step
TodoWrite([
  {
    id: "task05-01-step1",
    content: "【backend persona】需求分析与设计 - 分析处方API需求，设计数据模型",
    status: "completed",
    priority: "high"
  },
  {
    id: "task05-01-step2",
    content: "【backend persona】实现与自测 - 完成API开发和单元测试",
    status: "in_progress",
    priority: "high"
  },
  // ... other steps
]);
  `
};

module.exports = {
  todoWriteTemplate,
  coreProniciples,
  statusDefinitions,
  priorityGuidelines,
  personaExamples,
  medicalPlatformTodos,
  usageExamples
};