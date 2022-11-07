# frozen_string_literal: true

require 'spec_helper'
require 'openssl'
require 'time'
require 'base64'

# Implements the model defined by LDAPv3
# https://www.rfc-editor.org/rfc/rfc4511
module Ldap
  class LdapModel < RASN1::Model
    def self.model_name
      name.split('::').last.to_sym
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
      options.merge!(name: name)
      proc = proc do |opts|
        clazz.new(options.merge(opts))
      end
      @root = BaseElem.new(name, proc, nil)
    end

    private_class_method :custom_primitive_type_for
  end

  #
  # 4.1.2.  String Types
  #

  #        LDAPString ::= OCTET STRING -- UTF-8 encoded,
  #                                     -- [ISO10646] characters
  class LdapString < RASN1::Types::OctetString
  end

  #        LDAPDN ::= LDAPString
  #                    -- Constrained to <distinguishedName> [RFC4514]
  class LdapDN < LdapString
  end

  #
  # 4.2.  Bind Operation
  #

  #        SaslCredentials ::= SEQUENCE {
  #              mechanism               LDAPString,
  #              credentials             OCTET STRING OPTIONAL }
  class SaslCredentials < LdapModel
    sequence model_name,
             content: [
               ldap_string(:mechanism),
               octet_string(:credentials, optional: true)
             ]
  end

  #        AuthenticationChoice ::= CHOICE {
  #              simple                  [0] OCTET STRING,
  #                                      -- 1 and 2 reserved
  #              sasl                    [3] SaslCredentials,
  #              ...  }
  class AuthenticationChoice < LdapModel
    choice model_name,
             content: [
               octet_string(:simple, implicit: 0),
               wrapper(model(:sasl, SaslCredentials), implicit: 3)
             ]
  end

  #        BindRequest ::= [APPLICATION 0] SEQUENCE {
  #              version                 INTEGER (1 ..  127),
  #              name                    LDAPDN,
  #              authentication          AuthenticationChoice }
  class BindRequest < LdapModel
    sequence model_name,
             class: :application,
             implicit: 0,
             content: [
               integer(:version),
               ldap_dn(:name),
               model(:authentication, AuthenticationChoice)
             ]
  end

  #
  # 4.1.1.  Message Envelope
  #

  #        MessageID ::= INTEGER (0 ..  maxInt)
  #        maxInt INTEGER ::= 2147483647 -- (2^^31 - 1) --
  class MessageId < RASN1::Types::Integer
    # XXX: Add constrained types in accordance to the specification
  end

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
             model(:bind_request, BindRequest),
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

RSpec.describe Ldap do
  describe Ldap::LdapMessage do
    let(:valid_data) do
      "\x30\x2c\x02\x01\x01\x60\x27\x02\x01\x03\x04\x18\x41\x64\x6d\x69" \
      "\x6e\x69\x73\x74\x72\x61\x74\x6f\x72\x40\x61\x64\x66\x33\x2e\x6c" \
      "\x6f\x63\x61\x6c\x80\x08\x70\x34\x24\x24\x77\x30\x72\x64".b
    end

    it_behaves_like 'a model that produces the same binary data when to_der is called'

    describe '#parse' do
      it 'parses the data successfully' do
        expected = {
          LdapMessage: {
            message_id: 1,
            protocol_op: {
              bind_request: {
                version: 3,
                 name: 'Administrator@adf3.local',
                 authentication: {
                   simple: 'p4$$w0rd'.b
                 }
              }
            }
          }
        }
        expect(described_class.parse(valid_data).to_h).to eq(expected)
      end
    end
  end
end
