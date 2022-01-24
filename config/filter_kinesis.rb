def filter(event)
    matching_count_rules = []

    # Standalone WAF rule
    non_terminating_matching_rules = event.get('[nonTerminatingMatchingRules]')
    if non_terminating_matching_rules
      non_terminating_matching_rules.each { |rule|
        matching_count_rules.push(rule['ruleId'])
      }
    end

    rule_group_list = event.get('[ruleGroupList]')
    if rule_group_list
      rule_group_list.each { |rule|
        non_terminating_matching_rules = rule['nonTerminatingMatchingRules']
        rule_group_id = rule['ruleGroupId']
        match = rule_group_id.match(/rulegroup\/(.+?)\//)
        if match
          rule_group_id = match[1]
        end

        # Rules in a Rule Group

        if non_terminating_matching_rules
          non_terminating_matching_rules.each { |rule|
            if rule['action'] == 'COUNT'
              matching_count_rules.push(rule_group_id + '.' + rule['ruleId'])
            end
          }
        end

        # Excluded Managed WAF Rules

        excludedRules = rule['excludedRules']
        if excludedRules
          excludedRules.each { |excludedRule|
            if excludedRule['exclusionType'] == 'EXCLUDED_AS_COUNT'
              matching_count_rules.push(rule_group_id + '.' + excludedRule['ruleId'])
            end
          }
        end
      }
    end

    if matching_count_rules.length() > 0
      event.set('matchingCountRules', matching_count_rules)
    end
    return [event]

  end

  test "when there are standalone rules matched in COUNT mode" do
    in_event { {
      "timestamp" => 1639580407632,
      "nonTerminatingMatchingRules"=> [
          {
              "ruleId" => "FromGBRule",
              "action" => "COUNT",
              "ruleMatchDetails" => []
          },
          {
            "ruleId" => "JonnyRules",
            "action" => "COUNT",
            "ruleMatchDetails" => []
        }
      ],
      "httpRequest"=> {
          "requestId"=> "uuCC76pG7KLiBMUki4xtaksJ8kus4WCRyzuL7TwHx1pnp2EzG53uSQ=="
      }
    } }

    expect("That the record is returned") do |events|
      events.size == 1
    end

    expect("That the requestID is returned unchanged") do |events|
      events[0].get("httpRequest")["requestId"] == "uuCC76pG7KLiBMUki4xtaksJ8kus4WCRyzuL7TwHx1pnp2EzG53uSQ=="
    end

    expect("That the matchingCountRules field is populated with matched standalone rulenames") do |events|
      events[0].get("matchingCountRules") == ["FromGBRule", "JonnyRules"]
    end

  end

  test "when there are rules in a rulegroup matched in COUNT mode" do
    in_event { {
      "timestamp": 1639657295700,
      "ruleGroupList": [
          {
              "ruleGroupId": "arn:aws:wafv2:us-east-1:150648916438:global/rulegroup/INFRA-7170-RULE-GROUP/3e7d202e-9bda-49be-890c-e767ae840a9c",
              "terminatingRule": nil,
              "nonTerminatingMatchingRules": [
                  {
                      "ruleId": "FromGB",
                      "action": "COUNT",
                      "ruleMatchDetails": []
                  },
                  {
                      "ruleId": "JonnyRule",
                      "action": "COUNT",
                      "ruleMatchDetails": []
                  }
              ]
          },
          {
              "ruleGroupId": "arn:aws:wafv2:us-east-1:150648916438:global/rulegroup/DansRuleGroup/3e7d202e-9bda-49be-890c-eejfnwergdef",
              "terminatingRule": nil,
              "nonTerminatingMatchingRules": [
                  {
                      "ruleId": "DansRule",
                      "action": "COUNT",
                      "ruleMatchDetails": []
                  }
              ]
          }
      ],
      "httpRequest": {
          "requestId": "Yb2HR1G9sBm_aZhIqzejA1pFuoFNjU-DUrw-UYRlWmaY9PYTXHFDjQ=="
      }
  } }

    expect("That the record is returned") do |events|
      events.size == 1
    end

    expect("That the requestID is returned unchanged") do |events|
      events[0].get("httpRequest")["requestId"] == "Yb2HR1G9sBm_aZhIqzejA1pFuoFNjU-DUrw-UYRlWmaY9PYTXHFDjQ=="
    end

    expect("That the matchingCountRules field is populated with <RuleGroupName>.<Rulename>") do |events|
      events[0].get("matchingCountRules") == ["INFRA-7170-RULE-GROUP.FromGB", "INFRA-7170-RULE-GROUP.JonnyRule", "DansRuleGroup.DansRule"]
    end

  end

  test "when there are excluded rules in an AWS managed rulegroup excluded as COUNT" do
    in_event { {
      "timestamp": 1639657295700,
      "ruleGroupList": [
        {
          "ruleGroupId": "AWS#AWSManagedRulesCommonRuleSet",
          "terminatingRule": nil,
          "excludedRules": [
            {
              "exclusionType": "EXCLUDED_AS_COUNT",
              "ruleId": "NoUserAgent_HEADER"
            },
            {
              "exclusionType": "EXCLUDED_AS_COUNT",
              "ruleId": "SizeRestrictions_BODY"
            }
          ]
        },
        {
            "ruleGroupId": "AWS#AWSManagedRulesAmazonIpReputationList",
            "terminatingRule": nil,
            "nonTerminatingMatchingRules": [],
            "excludedRules": nil
        },
        {
          "ruleGroupId": "AWS#AWSManagedRulesAdminProtectionRuleSet",
          "terminatingRule": nil,
          "nonTerminatingMatchingRules": [],
          "excludedRules": [
            {
              "exclusionType": "EXCLUDED_AS_COUNT",
              "ruleId": "EC2MetaDataSSRF_BODY"
            }
          ]
        }
      ],
      "httpRequest": {
        "requestId": "Yb2HR1G9sBm_aZhIqzejA1pFuoFNjU-DUrw-UYRlWmaY9PYTXHFDjQ=="
      }
    } }

    expect("That the record is returned") do |events|
      events.size == 1
    end

    expect("That the requestID is returned unchanged") do |events|
      events[0].get("httpRequest")["requestId"] == "Yb2HR1G9sBm_aZhIqzejA1pFuoFNjU-DUrw-UYRlWmaY9PYTXHFDjQ=="
    end

    expect("That the matchingCountRules field is populated with <RuleGroupName>.<RuleName>") do |events|
      events[0].get("matchingCountRules") == ["AWS#AWSManagedRulesCommonRuleSet.NoUserAgent_HEADER", "AWS#AWSManagedRulesCommonRuleSet.SizeRestrictions_BODY", "AWS#AWSManagedRulesAdminProtectionRuleSet.EC2MetaDataSSRF_BODY"]
    end

  end

  test "when all three methods of count matching are triggered in a single request" do
    in_event { {
      "timestamp": 1639657295700,
      "ruleGroupList": [
          {
              "ruleGroupId": "arn:aws:wafv2:us-east-1:150648916438:global/rulegroup/INFRA-7170-RULE-GROUP/3e7d202e-9bda-49be-890c-e767ae840a9c",
              "terminatingRule": nil,
              "nonTerminatingMatchingRules": [
                  {
                      "ruleId": "FromGB",
                      "action": "COUNT",
                      "ruleMatchDetails": []
                  }
              ],
              "excludedRules": nil
          },
          {
              "ruleGroupId": "AWS#AWSManagedRulesAdminProtectionRuleSet",
              "terminatingRule": nil,
              "nonTerminatingMatchingRules": [],
              "excludedRules": [
                  {
                      "exclusionType": "EXCLUDED_AS_COUNT",
                      "ruleId": "HostingProviderIPList"
                  }
              ]
          }
      ],
      "nonTerminatingMatchingRules": [
          {
              "ruleId": "FromGBRule",
              "action": "COUNT",
              "ruleMatchDetails": []
          }
      ],
      "httpRequest": {
          "requestId": "Yb2HR1G9sBm_aZhIijrgbrgbrehigbruiegbreibgXHFDjQ=="
      }
  } }

    expect("That the record is returned") do |events|
      events.size == 1
    end

    expect("That the requestID is returned unchanged") do |events|
      events[0].get("httpRequest")["requestId"] == "Yb2HR1G9sBm_aZhIijrgbrgbrehigbruiegbreibgXHFDjQ=="
    end

    expect("That the matchingCountRules field is populated") do |events|
      events[0].get("matchingCountRules") == ["FromGBRule", "INFRA-7170-RULE-GROUP.FromGB", "AWS#AWSManagedRulesAdminProtectionRuleSet.HostingProviderIPList"]
    end

  end
