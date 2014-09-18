
```myco
Myco < Ruby, QML, Ioke {
  primary author: "Joe Eli McIlvain"
  
  latest gem version: 0.1.0
  development status: [:alpha, :experimental]
  
  dependency "Rubinius VM": git(:master)
  
  development dependency 'bundler':  1.6
  development dependency 'rake':    10.3
  development dependency 'rspec':    3.0
  development dependency 'fivemat':  1.3
  
  [features]
  
  "innovative declarative syntax layer around a familiar Ruby-like layer"
  "ease of expression of intent" : "consistent but powerful rules"
  todo "runtime parsing rule intercession"
  todo "nested blocks parsed by user parsers"
  
  "patterns for a responsibly localized import system": ImportSystemMethods {
    import 'some/library'
    import as(:SomeLibrary) 'some/library'
    private import 'some/library'
    export as(:MyGlobalLibrary) 'my/library'
    arbitrary user_defined import_mechanism 'special/library'
  }
  
  "fluid integration with the host Ruby runtime": {
    ruby_require('some_ruby_gem')
    obj = SomeRubyGem::Object.new(1, 2, *rest, foo:8, bar:9)
    
    RubyEval """
      Myco::SomeObject.new(foo:8, bar:9)
    """
  }
  
  rich support_for(:decorators) in: user_space
  
  [decorators]
  
  support_for: Decorator {
    apply: |meme|
      arguments.each |feature| { meme.supported_features.push(feature) }
  }
  
  rich: Decorator {
    [transforms]
    richness: true
    memoize: true
  }
  
  [contributing]
  
  Github < RepositoryHost {
    URL: "https://github.com/jemc/myco"
    IssueTracker: URL + "/issues"
  }
  
  contributing_process: |user, problem| {
    issue = user.file_bug_report(problem, on: Github::IssueTracker)
    
    if(user.can_implement?) {
      pr = PullRequest {
        name: "Fix for issue #"issue.number" - "issue.description"."
        branch: snake_case(issue.name)
        user: user
        
        include fix: for(problem)
        include tests: for(fix)
        
        user.file_pull_request(pr, on: Github::IssueTracker)
      }
    }
  }
}
```
