# Architecture: Task Management API

## Status: LOCKED
> This document was produced by FORGE /architect.

## Overview
A REST API for managing tasks with user authentication.

## Data Flow
1. Client sends HTTP request → Express router
2. Router dispatches to controller → validates input
3. Controller calls service layer → business logic
4. Service calls repository → database operations
5. Response flows back through the stack

## API Contracts

### createTask
- Input: `{ title: string, description?: string, assigneeId: string }`
- Output: `{ id: string, title: string, status: "pending", createdAt: string }`
- Errors: `400 Bad Request` (missing title), `404 Not Found` (invalid assigneeId)

### getTaskById
- Input: `id: string` (path parameter)
- Output: `{ id: string, title: string, description: string, status: string, assigneeId: string }`
- Errors: `404 Not Found`

### updateTaskStatus
- Input: `{ id: string, status: "pending" | "in_progress" | "done" }`
- Output: `{ id: string, status: string, updatedAt: string }`
- Errors: `400 Bad Request` (invalid transition), `404 Not Found`

## Component Boundaries

| Component | Responsibility | Creates/Modifies |
|-----------|---------------|-----------------|
| TaskController | HTTP handling, input validation | src/controllers/task.ts |
| TaskService | Business logic, status transitions | src/services/task.ts |
| TaskRepository | Database queries | src/repositories/task.ts |
| TaskModel | Type definitions | src/models/task.ts |

## Edge Cases

1. Creating a task with an empty title → return 400
2. Status transition from "done" back to "pending" → reject with 400
3. Concurrent updates to same task → last-write-wins with optimistic locking
4. Assignee deleted while tasks exist → keep task, null out assigneeId
5. Very long title (>500 chars) → truncate to 500

## Test Strategy

### Unit Tests
- TaskService: test each status transition (valid and invalid)
- TaskController: test input validation for each endpoint

### Integration Tests
- Full request cycle: create → get → update → verify state
- Error responses match the documented error codes

### E2E Tests
- Happy path: create task, assign, complete
- Error path: invalid inputs return correct HTTP codes

## Dependencies
- express: ^4.18.0
- pg: ^8.11.0 (PostgreSQL driver)
- zod: ^3.22.0 (input validation)

## Security Considerations
- Validate all input with zod schemas at controller boundary
- Use parameterized queries in repository layer (prevent SQL injection)
- Rate limit task creation to 100/minute per user

## Deferred Items
- Task comments and attachments (Phase 2)
- Real-time updates via WebSocket (Phase 3)

## Code Example

Here is a code block that should NOT be treated as a header:

```typescript
// ## This Is Not A Header
// ### Neither is this
class TaskService {
  ## also not a header inside code
  async createTask(input: CreateTaskInput): Promise<Task> {
    return this.repository.create(input);
  }
}
```

## Notes
This architecture follows the repository pattern for data access.
