resource "aws_cloudformation_stack" "network" {
  name = "networking-stack2"

#   parameters = {
#     VPCCidr = "10.0.0.0/16"
#   }

  template_body = <<STACK
---
## Example AWS WAF rule set covering generic OWASP Top 10 vulnerability
## areas with PHP backend specific misconfigurations.
##
## Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
## Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
## A copy of the License is located at http://aws.amazon.com/asl/ or in the "license" file accompanying this file.
## This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
## See the License for the specific language governing permissions and limitations under the License.
##
## Changelog:
## 2017-06-27 - Initial release
##
## Repository:
## https://github.com/awslabs/aws-waf-sample
##
## Dependencies:
## none

AWSTemplateFormatVersion: '2010-09-09'
Description: AWS WAF Basic OWASP Example Rule Set

## ::PARAMETERS::
## Template parameters to be configured by user
Parameters:
  stackPrefix:
    Type: String
    Description: The prefix to use when naming resources in this stack. Normally we would use the stack name, but since this template can be used as a resource in other stacks we want to keep the naming consistent. No symbols allowed.
    ConstraintDescription: Alphanumeric characters only, maximum 10 characters
    AllowedPattern: ^[a-zA-z0-9]+$
    MaxLength: 10
    Default: generic
  stackScope:
    Type: String
    Description: You can deploy this stack at a regional level, for regional WAF targets like Application Load Balancers, or for global targets, such as Amazon CloudFront distributions.
    AllowedValues:
      - Global
      - Regional
    Default: Regional
  ruleAction:
    Type: String
    Description: The type of action you want to iplement for the rules in this set. Valid options are COUNT or BLOCK.
    AllowedValues:
      - BLOCK
      - COUNT
    Default: BLOCK
  includesPrefix:
    Type: String
    Description: This is the URI path prefix (starting with '/') that identifies any files in your webroot that are server-side included components, and should not be invoked directly via URL. These can be headers, footers, 3rd party server side libraries or components. You can add additional prefixes later directly in the set.
    Default: /includes
  adminUrlPrefix:
    Type: String
    Description: This is the URI path prefix (starting with '/') that identifies your administrative sub-site. You can add additional prefixes later directly in the set.
    Default: /admin
  adminRemoteCidr:
    Type: String
    Description: This is the IP address allowed to access your administrative interface. Use CIDR notation. You can add additional ones later directly in the set.
    Default: 127.0.0.1/32
  maxExpectedURISize:
    Type: Number
    Description: Maximum number of bytes allowed in the URI component of the HTTP request. Generally the maximum possible value is determined by the server operating system (maps to file system paths), the web server software, or other middleware components. Choose a value that accomodates the largest URI segment you use in practice in your web application.
    Default: 512
  maxExpectedQueryStringSize:
    Type: Number
    Description: Maximum number of bytes allowed in the query string component of the HTTP request. Normally the  of query string parameters following the "?" in a URL is much larger than the URI , but still bounded by the  of the parameters your web application uses and their values.
    Default: 1024
  maxExpectedBodySize:
    Type: Number
    Description: Maximum number of bytes allowed in the body of the request. If you do not plan to allow large uploads, set it to the largest payload value that makes sense for your web application. Accepting unnecessarily large values can cause performance issues, if large payloads are used as an attack vector against your web application.
    Default: 1048576
  maxExpectedCookieSize:
    Type: Number
    Description: Maximum number of bytes allowed in the cookie header. The maximum size should be less than 4096, the size is determined by the amount of information your web application stores in cookies. If you only pass a session token via cookies, set the size to no larger than the serialized size of the session token and cookie metadata.
    Default: 4093
  csrfExpectedHeader:
    Type: String
    Description: The custom HTTP request header, where the CSRF token value is expected to be encountered
    Default: x-csrf-token
  csrfExpectedSize:
    Type: Number
    Description: The size in bytes of the CSRF token value. For example if it's a canonically formatted UUIDv4 value the expected size would be 36 bytes/ASCII characters
    Default: 36

## ::METADATA::
## CloudFormation parameter UI definitions
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: Resource Prefix
        Parameters:
          - stackPrefix
      - Label:
          default: WAF Implementation
        Parameters:
          - stackScope
          - ruleAction
      - Label:
          default: Generic HTTP Request Enforcement
        Parameters:
          - maxExpectedURISize
          - maxExpectedQueryStringSize
          - maxExpectedBodySize
          - maxExpectedCookieSize
      - Label:
          default: Administrative Interface
        Parameters:
          - adminUrlPrefix
          - adminRemoteCidr
      - Label:
          default: Cross-Site Request Forgery (CSRF)
        Parameters:
          - csrfExpectedHeader
          - csrfExpectedSize
      - Label:
          default: Application Specific
        Parameters:
          - includesPrefix
    ParameterLabels:
      stackPrefix:
        default: Resource Name Prefix
      stackScope:
        default: Apply to WAF
      ruleAction:
        default: Rule Effect
      includesPrefix:
        default: Server-side components URI prefix
      adminUrlPrefix:
        default: URI prefix
      adminRemoteCidr:
        default: Allowed IP source (CIDR)
      maxExpectedURISize:
        default: Max. size of URI
      maxExpectedQueryStringSize:
        default: Max. size of QUERY STRING
      maxExpectedBodySize:
        default: Max. size of BODY
      maxExpectedCookieSize:
        default: Max. size of COOKIE
      csrfExpectedHeader:
        default: HTTP Request Header
      csrfExpectedSize:
        default: Token Size

## ::CONDITIONS::
## Determines if we're generating regional or global resources
Conditions:
  isRegional: !Equals [ !Ref stackScope, Regional ]
  isGlobal: !Equals [ !Ref stackScope, Global ]

## ::RESOURCES::
## Resources used in this solution
Resources:

## 1.
## OWASP Top 10 A1
## Mitigate SQL Injection Attacks
## Matches attempted SQLi patterns in the URI, QUERY_STRING, BODY, COOKIES
  wafrSQLiSet:
    Type: AWS::WAFRegional::SqlInjectionMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'detect-sqli']]
      SqlInjectionMatchTuples:
        - FieldToMatch:
            Type: URI
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: HTML_ENTITY_DECODE
  wafgSQLiSet:
    Type: AWS::WAF::SqlInjectionMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'detect-sqli']]
      SqlInjectionMatchTuples:
        - FieldToMatch:
            Type: URI
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: HTML_ENTITY_DECODE
  wafrSQLiRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'mitigatesqli']]
      Name: !Join ['-', [!Ref stackPrefix, 'mitigate-sqli']]
      Predicates:
        - Type: SqlInjectionMatch
          Negated: false
          DataId: !Ref wafrSQLiSet
  wafgSQLiRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'mitigatesqli']]
      Name: !Join ['-', [!Ref stackPrefix, 'mitigate-sqli']]
      Predicates:
        - Type: SqlInjectionMatch
          Negated: false
          DataId: !Ref wafgSQLiSet

## 2.
## OWASP Top 10 A2
## Blacklist bad/hijacked JWT tokens or session IDs
## Matches the specific values in the cookie or Authorization header
## for JWT it is sufficient to check the signature
  wafrAuthTokenStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-auth-tokens']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          PositionalConstraint: CONTAINS
          TargetString: example-session-id
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: authorization
          PositionalConstraint: ENDS_WITH
          TargetString: .TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
          TextTransformation: URL_DECODE
  wafgAuthTokenStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-auth-tokens']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          PositionalConstraint: CONTAINS
          TargetString: example-session-id
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: authorization
          PositionalConstraint: ENDS_WITH
          TargetString: .TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
          TextTransformation: URL_DECODE
  wafrAuthTokenRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'badauthtokens']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-bad-auth-tokens']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrAuthTokenStringSet
  wafgAuthTokenRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'badauthtokens']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-bad-auth-tokens']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgAuthTokenStringSet


## 3.
## OWASP Top 10 A3
## Mitigate Cross Site Scripting Attacks
## Matches attempted XSS patterns in the URI, QUERY_STRING, BODY, COOKIES
  wafrXSSSet:
    Type: AWS::WAFRegional::XssMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'detect-xss']]
      XssMatchTuples:
        - FieldToMatch:
            Type: URI
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: HTML_ENTITY_DECODE
  wafgXSSSet:
    Type: AWS::WAF::XssMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'detect-xss']]
      XssMatchTuples:
        - FieldToMatch:
            Type: URI
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: BODY
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: HTML_ENTITY_DECODE
  wafrXSSRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'mitigatexss']]
      Name: !Join ['-', [!Ref stackPrefix, 'mitigate-xss']]
      Predicates:
        - Type: XssMatch
          Negated: false
          DataId: !Ref wafrXSSSet
  wafgXSSRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'mitigatexss']]
      Name: !Join ['-', [!Ref stackPrefix, 'mitigate-xss']]
      Predicates:
        - Type: XssMatch
          Negated: false
          DataId: !Ref wafgXSSSet

## 4.
## OWASP Top 10 A4
## Path Traversal, LFI, RFI
## Matches request patterns designed to traverse filesystem paths, and include
## local or remote files
  wafrPathsStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-rfi-lfi-traversal']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: HTML_ENTITY_DECODE
  wafgPathsStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-rfi-lfi-traversal']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ../
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: HTML_ENTITY_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: ://
          TextTransformation: HTML_ENTITY_DECODE
  wafrPathsRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectrfilfi']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-rfi-lfi-traversal']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrPathsStringSet
  wafgPathsRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectrfilfi']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-rfi-lfi-traversal']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgPathsStringSet

## 5.
## OWASP Top 10 A4
## Privileged Module Access Restrictions
## Restrict access to the admin interface to known source IPs only
## Matches the URI prefix, when the remote IP isn't in the whitelist
  wafrAdminUrlStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-admin-url']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: STARTS_WITH
          TargetString: !Ref adminUrlPrefix
          TextTransformation: URL_DECODE
  wafgAdminUrlStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-admin-url']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: STARTS_WITH
          TargetString: !Ref adminUrlPrefix
          TextTransformation: URL_DECODE
  wafrAdminRemoteAddrIpSet:
    Type: AWS::WAFRegional::IPSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-admin-remote-ip']]
      IPSetDescriptors:
        - Type: IPV4
          Value: !Ref adminRemoteCidr
  wafgAdminRemoteAddrIpSet:
    Type: AWS::WAF::IPSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-admin-remote-ip']]
      IPSetDescriptors:
        - Type: IPV4
          Value: !Ref adminRemoteCidr
  wafrAdminAccessRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectadminaccess']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-admin-access']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrAdminUrlStringSet
        - Type: IPMatch
          Negated: true
          DataId: !Ref wafrAdminRemoteAddrIpSet
  wafgAdminAccessRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectadminaccess']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-admin-access']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgAdminUrlStringSet
        - Type: IPMatch
          Negated: true
          DataId: !Ref wafgAdminRemoteAddrIpSet

## 6.
## OWASP Top 10 A5
## PHP Specific Security Misconfigurations
## Matches request patterns designed to exploit insecure PHP/CGI configuration
  wafrPHPInsecureQSStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-php-insecure-var-refs']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: _SERVER[
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: _ENV[
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: auto_prepend_file=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: auto_append_file=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: allow_url_include=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: disable_functions=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: open_basedir=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: safe_mode=
          TextTransformation: URL_DECODE
  wafgPHPInsecureQSStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-php-insecure-var-refs']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: _SERVER[
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: _ENV[
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: auto_prepend_file=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: auto_append_file=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: allow_url_include=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: disable_functions=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: open_basedir=
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: QUERY_STRING
          PositionalConstraint: CONTAINS
          TargetString: safe_mode=
          TextTransformation: URL_DECODE
  wafrPHPInsecureURIStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-php-insecure-uri']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: php
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: /
          TextTransformation: URL_DECODE
  wafgPHPInsecureURIStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-php-insecure-uri']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: php
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: /
          TextTransformation: URL_DECODE
  wafrPHPInsecureRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectphpinsecure']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-php-insecure']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrPHPInsecureQSStringSet
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrPHPInsecureURIStringSet
  wafgPHPInsecureRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectphpinsecure']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-php-insecure']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgPHPInsecureQSStringSet
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgPHPInsecureURIStringSet

## 7.
## OWASP Top 10 A7
## Mitigate abnormal requests via size restrictions
## Enforce consistent request hygene, limit size of key elements
  wafrSizeRestrictionSet:
    Type: AWS::WAFRegional::SizeConstraintSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'size-restrictions']]
      SizeConstraints:
        - FieldToMatch:
            Type: URI
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedURISize
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedQueryStringSize
        - FieldToMatch:
            Type: BODY
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedBodySize
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedCookieSize
  wafgSizeRestrictionSet:
    Type: AWS::WAF::SizeConstraintSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'size-restrictions']]
      SizeConstraints:
        - FieldToMatch:
            Type: URI
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedURISize
        - FieldToMatch:
            Type: QUERY_STRING
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedQueryStringSize
        - FieldToMatch:
            Type: BODY
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedBodySize
        - FieldToMatch:
            Type: HEADER
            Data: cookie
          TextTransformation: NONE
          ComparisonOperator: GT
          Size: !Ref maxExpectedCookieSize
  wafrSizeRestrictionRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'restrictsizes']]
      Name: !Join ['-', [!Ref stackPrefix, 'restrict-sizes']]
      Predicates:
        - Type: SizeConstraint
          Negated: false
          DataId: !Ref wafrSizeRestrictionSet
  wafgSizeRestrictionRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'restrictsizes']]
      Name: !Join ['-', [!Ref stackPrefix, 'restrict-sizes']]
      Predicates:
        - Type: SizeConstraint
          Negated: false
          DataId: !Ref wafgSizeRestrictionSet

## 8.
## OWASP Top 10 A8
## CSRF token enforcement example
## Enforce the presence of CSRF token in request header
  wafrCSRFMethodStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-csrf-method']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: METHOD
          PositionalConstraint: EXACTLY
          TargetString: post
          TextTransformation: LOWERCASE
  wafgCSRFMethodStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-csrf-method']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: METHOD
          PositionalConstraint: EXACTLY
          TargetString: post
          TextTransformation: LOWERCASE
  wafrCSRFTokenSizeConstraint:
    Type: AWS::WAFRegional::SizeConstraintSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-csrf-token']]
      SizeConstraints:
        - FieldToMatch:
            Type: HEADER
            Data: !Ref csrfExpectedHeader
          TextTransformation: NONE
          ComparisonOperator: EQ
          Size: !Ref csrfExpectedSize
  wafgCSRFTokenSizeConstraint:
    Type: AWS::WAF::SizeConstraintSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-csrf-token']]
      SizeConstraints:
        - FieldToMatch:
            Type: HEADER
            Data: !Ref csrfExpectedHeader
          TextTransformation: NONE
          ComparisonOperator: EQ
          Size: !Ref csrfExpectedSize
  wafrCSRFRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'enforcecsrf']]
      Name: !Join ['-', [!Ref stackPrefix, 'enforce-csrf']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrCSRFMethodStringSet
        - Type: SizeConstraint
          Negated: true
          DataId: !Ref wafrCSRFTokenSizeConstraint
  wafgCSRFRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'enforcecsrf']]
      Name: !Join ['-', [!Ref stackPrefix, 'enforce-csrf']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgCSRFMethodStringSet
        - Type: SizeConstraint
          Negated: true
          DataId: !Ref wafgCSRFTokenSizeConstraint

## 9.
## OWASP Top 10 A9
## Server-side includes & libraries in webroot
## Matches request patterns for webroot objects that shouldn't be directly accessible
  wafrServerSideIncludeStringSet:
    Type: AWS::WAFRegional::ByteMatchSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-ssi']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: STARTS_WITH
          TargetString: !Ref includesPrefix
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .cfg
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .conf
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .config
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .ini
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .log
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .bak
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .backup
          TextTransformation: LOWERCASE
  wafgServerSideIncludeStringSet:
    Type: AWS::WAF::ByteMatchSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-ssi']]
      ByteMatchTuples:
        - FieldToMatch:
            Type: URI
          PositionalConstraint: STARTS_WITH
          TargetString: !Ref includesPrefix
          TextTransformation: URL_DECODE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .cfg
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .conf
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .config
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .ini
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .log
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .bak
          TextTransformation: LOWERCASE
        - FieldToMatch:
            Type: URI
          PositionalConstraint: ENDS_WITH
          TargetString: .backup
          TextTransformation: LOWERCASE
  wafrServerSideIncludeRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectssi']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-ssi']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafrServerSideIncludeStringSet
  wafgServerSideIncludeRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'detectssi']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-ssi']]
      Predicates:
        - Type: ByteMatch
          Negated: false
          DataId: !Ref wafgServerSideIncludeStringSet

## 10.
## Generic
## IP Blacklist
## Matches IP addresses that should not be allowed to access content
  wafrBlacklistIpSet:
    Type: AWS::WAFRegional::IPSet
    Condition: isRegional
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-blacklisted-ips']]
      IPSetDescriptors:
        - Type: IPV4
          Value: 192.168.1.1/32
        - Type: IPV4
          Value: 169.254.0.0/16
        - Type: IPV4
          Value: 172.16.0.0/16
        - Type: IPV4
          Value: 127.0.0.1/32
  wafgBlacklistIpSet:
    Type: AWS::WAF::IPSet
    Condition: isGlobal
    Properties:
      Name: !Join ['-', [!Ref stackPrefix, 'match-blacklisted-ips']]
      IPSetDescriptors:
        - Type: IPV4
          Value: 192.168.1.1/32
        - Type: IPV4
          Value: 169.254.0.0/16
        - Type: IPV4
          Value: 172.16.0.0/16
        - Type: IPV4
          Value: 127.0.0.1/32
  wafrBlacklistIpRule:
    Type: AWS::WAFRegional::Rule
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'blacklistedips']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-blacklisted-ips']]
      Predicates:
        - Type: IPMatch
          Negated: false
          DataId: !Ref wafrBlacklistIpSet
  wafgBlacklistIpRule:
    Type: AWS::WAF::Rule
    Condition: isGlobal
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'blacklistedips']]
      Name: !Join ['-', [!Ref stackPrefix, 'detect-blacklisted-ips']]
      Predicates:
        - Type: IPMatch
          Negated: false
          DataId: !Ref wafgBlacklistIpSet

## --
## WebACL containing the above rules evaluated in-order
  wafrOwaspACL:
    Type: AWS::WAFRegional::WebACL
    Condition: isRegional
    Properties:
      MetricName: !Join ['', [!Ref stackPrefix, 'owaspacl']]
      Name: !Join ['-', [!Ref stackPrefix, 'owasp-acl']]
      DefaultAction:
        Type: ALLOW
      Rules:
        - Action:
            Type: !Ref ruleAction
          Priority: 10
          RuleId: !Ref wafrSizeRestrictionRule
        - Action:
            Type: !Ref ruleAction
          Priority: 20
          RuleId: !Ref wafrBlacklistIpRule
        - Action:
            Type: !Ref ruleAction
          Priority: 30
          RuleId: !Ref wafrAuthTokenRule
        - Action:
            Type: !Ref ruleAction
          Priority: 40
          RuleId: !Ref wafrSQLiRule
        - Action:
            Type: !Ref ruleAction
          Priority: 50
          RuleId: !Ref wafrXSSRule
        - Action:
            Type: !Ref ruleAction
          Priority: 60
          RuleId: !Ref wafrPathsRule
        - Action:
            Type: !Ref ruleAction
          Priority: 70
          RuleId: !Ref wafrPHPInsecureRule
        - Action:
            Type: ALLOW
          Priority: 80
          RuleId: !Ref wafrCSRFRule
        - Action:
            Type: !Ref ruleAction
          Priority: 90
          RuleId: !Ref wafrServerSideIncludeRule
        - Action:
            Type: !Ref ruleAction
          Priority: 100
          RuleId: !Ref wafrAdminAccessRule

  # MyWebACLAssociation:
  #   Type: AWS::WAFRegional::WebACLAssociation
  #   DependsOn: wafrOwaspACL
  #   Properties:
  #     WebACLId: !Ref wafrOwaspACL
  #     ResourceArn:
  #       Fn::ImportValue: csye6225-load-balancer

## ::OUTPUTS::
## Outputs useful in other templates
Outputs:
  wafWebACL:
    Value: !Ref wafrOwaspACL
  wafWebACLMetric:
    Value: !Join ['', [!Ref stackPrefix, 'owaspacl']]
  wafSQLiRule:
    Value: !If [ isRegional, !Ref wafrSQLiRule, !Ref wafgSQLiRule ]
  wafSQLiRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'mitigatesqli']]
  wafAuthTokenRule:
    Value: !If [ isRegional, !Ref wafrAuthTokenRule, !Ref wafgAuthTokenRule ]
  wafAuthTokenRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'badauthtokens']]
  wafXSSRule:
    Value: !If [ isRegional, !Ref wafrXSSRule, !Ref wafgXSSRule ]
  wafXSSRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'mitigatexss']]
  wafPathsRule:
    Value: !If [ isRegional, !Ref wafrPathsRule, !Ref wafgPathsRule ]
  wafPathsRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'detectrfilfi']]
  wafPHPMisconfigRule:
    Value: !If [ isRegional, !Ref wafrPHPInsecureRule, !Ref wafgPHPInsecureRule ]
  wafPHPMisconfigRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'detectphpinsecure']]
  wafAdminAccessRule:
    Value: !If [ isRegional, !Ref wafrAdminAccessRule, !Ref wafgAdminAccessRule ]
  wafAdminAccessRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'detectadminaccess']]
  wafCSRFRule:
    Value: !If [ isRegional, !Ref wafrCSRFRule, !Ref wafgCSRFRule ]
  wafCSRFRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'enforcecsrf']]
  wafSSIRule:
    Value: !If [ isRegional, !Ref wafrServerSideIncludeRule, !Ref wafgServerSideIncludeRule ]
  wafSSIRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'detectssi']]
  wafBlacklistIpRule:
    Value: !If [ isRegional, !Ref wafrBlacklistIpRule, !Ref wafgBlacklistIpRule ]
  wafBlacklistIpRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'blacklistedips']]
  wafSizeRestrictionRule:
    Value: !If [ isRegional, !Ref wafrSizeRestrictionRule, !Ref wafgSizeRestrictionRule ]
  wafSizeRestrictionRuleMetric:
    Value: !Join ['', [!Ref stackPrefix, 'restrictsizes']]
  wafAuthTokenBlacklist:
    Value: !If [ isRegional, !Ref wafrAuthTokenStringSet, !Ref wafgAuthTokenStringSet ]
  wafAdminAccessWhitelist:
    Value: !If [ isRegional, !Ref wafrAdminRemoteAddrIpSet, !Ref wafgAdminRemoteAddrIpSet ]
  wafIpBlacklist:
    Value: !If [ isRegional, !Ref wafrBlacklistIpSet, !Ref wafgBlacklistIpSet ]
STACK
}

