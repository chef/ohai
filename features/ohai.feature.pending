Feature: Collects data about a system
  In order to understand the state of my system	
  As a Systems Administrator
  I want to have a program that detects information for me

	Scenario: Collect data about the system via a single plugin
	  Given a plugin called 'platform'
	  When I run ohai
	  Then I should have a 'platform' of 'kitties'
	
	Scenario: Collect data about the system via a directory of plugins
		Given a plugin directory at './plugins'
		When I run ohai
		Then I should have a 'platform' of 'kitties'
		 And I should have a 'foghorn' of 'leghorn'
		
	Scenario: Collect data about the system via an external script
		Given a plugin called 'perl'
		When I run ohai
		Then I should have a 'perl_major_version' of '5'
		