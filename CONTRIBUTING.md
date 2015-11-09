# Contributing to Ohai

We are glad you want to contribute to Ohai!

We utilize **Github Issues** for issue tracking and contributions. You can contribute in two ways:

1. Reporting an issue or making a feature request [here](#issues).
2. Adding features or fixing bugs yourself and contributing your code to Ohai.

## Contribution Process

We have a 3 step process that utilizes **Github Issues**:

1. Sign or be added to an existing [Contributor License Agreement (CLA)](https://supermarket.chef.io/become-a-contributor).
2. Create a Github Pull Request.
3. Do [Code Review](#cr) with the **Chef Engineering Team** or **Chef Core Committers** on the pull request.

### <a name="pulls"></a> Ohai Pull Requests

Ohai is built to last. We strive to ensure high quality throughout the Ohai experience. In order to ensure
  this, we require a couple of things for all pull requests to Ohai:

1. **Tests:** To ensure high quality code and protect against future regressions, we require all the
  code in Ohai to have at least unit test coverage. See the [spec/unit](https://github.com/chef/ohai/tree/master/spec/unit)
  directory for the existing tests and use ```bundle exec rake spec``` to run them.
2. **Green Travis Run:** We use [Travis CI](https://travis-ci.org/) in order to run our tests
  continuously on all the pull requests. We require the Travis runs to succeed on every pull
  request before being merged.

In addition to this it would be nice to include the description of the problem you are solving
  with your change. You can use the [Issue Template](#issuetemplate) in the description section
  of the pull request.

### <a name="cr"></a>Code Review Process

The code review process happens via Github pull requests. See
  [this article](https://help.github.com/articles/using-pull-requests) if you're not
  familiar with Github Pull Requests.

Once you a pull request, the **Chef Engineering Team** or **Chef Core Committers** will review your code
  and respond to you with any feedback they might have. The process at this point is as follows:

1. 2 thumbs-ups are required from the **Chef Engineering Team** or **Chef Core Committers** for all merges.
2. When ready, your pull request will be tagged with label `Ready For Merge`.
3. Your patch will be merged into `master` including necessary documentation updates
  and you will be included in `CHANGELOG.md`. Our goal is to have patches merged in 2 weeks
  after they are marked to be merged.

If you would like to learn about when your code will be available in a release of Ohai, read more about
  the [Release Process](#release).

### Contributor License Agreement (CLA)
Licensing is very important to open source projects. It helps ensure the
  software continues to be available under the terms that the author desired.

Chef uses [the Apache 2.0 license](https://github.com/chef/ohai/blob/master/LICENSE)
  to strike a balance between open contribution and allowing you to use the
  software however you would like to.

The license tells you what rights you have that are provided by the copyright holder.
  It is important that the contributor fully understands what rights they are
  licensing and agrees to them. Sometimes the copyright holder isn't the contributor,
  such as when the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Chef requires an Individual CLA
  or a Corporate CLA for contributions. This agreement helps ensure you are aware of the
  terms of the license you are contributing your copyrighted works under, which helps to
  prevent the inclusion of works in the projects that the contributor does not hold the rights
  to share.

It only takes a few minutes to complete a CLA, and you retain the copyright to your contribution.

You can complete our
  [Individual CLA](https://supermarket.chef.io/icla-signatures/new) online.
  If you're contributing on behalf of your employer and they retain the copyright for your works,
  have your employer fill out our
  [Corporate CLA](https://supermarket.chef.io/ccla-signatures/new) instead.

### Chef Obvious Fix Policy

Small contributions such as fixing spelling errors, where the content is small enough
  to not be considered intellectual property, can be submitted by a contributor as a patch,
  without a CLA.

As a rule of thumb, changes are obvious fixes if they do not introduce any new functionality
  or creative thinking. As long as the change does not affect functionality, some likely
  examples include the following:

* Spelling / grammar fixes
* Typo correction, white space and formatting changes
* Comment clean up
* Bug fixes that change default return values or error codes stored in constants
* Adding logging messages or debugging output
* Changes to ‘metadata’ files like Gemfile, .gitignore, build scripts, etc.
* Moving source files from one directory or package to another

**Whenever you invoke the “obvious fix” rule, please say so in your commit message:**

```
------------------------------------------------------------------------
commit 370adb3f82d55d912b0cf9c1d1e99b132a8ed3b5
Author: danielsdeleo <dan@chef.io>
Date:   Wed Sep 18 11:44:40 2013 -0700

  Fix typo in config file docs.

  Obvious fix.

------------------------------------------------------------------------
```

## <a name="issues"></a> Ohai Issue Tracking

Ohai Issue Tracking is handled using Github Issues.

If you are familiar with Ohai and know the component that is causing you a problem or if you
  have a feature request on a specific component you can file an issue in the corresponding
  Github project. All of our Open Source Software can be found in our
  [Github organization](https://github.com/chef/).

Otherwise you can file your issue in the [Ohai project](https://github.com/chef/ohai/issues)
  and we will make sure it gets filed against the appropriate project.

In order to decrease the back and forth in issues, and to help us get to the bottom of them quickly
  we use the below issue template. You can copy/paste this template into the issue you are opening and
  edit it accordingly.

<a name="issuetemplate"></a>
```
### Version:
[Version of the project installed]

### Environment: [Details about the environment such as the Operating System, cloud provider, etc...]

### Scenario:
[What you are trying to achieve and you can't?]



### Steps to Reproduce:
[If you are filing an issue what are the things we need to do in order to repro your problem?]


### Expected Result:
[What are you expecting to happen as the consequence of above reproduction steps?]


### Actual Result:
[What actually happens after the reproduction steps?]
```

## <a name="release"></a>Ohai Release Cycles

Our primary shipping vehicle is operating system specific packages that includes
  all the requirements of Chef and Ohai. We call these [Omnibus packages](https://github.com/chef/omnibus)

We also release our software as gems to [Rubygems](https://rubygems.org/) but we strongly
  recommend using the Chef packages, since they are the only combination  of native libraries
  and gems required by Ohai that we test throughly.

Our version numbering closely follows [Semantic Versioning](http://semver.org/) standard. Our
  standard version numbers look like X.Y.Z which mean:

* X is a major release, which may not be fully compatible with prior major releases
* Y is a minor release, which adds both new features and bug fixes
* Z is a patch release, which adds just bug fixes

We frequently make `alpha` and `beta` releases with version numbers that look like
  `X.Y.Z.alpha.0` or `X.Y.Z.beta.1`. These releases are still well tested but not as
  throughly as **Minor** or **Patch** releases.

We do a `Minor` release approximately every 3 months and `Patch` releases on a when-needed
  basis for regressions, significant bugs, and security issues.

Announcements of releases are available on [Chef Blog](https://www.chef.io/blog/) at the
  time of release

## Chef Community

Ohai is made possible by a strong community of developers and system administrators in the Chef
  community. If you have any questions or if you would like to get involved in the community you
  can check out:

* [chef](https://discourse.chef.io/) mailing list
* [\#chef](https://botbot.me/freenode/chef) and [\#chef-hacking](https://botbot.me/freenode/chef-hacking) IRC channels on irc.freenode.net

Also here are some additional pointers to some awesome Chef content:

* [Chef Docs](https://docs.chef.io/)
* [Learn Chef](https://learn.chef.io/)
* [Chef Inc](https://www.chef.io/)
