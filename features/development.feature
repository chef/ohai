Feature: Development processes of newgem itself (rake tasks)

  As a Newgem maintainer or contributor
  I want rake tasks to maintain and release the gem
  So that I can spend time on the tests and code, and not excessive time on maintenance processes
    
  Scenario: Generate RubyGem
    Given this project is active project folder
    And 'pkg' folder is deleted
    When task 'rake gem' is invoked
    Then folder 'pkg' is created
    And file with name matching 'pkg/*.gem' is created else you should run "rake manifest" to fix this
    And gem spec key 'rdoc_options' contains /--mainREADME.rdoc/
