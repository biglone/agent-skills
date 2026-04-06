---
name: migration-helper
description: 数据库迁移和框架升级指导。当用户要求数据库迁移、版本升级、框架迁移时使用。
allowed-tools: Read, Grep, Glob, Bash
---

# 迁移助手

## 数据库迁移

### 迁移工具

#### Prisma (Node.js)
```bash
# 创建迁移
npx prisma migrate dev --name init

# 应用迁移
npx prisma migrate deploy

# 重置数据库
npx prisma migrate reset

# 查看迁移状态
npx prisma migrate status
```

#### Sequelize (Node.js)
```bash
# 创建迁移
npx sequelize migration:create --name create-users

# 运行迁移
npx sequelize db:migrate

# 回滚迁移
npx sequelize db:migrate:undo
npx sequelize db:migrate:undo:all
```

#### Alembic (Python/SQLAlchemy)
```bash
# 初始化
alembic init migrations

# 创建迁移
alembic revision --autogenerate -m "create users table"

# 运行迁移
alembic upgrade head

# 回滚
alembic downgrade -1
```

#### Rails
```bash
# 创建迁移
rails generate migration CreateUsers

# 运行迁移
rails db:migrate

# 回滚
rails db:rollback
rails db:rollback STEP=3
```

### 迁移脚本示例

```javascript
// Prisma schema
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  posts     Post[]
}

// 添加新字段的迁移
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  avatar    String?  // 新增字段
  createdAt DateTime @default(now())
  posts     Post[]
}
```

```javascript
// Sequelize 迁移
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('users', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      email: {
        type: Sequelize.STRING,
        unique: true,
        allowNull: false,
      },
      name: Sequelize.STRING,
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE,
    });
  },

  down: async (queryInterface) => {
    await queryInterface.dropTable('users');
  },
};
```

### 数据迁移最佳实践

1. **备份数据** - 迁移前必须备份
2. **小步迭代** - 分多次小迁移
3. **可回滚** - 确保能回滚
4. **测试环境先行** - 先在测试环境验证
5. **监控性能** - 大表迁移注意锁和性能

## 框架升级

### React 16 → 18
```javascript
// 旧版 ReactDOM.render
import ReactDOM from 'react-dom';
ReactDOM.render(<App />, document.getElementById('root'));

// 新版 createRoot
import { createRoot } from 'react-dom/client';
const root = createRoot(document.getElementById('root'));
root.render(<App />);
```

**主要变更**:
- Concurrent Mode
- Automatic Batching
- Suspense 改进
- 新 Hooks: useId, useTransition, useDeferredValue

### Vue 2 → 3
```javascript
// Vue 2
new Vue({
  el: '#app',
  data: {
    count: 0
  }
});

// Vue 3
import { createApp, ref } from 'vue';

const app = createApp({
  setup() {
    const count = ref(0);
    return { count };
  }
});
app.mount('#app');
```

**主要变更**:
- Composition API
- `<script setup>` 语法
- Teleport, Suspense
- 多根节点组件
- v-model 改变

### Node.js 升级

```bash
# 检查兼容性
npx npm-check-updates

# 更新 package.json
npx npm-check-updates -u

# 检查 Node.js 版本要求
node -v
```

**常见问题**:
- CommonJS → ESM
- 废弃的 API
- 依赖兼容性

### TypeScript 升级

```bash
# 安装新版本
npm install typescript@latest

# 检查错误
npx tsc --noEmit
```

**常见变更**:
- 更严格的类型检查
- 新语法特性
- 配置选项变化

## 迁移清单

### 升级前
- [ ] 阅读升级指南/CHANGELOG
- [ ] 检查依赖兼容性
- [ ] 备份代码和数据
- [ ] 创建迁移分支
- [ ] 制定回滚计划

### 升级中
- [ ] 更新依赖版本
- [ ] 修复破坏性变更
- [ ] 更新废弃的 API
- [ ] 运行测试
- [ ] 修复类型错误

### 升级后
- [ ] 全面测试
- [ ] 性能测试
- [ ] 更新文档
- [ ] 通知团队
- [ ] 监控生产环境

## 常见迁移场景

### 数据库类型迁移
```
MySQL → PostgreSQL
- 检查数据类型差异
- 检查 SQL 语法差异
- 迁移存储过程/函数
- 测试数据完整性
```

### ORM 迁移
```
Sequelize → Prisma
1. 安装 Prisma
2. 内省现有数据库: prisma db pull
3. 生成客户端: prisma generate
4. 逐步替换查询代码
5. 删除 Sequelize
```

### 包管理器迁移
```bash
# npm → pnpm
cp package-lock.json package-lock.json.bak
mv node_modules node_modules.bak.pnpm 2>/dev/null || true
pnpm import  # 从 package-lock.json 生成
pnpm install
# 验证通过后可删除旧 lock 备份
# rm -f package-lock.json.bak package-lock.json

# npm → yarn
cp package-lock.json package-lock.json.bak
mv node_modules node_modules.bak.yarn 2>/dev/null || true
yarn install
# 验证通过后再移除旧 lock
# rm -f package-lock.json.bak package-lock.json
```

## 输出格式

```markdown
## 迁移指南

### 概述
- **迁移类型**: [框架升级/数据库迁移/...]
- **当前版本**: X.X.X
- **目标版本**: Y.Y.Y
- **风险等级**: 低/中/高

### 破坏性变更
1. [变更描述]
   - 影响范围
   - 修复方法

### 迁移步骤
1. [步骤1]
2. [步骤2]
...

### 代码修改
```diff
- 旧代码
+ 新代码
```

### 测试清单
- [ ] 单元测试
- [ ] 集成测试
- [ ] E2E 测试

### 回滚方案
[如何回滚到之前版本]
```
