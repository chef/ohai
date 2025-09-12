# GitHub Copilot Instructions for Ohai

## Repository Overview

Ohai is a system information detection tool used by Chef Infra. It profiles your operating system and emits JSON data about system attributes. This repository is an **Active** project under the Chef Infra umbrella.

### Repository Structure

```
ohai/
├── .buildkite/                # BuildKite CI configuration
├── .expeditor/                 # Expeditor build system configs
│   ├── config.yml             # Main expeditor configuration
│   ├── buildkite/             # BuildKite pipeline definitions
│   └── *.sh                   # Build and update scripts
├── .github/                   # GitHub configurations
│   ├── CODEOWNERS             # Code ownership definitions
│   ├── workflows/             # GitHub Actions workflows
│   ├── ISSUE_TEMPLATE/        # Issue templates
│   └── dependabot.yml         # Dependabot configuration
├── bin/ohai                   # Main executable
├── lib/                       # Main library code
│   ├── ohai.rb               # Main entry point
│   └── ohai/                 # Core modules
│       ├── application.rb     # CLI application logic
│       ├── config.rb          # Configuration management
│       ├── dsl.rb            # Domain Specific Language
│       ├── loader.rb         # Plugin loading system
│       ├── runner.rb         # Plugin execution engine
│       ├── system.rb         # Main system interface
│       ├── common/           # Common utilities
│       ├── dsl/              # DSL components
│       ├── mixin/            # Mixins for plugins
│       ├── plugins/          # System detection plugins
│       └── util/             # Utility modules
├── spec/                      # Test suite
│   ├── unit/                 # Unit tests
│   ├── functional/           # Functional tests
│   ├── support/              # Test helpers
│   └── data/                 # Test data and fixtures
├── habitat/                   # Habitat packaging
├── tasks/                     # Rake tasks
├── vendor/                    # Vendored dependencies
├── Rakefile                   # Build tasks
├── ohai.gemspec              # Gem specification
├── Gemfile                   # Ruby dependencies
├── README.md                 # Project documentation
├── CONTRIBUTING.md           # Contribution guidelines
├── CHANGELOG.md              # Version history
└── LICENSE                   # Apache 2.0 license
```

## Workflow for Task Implementation

### 1. Task Analysis and Setup
When provided with a Jira ID, follow this workflow:

1. **Fetch Jira Issue Details**
   ```
   Use the atlassian-mcp-server to fetch issue details
   Read and understand the story requirements
   Identify affected components and scope
   ```

2. **Branch Creation**
   ```bash
   # Create feature branch using Jira ID
   git checkout -b JIRA-ID
   ```

3. **Prompt for Continuation**
   - Provide summary of understanding
   - Ask: "Ready to proceed with implementation? What would you like to implement first?"
   - List remaining steps in the workflow

### 2. Implementation Phase

1. **Code Implementation**
   - Implement the required functionality
   - Follow Ruby style guidelines (uses Cookstyle)
   - Ensure code follows existing patterns in the repository
   - Add appropriate error handling and logging

2. **Unit Test Creation**
   - Create comprehensive unit tests using RSpec
   - Place tests in `spec/unit/` following existing structure
   - Ensure test coverage > 80%
   - Use existing test helpers in `spec/support/`
   - Follow existing test patterns (see `spec/spec_helper.rb`)

3. **Prompt for Continuation**
   - Summary: "Implementation completed with unit tests"
   - Next step: "Ready to run tests and validate coverage?"
   - Remaining: "Style checks, functional tests, PR creation"

### 3. Validation Phase

1. **Run Test Suite**
   ```bash
   bundle exec rake spec          # Run all tests
   bundle exec rake style         # Check code style
   bundle exec rake style:auto_correct  # Auto-fix style issues
   ```

2. **Coverage Validation**
   - Ensure test coverage remains > 80%
   - Add additional tests if coverage drops

3. **Prompt for Continuation**
   - Summary: "Tests passing with coverage > 80%"
   - Next step: "Ready to create pull request?"
   - Remaining: "PR creation and submission"

### 4. Pull Request Creation

1. **Commit Changes with DCO Compliance**
   ```bash
   # All commits must include DCO sign-off
   git commit -m "feat: implement JIRA-ID feature

   Detailed description of changes made

   Signed-off-by: Your Name <your.email@example.com>" --signoff
   ```

2. **Push Branch and Create PR**
   ```bash
   # Push the branch
   git push origin JIRA-ID

   # Create PR using GitHub CLI
   gh pr create \
     --title "feat: implement JIRA-ID - Brief Description" \
     --body "$(cat <<EOF
   <h2>Summary</h2>
   <p>Brief description of changes implemented</p>

   <h2>Changes Made</h2>
   <ul>
     <li>Change 1</li>
     <li>Change 2</li>
     <li>Change 3</li>
   </ul>

   <h2>Testing</h2>
   <ul>
     <li>Unit tests added with coverage > 80%</li>
     <li>All existing tests pass</li>
     <li>Style checks pass</li>
   </ul>

   <h2>Related Issue</h2>
   <p>Closes JIRA-ID</p>
   EOF
   )" \
     --assignee @me
   ```

3. **Final Prompt**
   - Summary: "Pull request created successfully"
   - Next step: "PR is ready for review"
   - Status: "Task completed - awaiting team review"

## Repository-Specific Guidelines

### DCO Compliance Requirements
- **ALL commits must be signed off** using `git commit --signoff`
- Include `Signed-off-by: Your Name <your.email@example.com>` in commit messages
- This certifies you have the right to submit the code under the project's license
- DCO compliance is enforced by the project and required for all contributions

### Expeditor Build System Integration
- Expeditor handles automated releases and version bumping
- Available labels for version control:
  - `Expeditor: Bump Version Minor` - Bumps minor version
  - `Expeditor: Bump Version Major` - Bumps major version
  - `Expeditor: Skip Version Bump` - Prevents version bump
  - `Expeditor: Skip Changelog` - Skips changelog update
  - `Expeditor: Skip Habitat` - Skips Habitat package build
  - `Expeditor: Skip All` - Skips all Expeditor actions

### GitHub Labels and PR Workflow
- Use semantic commit prefixes: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`
- PRs are automatically tested via GitHub Actions and BuildKite
- Code must pass all CI checks before merging
- Expeditor will automatically delete merged branches
- Release branches: `main` (19.x), `18-stable`, `17-stable`, `16-stable`

### Testing Requirements
- **Minimum 80% test coverage required**
- Use RSpec for all tests
- Unit tests in `spec/unit/`
- Functional tests in `spec/functional/`
- Integration tests use `spec/support/integration_helper.rb`
- Platform-specific tests use `spec/support/platform_helpers.rb`

### Code Quality Standards
- Follow Cookstyle/RuboCop rules defined in `.rubocop.yml`
- Use `bundle exec rake style:auto_correct` to fix style issues
- Required Ruby version: >= 3.1
- Follow existing code patterns and conventions

### Plugin Development
- Plugins are located in `lib/ohai/plugins/`
- Use Ohai DSL for plugin development
- Plugins should provide system information in JSON format
- Test plugins thoroughly across supported platforms

### MCP Server Integration
When working with Jira issues:
- Use the `atlassian-mcp-server` MCP server for Jira integration
- Fetch complete issue details including description, acceptance criteria
- Reference Jira ID in commit messages and PR titles
- Ensure implementation matches story requirements

## Prompt-Based Workflow

### After Each Major Step
1. **Provide Summary**: Clear description of what was completed
2. **Next Step Announcement**: What will be done next
3. **Remaining Steps**: List of what's left to complete
4. **Continuation Prompt**: "Ready to proceed with [next step]? (y/n)"

### Example Workflow Prompts
```
✅ Step 1 Complete: Jira issue CHEF-1234 analyzed
📋 Summary: Feature requires adding network interface detection for Docker containers
🔄 Next Step: Implement network plugin enhancement
📝 Remaining: Unit tests, integration tests, style checks, PR creation
❓ Ready to proceed with implementation? (y/n)
```

## Important Notes

### Files Not to Modify
- `.expeditor/config.yml` - Managed by Chef Infrastructure team
- `.github/CODEOWNERS` - Managed by maintainers
- Version files - Managed by Expeditor
- License files - Apache 2.0 license is fixed

### Local Development
- Use `bundle install` to install dependencies
- Run `bundle exec rake console` for interactive debugging
- All development work is performed in local repository
- Use standard Git workflow for branch management

### GitHub CLI Authentication
- Ensure GitHub CLI is properly authenticated
- Use standard `gh auth login` process
- Authentication is handled independently of shell profiles

### Communication Style
- Be concise and clear in commit messages
- Use HTML formatting in PR descriptions for better readability
- Reference related issues and PRs appropriately
- Maintain professional tone in all communications

This comprehensive guide ensures consistent, high-quality contributions to the Ohai project while following all repository conventions and requirements.