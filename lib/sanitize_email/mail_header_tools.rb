# Copyright (c) 2008-16 Peter H. Boling of RailsBling.com
# Released under the MIT license

module SanitizeEmail
  # Tools for modifying the header of an email
  module MailHeaderTools

    def self.prepend_subject_array(message)
      prepend = []
      prepend << SanitizeEmail::MailHeaderTools.prepend_email_to_subject(Array(message.to)) if SanitizeEmail.use_actual_email_prepended_to_subject
      prepend << SanitizeEmail::MailHeaderTools.prepend_environment_to_subject if SanitizeEmail.use_actual_environment_prepended_to_subject
      prepend << "" unless prepend.empty? # this will force later joins to add an extra space
      prepend
    end

    def self.custom_subject(message)
      prepend_subject_array(message).join(" ")
    end

    def self.prepend_environment_to_subject
      SanitizeEmail::Config.config[:environment]
    end

    def self.prepend_email_to_subject(actual_addresses)
      "(#{actual_addresses.uniq.join(',').gsub(/@/, ' at ').gsub(/[<>]/, '~')})" if actual_addresses.respond_to?(:join)
    end

    def self.add_original_addresses_as_headers(message)
      ## Add headers by string concat. Setting hash values on message.headers does nothing, strangely. http://goo.gl/v46GY
      {
        'X-Sanitize-Email-To' => Array(message.to).uniq, # can be an array, so casting it as an array
        'X-Sanitize-Email-Cc' => Array(message.cc).uniq  # can be an array, so casting it as an array
        # Don't write out the BCC, as those addresses should not be visible in message headers for obvious reasons
      }.each { |header_key, header_value|
        # For each type of address line
        SanitizeEmail::MailHeaderTools.update_header(header_key, header_value, message)
      }
    end

    def self.prepend_custom_subject(message)
      message.subject = "" unless message.subject
      message.subject = message.subject.dup.prepend(SanitizeEmail::MailHeaderTools.custom_subject(message))
    end

    # According to https://github.com/mikel/mail this is the correct way to update headers.
    def self.update_header(header_key, header_value, message)
      # For each address, as header_value can be an array of addresses
      Array(header_value).each_with_index { |elem, index|
        num = index + 1
        new_header_key = num > 1 ?
          "#{header_key}-#{num}" :
          header_key
        message.header[new_header_key] = elem.to_s
      } if header_value
    end

  end
end
