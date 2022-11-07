# frozen_string_literal: true

require "spec_helper"
require "openssl"
require "time"
require "base64"

# Implements the model defined by LDAPv3
# https://www.rfc-editor.org/rfc/rfc4511
module Ldap
  class LdapModel < RASN1::Model
    def self.model_name
      name.split("::").last.to_sym
    end

    def self.message_id(name, options = {})
      custom_primitive_type_for(name, MessageId, options)
    end

    def self.ldap_string(name, options = {})
      custom_primitive_type_for(name, LdapString, options)
    end

    def self.ldap_dn(name, options = {})
      custom_primitive_type_for(name, LdapDN, options)
    end

    def self.ldap_relative_dn(name, options = {})
      custom_primitive_type_for(name, LdapString, options)
    end

    def self.custom_primitive_type_for(name, clazz, options = {})
      options[:name] = name
      proc = proc { |opts| clazz.new(options.merge(opts)) }
      @root = BaseElem.new(name, proc, nil)
    end

    private_class_method :custom_primitive_type_for
  end

  # 4.1.2.  String Types
  #        LDAPString ::= OCTET STRING -- UTF-8 encoded,
  #                                     -- [ISO10646] characters
  class LdapString < RASN1::Types::OctetString
  end

  # 4.1.3.  Distinguished Name and Relative Distinguished Name
  #        LDAPDN ::= LDAPString
  #                    -- Constrained to <distinguishedName> [RFC4514]
  class LdapDN < LdapString
  end

  #
  # 4.1.1.  Message Envelope
  #

  # 4.1.1.  Message Envelope
  #        MessageID ::= INTEGER (0 ..  maxInt)
  #        maxInt INTEGER ::= 2147483647 -- (2^^31 - 1) --
  class MessageId < RASN1::Types::Integer
    # XXX: Add constrained types in accordance to the specification
  end

  # 4.1.10.  Referral
  #        URI ::= LDAPString     -- limited to characters permitted in
  #                                -- URIs
  class LdapUri < LdapString
  end

  # 4.1.10.  Referral
  #        Referral ::= SEQUENCE SIZE (1..MAX) OF uri URI
  class Referral < LdapModel
    sequence_of :uri, LdapUri
  end

  # 4.1.9.  Result Message
  #
  #        LDAPResult ::= SEQUENCE {
  #              resultCode         ENUMERATED {
  #                   success                      (0),
  #                   ...
  #                   other                        (80),
  #                   ...  },
  #              matchedDN          LDAPDN,
  #              diagnosticMessage  LDAPString,
  #              referral           [3] Referral OPTIONAL }
  class LdapResult < LdapModel
    def self.components
      [
        enumerated(
          :result_code,
          enum: {
            "success" => 0,
            "operationsError" => 1,
            "protocolError" => 2,
            "timeLimitExceeded" => 3,
            "sizeLimitExceeded" => 4,
            "compareFalse" => 5,
            "compareTrue" => 6,
            "authMethodNotSupported" => 7,
            "strongerAuthRequired" => 8,
            #     -- 9 reserved --
            "referral" => 10,
            "adminLimitExceeded" => 11,
            "unavailableCriticalExtension" => 12,
            "confidentialityRequired" => 13,
            "saslBindInProgress" => 14,
            "noSuchAttribute" => 16,
            "undefinedAttributeType" => 17,
            "inappropriateMatching" => 18,
            "constraintViolation" => 19,
            "attributeOrValueExists" => 20,
            "invalidAttributeSyntax" => 21,
            #     -- 22-31 unused --
            "noSuchObject" => 32,
            "aliasProblem" => 33,
            "invalidDNSyntax" => 34,
            # -- 35 reserved for undefined isLeaf --
            "aliasDereferencingProblem" => 36,
            # -- 37-47 unused --
            "inappropriateAuthentication" => 48,
            "invalidCredentials" => 49,
            "insufficientAccessRights" => 50,
            "busy" => 51,
            "unavailable" => 52,
            "unwillingToPerform" => 53,
            "loopDetect" => 54,
            # -- 55-63 unused --
            "namingViolation" => 64,
            "objectClassViolation" => 65,
            "notAllowedOnNonLeaf" => 66,
            "notAllowedOnRDN" => 67,
            "entryAlreadyExists" => 68,
            "objectClassModsProhibited" => 69,
            #-- 70 reserved for CLDAP --
            "affectsMultipleDSAs" => 71,
            # -- 72-79 unused --
            "other" => 80
          }
        ),
        ldap_dn(:matched_dn),
        ldap_string(:diagnostic_message),
        wrapper(model(:referral, Referral), implicit: 3, optional: true)
      ]
    end

    sequence model_name, content: self.components
  end

  # 4.7.  Add Operation
  # AddResponse ::= [APPLICATION 9] LDAPResult
  class AddResponse < LdapModel
    sequence model_name,
            class: :application,
            implicit: 9,
            content: [
              *LdapResult.components
            ]
  end

  # 4.1.1.  Message Envelope
  #              protocolOp      CHOICE {
  #                   bindRequest           BindRequest,
  #                   bindResponse          BindResponse,
  #                   unbindRequest         UnbindRequest,
  #                   searchRequest         SearchRequest,
  #                   searchResEntry        SearchResultEntry,
  #                   searchResDone         SearchResultDone,
  #                   searchResRef          SearchResultReference,
  #                   modifyRequest         ModifyRequest,
  #                   modifyResponse        ModifyResponse,
  #                   addRequest            AddRequest,
  #                   addResponse           AddResponse,
  #                   delRequest            DelRequest,
  #                   delResponse           DelResponse,
  #                   modDNRequest          ModifyDNRequest,
  #                   modDNResponse         ModifyDNResponse,
  #                   compareRequest        CompareRequest,
  #                   compareResponse       CompareResponse,
  #                   abandonRequest        AbandonRequest,
  #                   extendedReq           ExtendedRequest,
  #                   extendedResp          ExtendedResponse,
  #                   ...,
  #                   intermediateResponse  IntermediateResponse },
  class ProtocolOp < LdapModel
    choice model_name,
           content: [
             model(:add_response, AddResponse),
           ]
  end

  #        LDAPMessage ::= SEQUENCE {
  #              messageID       MessageID,
  #              protocolOp      CHOICE {
  #                   bindRequest           BindRequest,
  #                   bindResponse          BindResponse,
  #                   ...,
  #                   intermediateResponse  IntermediateResponse },
  #              controls       [0] Controls OPTIONAL }
  class LdapMessage < LdapModel
    sequence model_name,
            content: [
              message_id(:message_id),
              model(:protocol_op, ProtocolOp)
            ]
  end
end

# Network traffic extracted from wireshark in conjunction with https://docs.oracle.com/cd/E19693-01/819-0995/6n3cq3apv/index.html#bcadf or https://directory.apache.org/studio/
RSpec.describe Ldap do
  describe Ldap::LdapMessage do
    context "when a AddResponse is parsed" do
      let(:valid_data) do
        Base64.decode64 <<~EOF
          MIQAAACWAgECaYQAAACNCgEKBAAEUDAwMDAyMDJCOiBSZWZFcnI6IERTSUQtMDMxMDA4MkYsIGRhdGEgMCwgMSBhY2Nlc3MgcG9pbnRzCglyZWYgMTogJ2V4YW1wbGUuY29tJwoAo4QAAAAwBC5sZGFwOi8vZXhhbXBsZS5jb20vb3U9UGVvcGxlLGRjPWV4YW1wbGUsZGM9Y29t
        EOF
      end

      it_behaves_like "a model that produces the same binary data when to_der is called", :pending

      describe "#parse" do
        it "parses the data successfully" do
          expected = {
            LdapMessage: {
              message_id: 2,
              protocol_op: {
                add_response: {
                  referral: ["ldap://example.com/ou=People,dc=example,dc=com"],
                  diagnostic_message: "0000202B: RefErr: DSID-0310082F, data 0, 1 access points\n\tref 1: 'example.com'\n\x00",
                  matched_dn: "",
                  result_code: "referral"
                }
              }
            }
          }

          expect(described_class.parse(valid_data).to_h).to eq(expected)
        end
      end
    end
  end
end
