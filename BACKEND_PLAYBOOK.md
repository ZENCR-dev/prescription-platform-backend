# BACKEND_PLAYBOOK.md - Backend Workspace Governance Projection

> **📋 Document Purpose**: Self-contained governance projection enabling backend workspace execution without external dependencies

**Version**: v3.1 - Self-Contained Governance Projection  
**Status**: ✅ Access Constraint Compliant  
**Role**: Complete backend execution guidance via embedded global governance content  

---

## 📝 Changelog

**v3.1 (2025-08-28)**: Self-contained governance projection with embedded content
- **Recovery**: Restored from git rollback operation that caused governance document regression
- **Fixed**: Removed all inaccessible external links to global documents
- **Added**: Embedded essential governance content from global framework
- **Created**: Self-contained projection accessible within backend workspace only
- **Authority**: Global Architect constitutional power exercised for workspace governance

**v3.0**: Governance projection with external links (deprecated - access violations)
**v2.0**: Legacy PRP generation guide (archived due to git rollback)

---

## 🏗️ Backend Layer Execution Framework (Workspace Implementation)

> **📋 Framework Reference**: Complete three-layer architecture defined in global governance documents. This section provides backend-specific implementation guidance only.

### **Backend Layer Execution Pattern**
```yaml
Backend_Execution_Flow:
  Layer_1_Navigation: "PLANNING.md → Backend strategic constraints and API development authority"
  Layer_2_Implementation: "PRPs/PRP-M1.X-*.md → Backend PRP work orders from Global Architect"
  Layer_3_Execution: "TodoWrite todos → Backend 4-Step QAD cycles with Supabase-First compliance"

Backend_Specific_Responsibilities:
  API_Authority_Role: "Exclusive ownership and maintenance of APIdocs/APIv1.md specifications"
  Quality_Gates: "Module Exit Criteria (MEM) validation + API contract delivery"
  Integration_Points: "Backend-First delivery timing + Database infrastructure management"
```

---

## 🎯 Global Governance Framework (Embedded Content)

### Core Constitutional Principles

**Value Stream Delivery Principle**:
All development work is organized into **Milestones**, which represent complete, end-to-end slices of business value that are independently testable and deliver tangible user outcomes. Progress tracking is based on Milestone completion, not individual task completion.

**Backend-First & Contract-Driven Collaboration Principle**:
The backend delivers a stable, documented API contract **before** the frontend begins development, creating a clear and reliable interface between teams.

**Implementation Protocol**:
1. Backend API design and documentation completion
2. Frontend contract review and approval  
3. Backend implementation and testing
4. API documentation finalization
5. Frontend development commencement
6. Integration testing and validation

**API Documentation Authority Mandate**:
Backend workspace maintains exclusive authority over API documentation. Backend team owns and maintains the single source of truth for all API specifications in APIdocs/APIv1.md with complete editorial control and distribution authority.

**Supabase-First Architecture Mandate**:
Supabase serves as the complete backend infrastructure for the platform, eliminating the need for custom backend services while ensuring comprehensive infrastructure management patterns.

**Implementation Requirements**:
- **Database Architecture**: PostgreSQL schema design, migrations, versioning, constraint management
- **Security Infrastructure**: Row Level Security (RLS) policies, authentication rules, data access controls
- **Server-Side Logic**: Supabase Edge Functions for business logic, financial calculations, third-party integrations
- **Data Management**: Database indexes, triggers, stored procedures, views, performance optimization
- **API Authority**: Exclusive authority over APIdocs/APIv1.md content and backend API endpoint specifications

**Zero Patient PII Mandate**:
The **inviolable architectural and ethical constraint** that the system must not store or process any personally identifiable patient information. Backend implementation must architecturally prevent patient PII storage through database design and API endpoint validation.

### "Deal the Card" PRP Distribution System

**Core Principle**: Backend team RECEIVES PRP work orders via global "Deal the Card" mechanism. Backend team NEVER generates PRPs.

**Distribution Protocol**:
```yaml
Distribution Criteria:
  Module_Readiness: Previous module MEM satisfaction required
  Workspace_Capacity: Team bandwidth validation
  Dependency_Satisfaction: All upstream dependencies completed

Distribution Process:
  1. MEM_Validation: Previous module completion verified
  2. PRP_Generation: Module-specific PRP created from official template
  3. Workspace_Placement: PRP file placed in backend workspace /PRPs/ directory
  4. Team_Notification: Backend team notified with implementation expectations
  5. Progress_Monitoring: Implementation tracking and status updates
```

**PRP Template Structure (Layer 2 Tactical Documents for Backend)**:
```markdown
# PRP-MX.Y-ModuleName.md

## **Architect Zone (Immutable Section - Layer 1战略到Layer 2传递)**
- Milestone Context & Business Value (from Layer 1 PLANNING.md)
- Module Objectives & Success Criteria (Layer 1 Backend战略约束)
- Technical Constraints & Dependencies (Layer 1架构决策，Supabase-First原则)
- Module Exit Criteria (MEM) - Layer 2到Layer 1验证要求，API交付验证标准

## **Engineer Zone (Flexible Implementation Section - Layer 2到Layer 3 Backend指导)**
- Component Breakdown & Implementation Plan (Layer 3 Backend原子任务分解指导)
- Testing Strategy & Quality Assurance (Layer 3 Backend质量验证标准)
- Risk Assessment & Mitigation (Layer 3 Backend执行风险控制，Supabase架构遵循)
- Timeline & Resource Allocation (Layer 3 TodoWrite估算指导，API交付时序)

## **Layer 3 Backend执行集成要求**
- 4-Step QAD Cycle Integration: 研究设计 → 实现验证 → 测试优化 → 提交更新
- TodoWrite Usage Standards: Backend Lead使用TodoWrite创建Backend原子任务todos
- Git Branch Mapping: Backend PRP对应task/module分支，Backend todos对应atomic/component分支
- API Documentation Authority: 独占维护APIdocs/APIv1.md，分发给Frontend消费
```

---

## 🚨 Backend-Specific Governance Adaptations

### PRP Reception and Execution (NOT Generation)

**Reception Workflow**:
1. **Global Architect** distributes PRP work order to `PRPs/PRP-MX.Y-*.md`
2. **Backend Team Lead** receives PRP and initiates execution
3. **AI Agent** executes 4-Step QAD Cycle for atomic tasks within PRP
4. **Team Lead** validates completion against Module Exit Criteria (MEM)

### 4-Step QAD (Quality Assurance Driven) Cycle Execution

**Standard Execution Pattern**:
```yaml
Step 1 - Research & Design: 
  - MCP tools integration + Supabase infrastructure best practices discovery
  - Database schema planning + RLS policy architecture design
  - Edge Functions planning + third-party integration patterns analysis

Step 2 - Implement & Validate: 
  - PostgreSQL schema implementation + RLS policy creation
  - Supabase Edge Functions development + business logic implementation
  - API endpoint creation + APIdocs/APIv1.md documentation updates

Step 3 - Test & Optimize: 
  - Database performance testing + RLS policy validation
  - Edge Functions testing + API endpoint integration testing
  - Security validation (zero-PII compliance) + performance optimization

Step 4 - Commit & Update: 
  - Quality gates validation + API documentation completion
  - Git commit with proper naming + development log updates
  - Progress tracking + MEM validation preparation
```

### Backend Core Constraints

**🚨 ABSOLUTE PROHIBITIONS**:
- **Zero Frontend Development**: NEVER create React components or frontend UI - violates workspace boundaries
- **Zero API Consumer Role**: NEVER consume API documentation - Backend creates and owns APIs
- **Zero Frontend Technology**: NEVER use Next.js, @supabase/ssr, or frontend-specific libraries
- **Zero PRP Generation**: NEVER create own PRP work orders - Global Architect exclusive

**✅ MANDATORY REQUIREMENTS**:
- **Supabase-First Compliance**: Use Supabase native features before custom implementations
- **API Authority Role**: Create, maintain, and own all API specifications in APIdocs/APIv1.md
- **Database-First Design**: All API endpoints derive from PostgreSQL schema and RLS policies
- **Module Exit Criteria**: Complete all atomic tasks before MEM validation

### Backend API Authority Governance

**Backend Lead API Authority Role**:
```yaml
Exclusive_Authority:
  - Backend workspace APIdocs/APIv1.md is the single source of truth for all API specifications
  - Complete editorial control over API documentation content and versioning
  - Authority to define API endpoints, parameters, responses, and error codes
  - Power to establish API contract timelines and delivery schedules
  
Development_Operations:
  - Create API specifications after Supabase schema and RLS policy implementation
  - Update APIdocs/APIv1.md in real-time during backend development cycles
  - Record development tasks and API modifications in APIdocs/APIv1_log.md
  - Coordinate with Global Architect on API completion milestones for frontend distribution
  
Documentation_Protocol:
  - Maintain technical implementation details and edge cases in API documentation
  - Document breaking changes and version compatibility notes for consumer guidance
  - Ensure API specifications reflect actual Supabase implementation accuracy
  - Provide comprehensive error handling standards and response format specifications
```

**Global Architect Coordination Interface**:
- **Quality Review**: Submit completed API documentation for Global Architect review and approval
- **Distribution Authorization**: Await Global Architect approval before API documentation distribution to frontend
- **Change Coordination**: Coordinate API contract changes through Global Architect oversight
- **Integration Support**: Provide technical clarification on API specifications when needed

---

## 📊 Engineering Unit Definitions (EUDs) - Backend Development Estimation System

### **EUDs概念定义 (Backend Implementation)**
Engineering Unit Definitions (EUDs) 是一套**客观、可计算的工程量度系统**，专为Backend开发工作量本质设计，实现基于Supabase架构复杂性的精确规划和进度跟踪。

### **Backend-Specific EUDs四层架构体系**
```yaml
# Backend EUD层次结构 (自顶向下)
Milestone (里程碑级):
  definition: "完整的后端业务价值交付单元"
  composition: "3-7个Backend Module组成"
  example: "M1: 核心认证与数据库架构系统"
  
Module (模块级):
  definition: "里程碑内的后端功能组件单元"
  composition: "5-15个Backend Component组成"
  example: "M1.1: Supabase认证基础设施, M1.2: 数据库RLS策略系统"
  
Component (组件级):
  definition: "模块内的后端技术实现单元"
  composition: "3-8个Backend Dev-Step组成"
  example: "RLS策略组件, Edge Functions组件, 数据库迁移组件"
  
Dev-Step (原子级):
  definition: "最小后端工作单元 = 一个完整的4-Step QAD循环"
  composition: "Research → Implement → Test → Commit (Supabase-focused)"
  example: "一个完整的数据库-API-文档周期"
```

### **Backend EUDs计算规则**
```yaml
# Backend专用计算公式
Backend Dev-Step = 1 complete Backend 4-Step QAD Cycle:
  - 1 Research phase (Supabase最佳实践和数据库架构分析)
  - 1 Implementation phase (PostgreSQL+Edge Functions实现)
  - 1 Testing phase (RLS策略和API端点验证)
  - 1 Commit phase (APIdocs/APIv1.md更新和代码提交)

Backend Component = 3-8 Dev-Steps:
  - Simple Component: 3-4 Dev-Steps (基础数据表, 简单API端点)
  - Medium Component: 5-6 Dev-Steps (复杂RLS策略, Edge Functions)
  - Complex Component: 7-8 Dev-Steps (财务计算引擎, 集成系统)

Backend Module = 5-15 Components:
  - Infrastructure Module: 5-8 Components (基础架构搭建)
  - Business Logic Module: 9-12 Components (业务逻辑实现)
  - Integration Module: 13-15 Components (复杂系统集成)

Backend Milestone = 3-7 Modules:
  - Foundation Milestone: 3-4 Modules (基础设施里程碑)
  - Feature Milestone: 5-6 Modules (功能开发里程碑)
  - Platform Milestone: 7 Modules (完整平台里程碑)
```

### **Backend EUDs特殊考虑**

**Supabase架构复杂性的EUD计算**:
```yaml
Supabase_Complexity_Factors:
  Database_Schema: 标准EUD计算 + 关系复杂度调整
  RLS_Policy: EUD × 1.3 (安全策略复杂性系数)
  Edge_Functions: EUD × 1.5 (服务器端逻辑复杂性系数)
  Third_Party_Integration: EUD × 1.4 (外部服务集成复杂性系数)
  
Example:
  - Basic Table Creation: 3 Dev-Steps (标准)
  - RLS Policy Implementation: 3 × 1.3 = 4 Dev-Steps (安全增强)
  - Edge Function + Integration: 4 × 1.5 = 6 Dev-Steps (业务逻辑复杂性)
```

**Backend质量验证的EUD增强**:
```yaml
Backend-Specific Quality Gates:
  - API Documentation: +1 Dev-Step per API endpoint
  - RLS Policy Testing: +1 Dev-Step per security policy
  - Performance Optimization: +1 Dev-Step per database query optimization
  - Integration Testing: +1 Dev-Step per third-party service integration
  
Adjusted Backend EUD Calculation:
  Base Component EUDs + Backend Quality Enhancement EUDs = Total Backend EUDs
```

---

## 🔧 Backend Execution Standards

### Branch Naming Convention (Unified Standard)
```bash
# Atomic task branches (consistent with frontend)
^prp-m1\.[1-6]-[a-z0-9-]+-atomic-[0-9]{3}$

# Examples:
prp-m1.1-auth-backend-atomic-001
prp-m1.2-database-rls-atomic-002
```

### Development Log Standards
```markdown
# Log file naming: PRPs/PRP-MX.Y-*_LOG.md
# Format: [YYYY-MM-DD HH:MM:SS] 🎯 QAD-Step - PRP-MX.Y-ModuleName
```

### Technology Stack Boundaries
```yaml
Backend Exclusive Technologies:
  - PostgreSQL + RLS: Complete database architecture and security
  - Supabase Edge Functions: Server-side business logic and integrations
  - Supabase Auth Configuration: Authentication system infrastructure
  - Database Migrations: Schema versioning and deployment
  - API Documentation: APIdocs/APIv1.md exclusive ownership

Shared Technologies (Backend Configured, Frontend Consumed):
  - Supabase Auth: Authentication system (Backend configures, Frontend uses)
  - Supabase Realtime: Real-time subscriptions (Backend enables, Frontend subscribes)
  - Supabase Storage: File storage (Backend policies, Frontend operations)

Prohibited Technologies:
  - Next.js applications: Frontend exclusive
  - React components: Frontend exclusive  
  - @supabase/ssr integration: Frontend exclusive
  - Frontend UI libraries: Frontend exclusive
```

---

## 🛡️ Compliance and Validation Framework

### Quality Gates (Embedded Global Framework)
```yaml
Pre-Implementation Quality Gates:
  - PRP received from Global Architect ✓
  - Supabase infrastructure requirements validated ✓
  - Database schema designed with zero-PII compliance ✓
  - API contract architecture aligned with business requirements ✓

Implementation Validation Gates:
  - 4-Step QAD Cycle completed for all components ✓
  - PostgreSQL schema implementation with RLS policies ✓
  - Edge Functions development with business logic validation ✓
  - APIdocs/APIv1.md updated with comprehensive API specifications ✓
  - Zero-PII compliance verified at database and API layers ✓

Pre-Commit Validation Gates:
  - Backend boundary validation passed ✓
  - API documentation completeness verified ✓
  - All quality gates completed successfully ✓
  - Database testing coverage >90% achieved ✓
```

### Medical Platform Compliance Requirements
```yaml
HIPAA Compliance (Backend Responsibilities):
  - Zero patient PII in database schema design ✓
  - RLS policies preventing unauthorized patient data access ✓
  - Audit trail implementation for all data operations ✓
  - Secure API endpoint design with comprehensive access logging ✓
  
Financial Compliance (Backend Responsibilities):
  - NZD cents precision in all monetary calculations ✓
  - Banking-grade transaction integrity with ACID compliance ✓
  - Complete financial audit trail with immutable logging ✓
  - Payment processing integration with security validation ✓

Security Compliance (Server-Side):
  - RLS policy implementation for multi-tenant data isolation ✓
  - Edge Function security with input validation and sanitization ✓
  - API authentication and authorization with role-based access control ✓
  - Database encryption at rest and secure connection protocols ✓
```

---

## 📋 B2B2C Traditional Chinese Medicine Platform Context

### Business Model Understanding (Backend Perspective)
**Practitioner-Pays Model**: Backend systems manage practitioner account balances, automatic prescription payment processing, and pharmacy settlement calculations, enabling patients to access traditional medicine through QR codes without payment barriers.

**Backend Role in Business Flow**:
1. **Practitioner Account Management**: Balance tracking, payment processing, transaction history
2. **Prescription Processing**: Digital prescription storage, QR code generation, status tracking
3. **Pharmacy Integration**: Order management, fulfillment tracking, payment calculation
4. **Financial Settlement**: Revenue calculation, pharmacy payments, platform profit tracking

### Medical Platform Specific Requirements (Backend Implementation)
```yaml
TCM Prescription Data Management:
  - Herb specification storage with dosage validation ✓
  - Traditional medicine database integration with safety protocols ✓
  - Prescription validation and clinical safety checking ✓
  - Professional practitioner workflow optimization with audit trails ✓

Anonymous Patient Data Architecture:
  - QR code generation with encrypted prescription data ✓
  - Prescription storage with zero PII database design ✓
  - Privacy-first architecture implementation at database layer ✓
  - Pharmacy integration without patient identification requirements ✓

Financial Processing Infrastructure:
  - Account balance management with real-time debit processing ✓
  - Precision financial calculations with NZD cents accuracy ✓
  - Transaction processing with comprehensive audit trails ✓
  - Platform revenue calculation and pharmacy payment automation ✓
```

---

## 📋 PRP Execution Entry Point

### Active PRP Navigation
- **Current Work Orders**: Check [`PLANNING.md`](PLANNING.md) for active M1 Backend PRP index
- **PRP Documents**: Execute tasks from `PRPs/PRP-MX.Y-*.md` files
- **Execution Rules**: Follow [`CLAUDE.md`](CLAUDE.md) for detailed AI Agent execution protocols

### API Documentation Authority Protocol
```yaml
API Development Authority:
  - Maintain exclusive control over APIdocs/APIv1.md content and versioning
  - Update API documentation in real-time during backend development cycles
  - Coordinate API contract delivery timelines with Global Architect for frontend distribution
  - Provide technical clarification and implementation details for API consumer guidance

Quality Coordination:
  - Align API documentation with Supabase schema implementation accuracy
  - Coordinate API completion milestones with Module Exit Criteria (MEM) validation
  - Participate in Global Architect quality reviews and approval processes
  - Maintain comprehensive error handling and response format documentation
```

---

## 🔗 Workspace Reference System

### Execution Documents (This Workspace)
- **Task Navigation**: [`PLANNING.md`](PLANNING.md) - Backend PRP tracking and status
- **Execution Rules**: [`CLAUDE.md`](CLAUDE.md) - AI Agent execution protocols
- **Environment Setup**: [`DevEnv.md`](DevEnv.md) - Development environment configuration

### API Documentation Authority
- **Primary Source**: [`APIdocs/APIv1.md`](APIdocs/APIv1.md) - Backend exclusive ownership
- **Development Log**: [`APIdocs/APIv1_log.md`](APIdocs/APIv1_log.md) - Backend development tracking

### Archive and History
- **Previous Version**: [`archive/PROJECT_PLAYBOOK_v2.0.md`](archive/PROJECT_PLAYBOOK_v2.0.md)

### Validation Scripts (Local Workspace)
- **PRP Boundary Validator**: [`scripts/prp-boundary-validator.sh`](scripts/prp-boundary-validator.sh)
- **API Consistency Checker**: [`scripts/api-consistency-checker.sh`](scripts/api-consistency-checker.sh)

---

**📊 Document Status**: ✅ **Self-Contained Governance Projection** | 🔗 **Access Constraint Compliant** | 🚀 **Backend Execution Ready**

**🔍 Git Rollback Recovery**: Successfully restored governance content from global framework projection on 2025-08-28 - Complete backend governance autonomy established.

*This document serves as a complete self-contained projection of global governance framework for backend workspace execution. All essential governance content is embedded to ensure accessibility within workspace boundaries. No external document dependencies required for autonomous backend development execution.*