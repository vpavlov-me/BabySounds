# Dangerfile for BabySounds iOS App
# Comprehensive PR analysis for Kids Category compliance

# Import Danger plugins
require 'danger/plugins/swiftlint'

# Configuration
MAX_PR_SIZE = 800
MAX_FIXME_COUNT = 5
REQUIRED_ACCESSIBILITY_COVERAGE = 50

# Helper methods
def files_matching(*patterns)
  patterns.map { |pattern| Dir.glob(pattern) }.flatten.uniq
end

def swift_files
  files_matching("**/*.swift").reject { |f| f.include?("Test") }
end

def changed_swift_files
  git.modified_files.select { |f| f.end_with?(".swift") }
end

def ui_files
  changed_swift_files.select { |f| f.include?("View") || f.include?("UI") }
end

# PR Size Analysis
def analyze_pr_size
  total_lines = git.lines_of_code
  
  if total_lines > MAX_PR_SIZE
    warn("📏 Large PR detected (#{total_lines} lines). Consider breaking into smaller PRs for easier review.")
    
    # Suggest splitting strategies
    message("💡 **Large PR Tips:**\n" +
            "- Split UI changes from business logic\n" +
            "- Separate refactoring from new features\n" +
            "- Create multiple smaller PRs with clear scope")
  elsif total_lines > MAX_PR_SIZE / 2
    message("📊 Medium-sized PR (#{total_lines} lines). Ensure good test coverage and documentation.")
  else
    message("✅ Good PR size (#{total_lines} lines) - easy to review!")
  end
end

# Kids Category Compliance Check
def check_kids_compliance
  compliance_issues = []
  
  changed_swift_files.each do |file|
    file_content = File.read(file)
    
    # Check for data collection
    if file_content.match?(/(Analytics|Tracking|UserDefaults.*email|UserDefaults.*name|UserDefaults.*location)/i)
      compliance_issues << "⚠️ Potential data collection in `#{file}` - ensure COPPA compliance"
    end
    
    # Check for external URLs without safety wrapper
    if file_content.match?(/https?:\/\//) && !file_content.include?("SafeLinkWrapper")
      compliance_issues << "🔗 External URLs in `#{file}` should use SafeLinkWrapper"
    end
    
    # Check for inappropriate content
    if file_content.match?(/(violence|adult|mature|gambling|weapon)/i)
      compliance_issues << "🚨 Potentially inappropriate content in `#{file}` for Kids Category"
    end
    
    # Check for advertising/monetization
    if file_content.match?/(advertisement|ads|monetization|purchase.*child)/i)
      compliance_issues << "💰 Potential advertising/monetization concerns in `#{file}`"
    end
  end
  
  if compliance_issues.any?
    warn("## 👶 Kids Category Compliance Issues\n\n" + compliance_issues.join("\n"))
    message("📋 **Kids Category Requirements:**\n" +
            "- No data collection from children under 13\n" +
            "- Parental gate for external links and purchases\n" +
            "- Age-appropriate content only\n" +
            "- COPPA compliance mandatory")
  else
    message("✅ No obvious Kids Category compliance issues found")
  end
end

# Accessibility Compliance Check
def check_accessibility
  accessibility_score = 0
  total_ui_elements = 0
  issues = []
  
  ui_files.each do |file|
    file_content = File.read(file)
    
    # Count UI elements
    ui_elements = file_content.scan(/(Button|Image|Toggle|Picker|TextField|AsyncImage)/).length
    total_ui_elements += ui_elements
    
    # Count accessibility implementations
    accessibility_implementations = file_content.scan(/(accessibilityLabel|accessibilityHint|accessibilityIdentifier)/).length
    accessibility_score += accessibility_implementations
    
    if ui_elements > 0 && accessibility_implementations == 0
      issues << "♿ `#{file}` has UI elements but no accessibility attributes"
    end
  end
  
  if total_ui_elements > 0
    coverage_percentage = (accessibility_score * 100 / total_ui_elements).round
    
    if coverage_percentage < REQUIRED_ACCESSIBILITY_COVERAGE
      warn("♿ Low accessibility coverage: #{coverage_percentage}% (#{accessibility_score}/#{total_ui_elements})")
      message("🎯 **Accessibility Improvements Needed:**\n" +
              "- Add `.accessibilityLabel()` for all interactive elements\n" +
              "- Include `.accessibilityHint()` for complex actions\n" +
              "- Use `.accessibilityIdentifier()` for UI testing")
    else
      message("✅ Good accessibility coverage: #{coverage_percentage}%")
    end
    
    if issues.any?
      warn("## ♿ Accessibility Issues\n\n" + issues.join("\n"))
    end
  end
end

# TODO/FIXME Analysis
def analyze_todos_fixmes
  todo_count = 0
  fixme_count = 0
  critical_files = []
  
  changed_swift_files.each do |file|
    file_content = File.read(file)
    
    file_todos = file_content.scan(/TODO/i).length
    file_fixmes = file_content.scan(/FIXME/i).length
    
    todo_count += file_todos
    fixme_count += file_fixmes
    
    if file_fixmes > 0
      critical_files << "`#{file}` (#{file_fixmes} FIXMEs)"
    end
  end
  
  if fixme_count > MAX_FIXME_COUNT
    fail("🚨 Too many FIXME comments (#{fixme_count}). Please address critical issues before merging.")
  elsif fixme_count > 0
    warn("🔧 FIXME comments found in: #{critical_files.join(', ')}")
  end
  
  if todo_count > 0
    message("📝 TODO comments: #{todo_count} (consider addressing before release)")
  end
end

# Performance Check
def check_performance_issues
  performance_issues = []
  
  changed_swift_files.each do |file|
    file_content = File.read(file)
    
    # Check for synchronous main queue calls
    if file_content.match?(/DispatchQueue\.main\.sync/)
      performance_issues << "⚡ Synchronous main queue call in `#{file}` may block UI"
    end
    
    # Check for nested loops (basic pattern)
    if file_content.match?(/for.*in.*\{[\s\S]*for.*in/)
      performance_issues << "🔄 Nested loops in `#{file}` may impact performance"
    end
    
    # Check for excessive force unwrapping
    force_unwrap_count = file_content.scan(/!(?!\=)/).length
    if force_unwrap_count > 10
      performance_issues << "⚠️ Many force unwraps in `#{file}` (#{force_unwrap_count}) - consider safe unwrapping"
    end
  end
  
  if performance_issues.any?
    warn("## ⚡ Performance Concerns\n\n" + performance_issues.join("\n"))
  end
end

# Localization Check
def check_localization
  hardcoded_strings = []
  
  changed_swift_files.each do |file|
    file_content = File.read(file)
    
    # Look for hardcoded English strings
    file_content.scan(/Text\("([^"]+)"\)/) do |match|
      string_content = match[0]
      if string_content.match?(/[A-Za-z]/) && !file_content.include?("LocalizedStringKey")
        hardcoded_strings << "`#{file}`: \"#{string_content}\""
      end
    end
  end
  
  if hardcoded_strings.any?
    warn("🌍 Potential hardcoded strings found:\n" + hardcoded_strings.join("\n"))
    message("💡 Consider using `LocalizedStringKey` or `NSLocalizedString` for internationalization")
  end
end

# SwiftLint Integration
def run_swiftlint
  if File.exist?(".swiftlint.yml")
    swiftlint.config_file = ".swiftlint.yml"
    swiftlint.lint_files inline_mode: true
    
    # Additional analysis
    if swiftlint.issues.any?
      message("🔍 SwiftLint found #{swiftlint.issues.count} issues. Please review and fix.")
    else
      message("✅ SwiftLint analysis passed!")
    end
  else
    warn("No SwiftLint configuration found")
  end
end

# Changelog Check
def check_changelog
  changelog_files = ["CHANGELOG.md", "CHANGES.md", "HISTORY.md"]
  changelog_updated = changelog_files.any? { |file| git.modified_files.include?(file) }
  
  unless changelog_updated
    has_user_facing_changes = changed_swift_files.any? { |f| f.include?("View") || f.include?("Manager") }
    
    if has_user_facing_changes
      warn("📝 Consider updating CHANGELOG.md for user-facing changes")
    end
  else
    message("✅ Changelog updated")
  end
end

# Test Coverage Reminder
def check_test_coverage
  test_files = git.added_files.select { |f| f.include?("Test") }
  new_swift_files = git.added_files.select { |f| f.end_with?(".swift") && !f.include?("Test") }
  
  if new_swift_files.any? && test_files.empty?
    warn("🧪 New Swift files added but no test files. Consider adding unit tests.")
    message("💡 **Testing Guidelines:**\n" +
            "- Test business logic in managers and services\n" +
            "- Mock external dependencies\n" +
            "- Verify Kids Category compliance in tests")
  end
end

# Branch Protection
def check_branch_protection
  target_branch = github.branch_for_base
  
  if target_branch == "main" && github.branch_for_head != "develop"
    warn("🚨 Direct PR to main branch. Consider merging to develop first.")
  end
  
  if github.branch_for_head == "main"
    fail("❌ Cannot create PR from main branch")
  end
end

# Main execution
message("## 🍼 BabySounds PR Analysis")

# Basic checks
analyze_pr_size
check_branch_protection

# Code quality
run_swiftlint
analyze_todos_fixmes
check_performance_issues

# Kids App specific checks
check_kids_compliance
check_accessibility
check_localization

# Documentation and testing
check_changelog
check_test_coverage

# Final summary
if status_report[:errors].empty? && status_report[:warnings].length <= 3
  message("🎉 **Excellent PR!** Ready for review.")
  message("🔍 **Review Checklist:**\n" +
          "- [ ] Kids Category compliance verified\n" +
          "- [ ] Accessibility tested\n" +
          "- [ ] Performance impact considered\n" +
          "- [ ] Documentation updated\n" +
          "- [ ] Manual testing completed")
else
  message("📋 **Review Summary:**\n" +
          "- Errors: #{status_report[:errors].length}\n" +
          "- Warnings: #{status_report[:warnings].length}\n" +
          "- Messages: #{status_report[:messages].length}")
end

# Kids Category reminder
message("---\n" +
        "👶 **Kids Category Reminder:**\n" +
        "This app is designed for children ages 5 & under. All changes must comply with:\n" +
        "- COPPA requirements\n" +
        "- Apple's Kids Category guidelines\n" +
        "- Accessibility standards\n" +
        "- Age-appropriate content policies") 