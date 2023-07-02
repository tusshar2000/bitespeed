class Contact < ApplicationRecord
  PRIMARY_CONTACT = "primary"
  SECONDARY_CONTACT = "secondary"

  def self.create_or_update_contact(params)
    email = params[:email]
    phone_number = params[:phoneNumber]

    check_and_create_contact(email, phone_number)
    check_and_create_contact_linkages(fetch_contacts(email, phone_number))

    generate_response(fetch_contacts(email, phone_number))
  end

  def self.check_and_create_contact(email, phone_number)
    if email.present? && phone_number.present?
      contacts = fetch_contacts(email, phone_number)
      contact = Contact.find_by(email: email, phone_number: phone_number)
      if contact.nil?
        Contact.create(
          email: email,
          phone_number: phone_number,
          linked_id: contacts.present? ? contacts.first.id : nil,
          link_precedence: contacts.present? ? SECONDARY_CONTACT : PRIMARY_CONTACT
        )
      else
        contact.update(link_precedence: link_precedence)
      end
    elsif email.present?
      if Contact.find_by(email: email).nil?
        Contact.create(
          email: email,
          link_precedence: PRIMARY_CONTACT
        )
      end
    elsif phone_number.present?
      if Contact.find_by(phone_number: phone_number).nil?
      Contact.create(
        phone_number: phone_number,
        link_precedence: PRIMARY_CONTACT
      )
      end
    end
  end

  def self.fetch_contacts(email, phone_number)
    conditions = []
    conditions << "email = '#{email}'" if email.present?
    conditions << "phone_number = '#{phone_number}'" if phone_number.present?
    conditions = conditions.join(' OR ')
    Contact.where(conditions)
  end

  def self.check_and_create_contact_linkages(contacts)
    return contacts if contacts.where(link_precedence: PRIMARY_CONTACT).count == 1
    first_contact = contacts.first
    contacts.where(id: contacts.ids - [first_contact.id])
            .update(link_precedence: SECONDARY_CONTACT, linked_id: first_contact.id)
  end

  def self.generate_response(records)
    primary_contact_id = nil
    emails = []
    phone_numbers = []
    secondary_contact_ids = []

    records.each do |record|
      primary_contact_id = record.id if record.link_precedence == PRIMARY_CONTACT
      emails << record.email if record.email.present?
      phone_numbers << record.phone_number if record.phone_number.present?
      secondary_contact_ids << record.id if record.link_precedence == SECONDARY_CONTACT
    end

    {
      "contact": {
        "primaryContactId": primary_contact_id,
        "emails": emails.uniq,
        "phoneNumbers": phone_numbers.uniq,
        "secondaryContactIds": secondary_contact_ids.uniq
      }
    }
  end
end